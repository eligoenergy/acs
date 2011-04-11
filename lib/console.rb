def collect_users
  departments = Department.alphabetical.all
  departments.each do |d|
    puts "Department #{d.id}, #{d.name}"
    d.jobs.each do |job|
      puts "  Job #{job.id}, #{job.name}"
      job.users.each do |u|
        puts "    User #{u.id}, #{u.login}, #{u.manager.try(:login)}, #{u.coworker_number}, #{u.current_state}, #{u.employment_type.name}"
      end
    end    
  end
  nil
end

def collect_jobs
  errors = []
  departments = Department.alphabetical.all
  departments.each do |d|
    jobs = d.jobs.alphabetical.all
    jobs.each do |j|
      begin
        users = User.active.where(:job_id => j.id)
        managers = []
        users.each do |u|
          managers << u.manager unless managers.include?(u.manager)
        end
        if managers.blank?
          managers = ''
        else
          managers = managers.sort{|a,b| a.login <=> b.login }.map(&:login).join(',')
        end
        puts "#{d.name},#{j.name},#{j.users.size},#{j.permissions.size},#{managers}"
      rescue Exception => e
        errors << [j,managers,e]
      end
    end
  end
  errors
end

def collect_users2
  errors = []
  departments = Department.alphabetical.all
  departments.each do |d|
    jobs = d.jobs.alphabetical.all
    jobs.each do |j|
      begin
        users = User.active.alphabetical_login.where(:job_id => j.id)
        users.each do |u|
          puts "#{d.name},#{j.name},#{u.login},#{u.manager.try(:login)}"
        end
      rescue Exception => e
        errors << e
      end
    end
  end
  errors
end