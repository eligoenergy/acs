class User < ActiveRecord::Base
  include AASM
  include Acs::Ldap
  # extend Acs::UserCsvImporter

  acts_as_nested_set :parent_column => 'manager_id'

  has_and_belongs_to_many :roles
  belongs_to :job
  belongs_to :company
  has_and_belongs_to_many :permissions, :uniq => true
  has_and_belongs_to_many :resources, :uniq => true
  belongs_to :manager, :class_name => 'User'
  has_many :actionable_requests, :class_name => 'AccessRequest', :foreign_key => 'current_worker_id'
  has_many :access_requests
  has_many :permission_requests, :through => :access_requests
  has_many :notes
  has_many :subordinates, :class_name => 'User', :foreign_key => 'manager_id'
  belongs_to :manager, :class_name => 'User'
  belongs_to :employment_type
  belongs_to :submitted_by, :class_name => 'User'
  belongs_to :terminated_by, :class_name => 'User'
  # has_many :unassigned_resource_requests, :class_name => 'AccessRequest', :conditions => ['current_state = ?', 'waiting_for_resource_owner_assignment']

  acts_as_change_logger :ignore => [ :crypted_password, :password_salt, :perishable_token, :persistence_token, :login_count, :failed_login_count, :current_login_ip, :last_login_ip, :last_request_at, :current_login_at, :last_login_at, :lft, :rgt ]

  define_index do
    indexes login, :sortable => true
    indexes first_name, :sortable => true
    indexes last_name, :sortable => true
    indexes email, :sortable => true
    has job_id, manager_id, company_id, submitted_by_id, terminated_by_id
    where "users.current_state = 'active'"
  end

  acts_as_authentic do |c|
    if ldap_active?
      c.validate_password_field = false
      c.require_password_confirmation = false
    end
#   c.ignore_blank_passwords = true
   c.merge_validates_length_of_login_field_options :within => 3..100
  end

  before_destroy :stop_bad_delete
  before_validation :set_role, :on => :create
  before_validation :generate_login, :on => :create
  before_validation :generate_email_address, :on => :create
  before_validation :set_default_password, :on => :create unless ldap_active?
  # accepts_nested_attributes_for :permissions
  validate :check_manager

  validates_with Acs::UserValidator

  scope :sort_by_last_name_first_name, order('users.last_name asc, users.first_name asc')
  scope :active, where(:current_state => 'active')
  scope :managers, where(:manager_flag => true)
  scope :waiting_for_hr, where(:current_state => ['pending', 'suspended'])
  scope :descendants_of, lambda { |manager| where('users.lft > ? and users.rgt < ?', manager.lft, manager.rgt)}
  scope :descendants_of_with, lambda { |manager| where('users.lft >= ? and users.rgt <= ?', manager.lft, manager.rgt)}
  scope :first_level_children_of, lambda { |manager| where('users.manager_id = ?', manager.id)}
  scope :by_dept, lambda { |department| includes(:job => [:department]).where(['jobs.department_id = ?', department.id]) }
  scope :help_desk, includes(:roles).where('roles.name = ?', Role::ROLES[:help_desk])
  scope :hr, includes(:roles).where('roles.name = ?', Role::ROLES[:hr])
  scope :by_job, lambda { |job_id| where(:job_id => job_id.to_i) }
  scope :by_department, lambda { |dept_id| joins(:job => [ :department ]).where(['departments.id = ?', dept_id]) }
  scope :by_location, lambda { |location_id| joins(:job => [ :department => [ :location ]]).where(['locations.id = ?', location_id]) }
  scope :by_role, lambda { |role_id| where(:role_id => role_id) }
  scope :by_employment_type, lambda { |employment_type_id| where(:employment_type_id => employment_type_id) }
  scope :with_extra_info, includes([:roles, {:job => {:department => :location}}])
  scope :created_by_me, lambda { |user_id| includes(:access_requests).where('users.submitted_by_id = ? and users.created_at > ? ', user_id, Date.today-14) }

  # TODO remove the by_ part from scopes above
  scope :last_name, lambda { |name| where('users.last_name ilike ?',"%#{name}%") }
  scope :first_name, lambda { |name| where('users.first_name ilike ?', "%#{name}%") }
  scope :ldap_name, lambda { |name| where('users.login ilike ?', "%#{name}%") }
  scope :coworker_number, lambda { |number| where('users.coworker_number = ?', number)}
  # scope :start_date, lambda { |date| where(:start_date => date) }
  # scope :department, lambda { |department_id| where() }
  # scope :location, lambda { |location_id| where() }
  scope :job, lambda { |job_id| where(:job_id => job_id)}
  scope :alphabetical, order('users.last_name, users.first_name')
  scope :alphabetical_login, order('users.login')
  scope :with_incomplete_access_requests, includes(:access_requests).where('access_requests.current_state not in (?)', ['completed', 'denied', 'canceled'])
  scope :has_some_access_to, lambda { |resource| includes(:permissions).where('permissions_users.permission_id in (?)', resource.permissions.map(&:id)) }

  preference :items_per_page, :integer, :default => 20
  preference :viewable_departments , :array

  aasm_column :current_state
  aasm_initial_state :passive

  aasm_state :passive
  aasm_state :pending
  aasm_state :active,  :enter => [:complete_activation, :notify_manager]
  aasm_state :suspended
  aasm_state :terminated, :enter => :complete_termination

  aasm_event :activate do
    transitions :from => [:passive, :pending], :to => :active
  end

  aasm_event :verify_with_hr do
    transitions :from => :passive, :to => :pending
  end

  aasm_event :verified_by_hr do
    transitions :from => :pending, :to => :active
  end

  aasm_event :suspend do
    transitions(
      :from => [:passive, :pending, :active],
      :to => :suspended
    )
  end

  aasm_event :terminate do
    transitions(
      :from => [:passive, :pending, :active, :suspended],
      :to => :terminated
    )
  end

  aasm_event :rehire do
    transitions :from => :terminated, :to => :active,
    :guard => :has_no_open_terminations
  end

  aasm_event :reactivate do
    transitions :from => :suspended, :to => :active
  end

  def stop_bad_delete
    User.count(:conditions => ['current_state = ?', 'active']) > 1
  end

  def set_role
    self.roles << default_role if self.roles.blank?
  end

  def generate_login
    # generate_unique_login from ldap module
    unless self.first_name.blank? || self.last_name.blank?
      self.login = generate_unique_login if login.blank?
    end
  end

  def manager?
    self.manager_flag
  end

  def direct_manager_of
    User.active.first_level_children_of self
  end

  def manager_of?(user)
    @is_manager_of ||= self.descendants.include?(user)
  end

  def check_manager
    if self.manager_id.nil?
      self.errors[:base] << "User must be created with a manager"
    end
  end

  def can_request_access_for?(user)
    self == user ? true : self.descendants.include?(user) || self.hr?
  end

  def viewable_departments
    if self.preferred_viewable_departments.nil?
      Department.all.each{ |d| d.id }
    else
      YAML.load(self.preferred_viewable_departments)[".key"]
    end
  end

  # AASM enter and exit state methods
  def complete_termination
    self.deleted_at = Time.now.utc
    self.end_date = Date.today
  end

  def has_no_open_terminations
    self.access_requests.not_completed.are_terminations.blank?
  end

  def complete_activation
    @activated = true
    self.activated_at = Time.now.utc
    self.deleted_at = nil
  end

  def new_employee?
    self.start_date.nil? || self.start_date >= Date.today || ['passive','pending'].include?(self.current_state)
  end

  def waiting_for_hr?
    ['pending','suspended'].include?(self.current_state)
  end

  def has_open_request_for?(permission)
    self.access_requests.not_completed.any?{|access_request| access_request.permission_requests.any? {|permission_request| permission_request.permission == permission}}
  end

  # TODO find a better place for these display helpers but still allow using current_user.display_helper
  def full_name
    "#{self.nickname.blank? ? self.first_name : self.nickname} #{self.last_name}"
  end

  def last_name_first
    "#{self.last_name}, #{self.nickname.blank? ? self.first_name : self.nickname}"
  end

  def set_default_password
    self.password = 'asdfasdf'
    self.password_confirmation = 'asdfasdf'
  end

  def generate_email_address
    self.email = self.login.gsub(/\W/,'')+"@"+self.company.email_domain
  end

  def notify_manager
    # TODO implement this method
  end

  def is_admin_or_hr?
    admin? || hr?
  end

  def default_role
    Role.find_by_name(Role::ROLES[:public])
  end
  def public?
    @user_is_public ||= self.roles.include?(Role.find_by_name(Role::ROLES[:public]))
  end
  def hr?
    @user_is_hr ||= self.roles.include?(Role.find_by_name(Role::ROLES[:hr]))
  end
  def help_desk?
    @user_is_help_desk ||= self.roles.include?(Role.find_by_name(Role::ROLES[:help_desk]))
  end
  def admin?
    @user_is_admin ||= self.roles.include?(Role.find_by_name(Role::ROLES[:admin]))
  end
  def auditor?
    @user_is_auditor ||= self.roles.include?(Role.find_by_name(Role::ROLES[:auditor]))
  end

  def can_view_all_requests_at_help_desk?
    help_desk? || admin?
  end

  def can_manage_users?
    hr? || manager?
  end

  def can_manage?(user)
    hr? || admin? || manager_of?(user)
  end

  def owns_resource_in_resource_group?(resource_group)
    self.resources.any? {|resource| resource.resource_group == resource_group }
  end

  def has_open_access_request_for?(permission)
    self.access_requests.not_completed.any? {|ar| ar.permission_requests.any? {|pr| pr.permission == permission } }
  end

  def transfer_employee(old_job,new_job,submitter)
    old_perms = old_job.permissions
    new_perms = new_job.permissions
    self.job = new_job
    revoke = ((old_perms - new_perms) - self.access_requests.not_completed.to_revoke.map(&:permissions).compact.uniq)
    grant = ((new_perms - old_perms) - self.access_requests.not_completed.to_grant.map(&:permissions).compact.uniq)
    revoke.each do |r|
      req = AccessRequest.new(
        :resource => r.resource,
        :user => self,
        :request_action => AccessRequest::ACTIONS[:revoke],
        :reason => AccessRequest::REASONS[:transfer],
        :created_by => submitter,
        :created_by_transfer => true,
        :permission_ids => [r.id]
      )
      req.send_to_help_desk! unless self.has_open_access_request_for?(r)
    end
    grant.each do |g|
      req = AccessRequest.new(
        :resource => g.resource,
        :user => self,
        :request_action => AccessRequest::ACTIONS[:grant],
        :reason => AccessRequest::REASONS[:transfer],
        :created_by => submitter,
        :created_by_transfer => true,
        :permission_ids => [g.id]
      )
      req.send_to_help_desk! unless self.has_open_access_request_for?(g)
    end
  end

  def self.verify_csv_length(csv,format)
    expected_size = CSV_TYPES['types'][format].size
    results = []
    csv.each_with_index { |line,idx|
      results << [idx+1, line.size == expected_size]
    }
    results
  end

  def self.import_from_csv(verified, csv, format, submitter, note)
    users = []
   # verified = verify_csv_length(csv,format)
    verified.each { |result|
      if result.include?(true)
        user = create_from_csv(csv[result.first-1], format, submitter, note)

        users << user
      end
    }
    logger.info { "\n*******\n* imported_users: #{users.inspect}" }
    users
  end

  def self.create_from_csv(csv_line, format, submitter, note)

    case format
    when 'user'
      first_name,last_name,start_date,department,position,manager,type = csv_line
      login = nil
    when 'backfill'
      first_name,last_name,login,start_date,department,position,manager,type = csv_line
    end
    # FIXME employees can have the same name, this needs to be updated to handle that
    if User.find_by_first_name_and_last_name(first_name,last_name)
      return "Employee #{first_name} #{last_name} already exists!"
    end
    unless user_manager = User.find_by_login(manager)
      return "Must insert manager #{manager} first!"
    end
    unless user_employment_type = EmploymentType.find_by_name(type.titleize)
      return "Employment type not valid."
    end
    unless user_department = Department.find_by_name(department.titleize)
      return "Department name is not valid"
    end
    unless user_position = user_department.jobs.find_by_name(position.titleize)
      return "Job title not valid."
    end

    # Can't go straight to User.create here because we need to generate a login and email address
    # TODO: refactor this step

    User.transaction do
      begin
        user = User.new(
          :first_name => first_name.titleize.strip,
          :last_name => last_name.titleize.strip,
          :login => login,
          :start_date => start_date,
          :manager_id => user_manager.id,
          :job_id => user_position.id,
          :employment_type_id => user_employment_type.id,
          :company_id => Company.find_by_name('Example').id
        )
        user.submitted_by = submitter
        user.generate_unique_login if user.login.nil?
        user.password_salt = Authlogic::Random.friendly_token unless Rails.env.production?
        logger.info { "* user.valid?: #{user.valid?}" }
        logger.info { "*      errors: #{user.errors.inspect}" }
        user.save!
        user.activate!
        AccessRequest.transaction do
          logger.info { "\n\n*****\n inside AccessRequest.transaction user: #{user.inspect}" }
          Resource.for_job(user.job).all.each do |resource|
            access_request = user.access_requests.create(
              :request_action => AccessRequest::ACTIONS[:grant],
              :reason => AccessRequest::REASONS[:new_hire],
              :resource => resource,
              :permission_ids => resource.permissions.map{|perm| perm.id if perm.resource == resource }.compact,
              :created_by => user.submitted_by,
              :for_new_user => true,
              :created_by_import => true
            )
            access_request.grant_all_permissions
            access_request.notes.create(:body => note, :user => user.submitted_by)
            access_request.send_to_help_desk!
          end
        end
        return user
      rescue ActiveRecord::RecordInvalid => e
        return e
      end
    end
  end
end

