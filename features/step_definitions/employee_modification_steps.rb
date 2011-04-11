When /^I use the default permissions for "([^"]*)"$/ do |job| #"
  @job = jobs(job.to_sym)
  @job.permissions.each do |permission|
    Then "the checkbox with id \"user_permission_ids_#{permission.id}\" should be checked"
    Then "the checkbox for permission \"#{permission.id}\" should be disabled"
  end
end

Then /^"([^"]*)" should be created$/ do |login|
  @user = User.find_by_login(login)
  @user.should_not be_blank
end

Then /^they should have the job "([^"]*)"$/ do |job|
  job = jobs(job.to_sym)
  @user.job.should == job
end

Then /^they should have the manager "([^"]*)"$/ do |manager|
  manager = users(manager.to_sym)
  @user.manager.should == manager
end

Then /^they should have the email address "([^"]*)"$/ do |email|
  @user.email.should == email
end

Then /^a "([^"]*)" "([^"]*)" should be created with "([^"]*)" and "([^"]*)"$/ do |first_name, last_name, job_title, manager|
  @manager = users(manager.to_sym)
  @user = User.where('first_name = ? and last_name = ? and job_id = ? and manager_id = ?', first_name, last_name, @job.id, @manager.id).first
  @user.should_not be_blank
  @user.created_at.should be_within(2).of(Time.now) 
end

Then /^access requests for resources needed by "([^"]*)" should be created$/ do |job| #"
  job = jobs(job.to_sym)
  @user.should have_exactly(job.permissions.size).permission_requests
  @access_request = @user.access_requests.first
end

Then /^it should be sent to help desk$/ do
  @user.access_requests.first.should be_waiting_for_help_desk_assignment
end

Then /^the new employee should not have any permissions$/ do
  @user.permissions.should be_blank
end

Then /^the new employee should have the role "([^"]*)"$/ do |role|
  role = roles(role.to_sym)
  @user.roles.should include(role)
end

Then /^"([^"]*)" should be activated$/ do |username|
  @user = users(username.to_sym)
  @user.current_state.should == 'active'
  @user.activated_at.should_not be_nil
end

Then /^they should have (\d+) access requests created for them$/ do |number|
  @access_requests = @user.access_requests.all
  @access_requests.size.should == number.to_i
end

Then /^the access requests should be "([^"]*)"$/ do |current_state|
  @access_requests.each do |access_request|
    access_request.current_state.should == current_state
  end
end

Then /^the access requests should have "([^"]*)" for "([^"]*)" assignment$/ do |username, role|
  user = users(username.to_sym)
  @access_requests.each do |access_request|
    access_request.send(role).should == user
  end
end

Then /^"([^"]*)" should have "([^"]*)" preferred items per page$/ do |username, items|
  @user = users(username.to_sym)
  @user.preferred_items_per_page.should == items.to_i
end  

Then /^"([^"]*)" should have "([^"]*)" selected as the viewable department$/ do |username, department_name|
  @user = users(username.to_sym)
  @department = Department.find_by_name(department_name)
  @user.viewable_departments.should == [(@department.id).to_s]
end  

Then /^the access requests reason should be "([^"]*)"$/ do |reason|
  @access_requests.each do |access_request|
    access_request.reason.should == reason
  end
end

Then /^the access requests should be by manager for subordinate$/ do
  @access_requests.each do |access_request|
    access_request.should be_by_manager_for_subordinate
  end
end
