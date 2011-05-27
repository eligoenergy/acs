module Acs
  module RequestGenerator
    
    def generate_future_employee_request!(options = {})
      request = self.requests.create(
        :created_by => options[:created_by],
        :reason => options[:reason] || Request::REASONS[:new_hire]
      )      
      Resource.for_job(self.job).all.each do |resource|
        access_request = request.access_requests.create(
          :request_action => AccessRequest::ACTIONS[:grant],
          :resource => resource,
          :permission_ids => (resource.permissions - (resource.permissions - self.job.permissions)).map(&:id)
        )
        access_request.manager = options[:manager] unless options[:manager].blank?
        access_request.hr = options[:hr] unless options[:hr].blank?
        access_request.notes.create(:body => options[:note], :user => request.created_by) unless options[:note].blank?
        access_request.approve_all_permission_requests(request.reason)
      end
      self.permissions.clear
      self.send(options[:end_action]) unless options[:end_action].blank?
      request.start!
    end
    
    def generate_revoke_request!(options = {})
      request = self.requests.create(
        :created_by => options[:created_by],
        :reason => Request::REASONS[:revoke]
      )
      options[:resources].each_pair do |resource_id, attributes|
        access_request = request.access_requests.create(
          :request_action => AccessRequest::ACTIONS[:revoke],
          :resource_id => resource_id,
          :permission_ids => attributes[:permission_ids],
          :manager => request.created_by
        )
        access_request.approve_all_permission_requests(request.reason)
      end
      request.start!
    end
    
    def generate_transfer_request!(options = {})
      
    end
    
    def generate_termination_request!(options = {})
      request = self.requests.create(
        :created_by => options[:created_by],
        :reason => Request::REASONS[:termination]
      )
      Resource.user_has_access(self).each do |resource|
        access_request = request.access_requests.create(
          :request_action => AccessRequest::ACTIONS[:revoke],
          :resource => resource,
          :permission_ids => self.permissions.where(:resource_id => resource.id).all.map(&:id)
        )
        if options[:created_by].hr? && self.ancestors.include?(options[:created_by])
          access_request.manager = options[:created_by]
          access_request.hr = options[:created_by]
        elsif options[:created_by].hr?
          access_request.hr = options[:created_by]
        else
          access_request.manager = options[:created_by]
        end
        access_request.notes.create(:body => options[:note], :user => request.created_by) unless options[:note].blank?
        access_request.approve_all_permission_requests(request.reason)
      end
      self.terminated_by = options[:terminated_by] unless options[:terminated_by].blank?
      self.send(options[:end_action]) unless options[:end_action].blank?
      request.start!
    end        

  end
end