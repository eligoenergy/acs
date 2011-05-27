Given /^I do not have any access to the resource "([^"]*)" from resource group "([^"]*)"$/ do |resource, resource_group|
  # @resource_group = ResourceGroup.find_by_name(resource_group)
  @resource_group = resource_groups(resource_group.to_sym)
  @resource_group.should be_valid
  @resource = @resource_group.resources.find_by_name(resource)
  @resource.should be_valid
  current_user.valid?
  current_user.should be_valid
  current_user.permissions.all?{ |permission| permission.resource.should_not == @resource }
end

Given /^I have "([^"]*)" access for resource "([^"]*)" from resource group "([^"]*)"$/ do |permission, resource, resource_group| #"
  @resource_group = ResourceGroup.find_by_name(resource_group)
  @resource = @resource_group.resources.find_by_name(resource)
  @permission_type = @resource_group.permission_types.find_by_name(permission)
  @permission = @resource.permissions.find_by_permission_type_id(@permission_type.id)
  current_user.permissions.should include(@permission)
end

Given /^"([^"]*)" is my subordinate$/ do |username| #"
  @user = User.find_by_login(username)
  current_user.subordinates.should include(@user)
end

Given /^I have a pending access request for "([^"]*)" from resource group "([^"]*)"$/ do |resource, resource_group|
  @resource_group = resource_groups(resource_group.to_sym)
  @resource = @resource_group.resources.find_by_name(resource)
  @resource.should_not be_blank
  current_user.access_requests.not_completed.any? {|ar| ar.resource == @resource}.should be_true
end

Then /^an Access Request should be created for that request with (\d+) permission request$/ do |number|
  @access_request.should be_waiting_for_manager_approval
  @access_request.should have(number).permission_requests
end

Then /^it should be assigned to my manager$/ do
  @access_request.current_worker.should == current_user.manager
end

Then /^an Access Request should be created for me$/ do
  @access_request = AccessRequest.where({:created_by_id => current_user.id, :user_id => current_user.id, :resource_id => @resource.id, :manager_id => current_user.manager.id, :request_action => 'grant', :current_worker_id => current_user.manager.id}).last
  @access_request.should_not be_blank
  @access_request.created_at.should be_within(5).of(Time.now)
end

Then /^the access request for "([^"]*)" should request "([^"]*)" access$/ do |resource, permission|
  resource = resources(resource.to_sym)
  access_request = @request.access_requests.where(:resource_id => resource.id).first
  access_request.should_not be_blank
  access_request.resource.should == resource
  access_request.permission_requests.any?{|permission_request| permission_request.permission.permission_type.name == permission }.should be_true
end


Then /^it should have a permission request for "([^"]*)" access$/ do |permission_type| #"
  @access_request.permission_requests.first.permission.permission_type.name.should == permission_type
end

Then /^it should be for "([^"]*)"$/ do |resource_name| #"
  @resource = Resource.find_by_name resource_name
  @access_request.resource.should == @resource
end

Then /^an access request should not be created for me$/ do
  @access_requests = AccessRequest.where('user_id = ? and resource_id = ? and current_state not in (?)', current_user.id, @resource.id, ['completed', 'denied'])
  @access_requests.should have_exactly(1).items
end

Then /^an Access Request should be created for "([^"]*)"$/ do |username| #"
  @user = users(username.to_sym)
  @access_request = AccessRequest.where('user_id = ? and created_by_id = ? and request_action = ?', @user.id, current_user.id, 'grant').last
  @access_request.created_at.should be_within(5).of(Time.now)  
end

Given /^"([^"]*)" is a request created by "([^"]*)"$/ do |name, login|
  @request = requests(name.to_sym)
  @created_by = users(login.to_sym)
  @request.should_not be_blank
  @created_by.should_not be_blank
  @request.user.should == @created_by
end

Then /^I "([^"]*)" "([^"]*)" for "([^"]*)"$/ do |action, radio_base, permission| #"
  val = action == 'approve' ? 'true' : 'false'
  id = @request.permission_requests.first.id
  Then "I choose \"#{radio_base}_#{id}_approved_#{val}\""
end

Then /^I "([^"]*)" "([^"]*)" "([^"]*)" permission for "([^"]*)"$/ do |action, radio_base, permission, request|
  @request = requests(request.to_sym)
  val = action == 'approve' ? 'true' : 'false'
  id = @request.permission_requests.first.id
  Then "I choose \"#{radio_base}_#{id}_approved_#{val}\""
end

# created for resource_owner_approval.feature
Given /^I am an owner of "([^"]*)"$/ do |resource| #"
  resource = resources(resource.to_sym)
  resource.users.should include(current_user)
end

Given /^"([^"]*)" is owned by "([^"]*)"$/ do |resource, user|
  resource = resources(resource.to_sym)
  @user = User.find_by_login user
  resource.users.should include(@user)
end

Given /^it is waiting for resource owner assignment$/ do
  @access_request.should be_waiting_for_resource_owner_assignment
end

Given /^it is waiting for resource owner$/ do
  @access_request.should be_waiting_for_resource_owner
end

Then /^"([^"]*)" access requests should be "([^"]*)"$/ do |request, current_state|
  @request = requests(request.to_sym)
  @request.access_requests.all? {|access_request| access_request.current_state.should == current_state }
end

Then /^the requests access requests should be "([^"]*)"$/ do |aasm_state| #"
  @request.reload
  @request.access_requests.all?{|access_request| access_request.current_state.should == aasm_state }
end

Then /^the requests access requests should be unassigned$/ do
  @request.reload
  @request.access_requests.all?{|access_request| access_request.current_worker.should be_blank }
end

Then /^the access request should be assigned to "([^"]*)"$/ do |username| #"
  @access_request.current_worker.login.should == username
end

Then /^the access request resource owner should be "([^"]*)"$/ do |username|
  @access_request.resource_owner.login.should == username
end


Then /^"([^"]*)" should have "([^"]*)" permissions$/ do |username, permission|
  @request.reload
  user = User.find_by_login username
  permission = permissions(permission.to_sym)
  user.permissions.should include(permission)
end

Then /^a access request to revoke "([^"]*)" access to "([^"]*)" should be created$/ do |permission, resource|
  @resource = resources(resource.to_sym)
  @access_request = AccessRequest.last
  @access_request.resource.should == @resource
  @access_request.permission_requests.first.permission.permission_type.name.should == permission
end

Then /^the access request should be for "([^"]*)"$/ do |username|
  @access_request.user.should == @user
end

Given /^"([^"]*)" has "([^"]*)" permission$/ do |username, permission| #"
  @user = users(username.to_sym)
  @permission = permissions(permission.to_sym)
  @user.permissions.should include(@permission)
end

Then /^"([^"]*)" should not have "([^"]*)" permission$/ do |username, permission|
  @user.login.should == username
  @user.permissions.should_not include(@permissions)
end

