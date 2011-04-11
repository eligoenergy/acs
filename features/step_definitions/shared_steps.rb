Given /^I am logged in as "([^"]*)"$/ do |username| #"
  login_as(username)
  Then 'I should see "Hello"'
  Then 'I should see "Dashboard"'
  current_user.login.should == username unless Webrat.configure.mode == :selenium
end

Then /^I login as "([^"]*)"$/ do |username|
  login_as(username)
  reloaded_current_user.login.should == username
end

Given /^I am not logged in$/ do
  current_user.should be_nil
end

Given /^I have the role "([^"]*)"$/ do |role| #"
  role = roles(role.to_sym)
  current_user.roles.should include(role)
end

Given /^I am a manager$/ do
  current_user.should be_manager
end

Given /^I am not a manager$/ do
  current_user.manager_flag.should be_false
  current_user.descendants.should be_blank
end

Given /^"([^"]*)" is subordinate to "([^"]*)"$/ do |employee, manager|
  @employee = User.find_by_login(employee)
  @manager = User.find_by_login(manager)
  @manager.subordinates.should include(@employee)
end

Then /^I press on "([^"]*)"$/ do |button|
  Then "I press \"#{button}\""
  And 'response body'
end

Then /^(?:|I )check permission "([^"]*)"$/ do |permission| #"
  permission = permissions(permission.to_sym)
  field = field_with_id("resources_permission_ids_#{permission.id}")
  check(field)
end

Then /^the checkbox for "([^"]*)" should be disabled$/ do |permission|
  permission = permissions(permission.to_sym)
  field = field_with_id("access_request_permission_requests_attributes_permission_id_#{permission.id}")
  field.element.attributes["disabled"].value.should == "disabled"
end

Then /^the checkbox for permission "([^"]*)" should be disabled$/ do |permission_id|
  permission = Permission.find(permission_id)
  field = field_with_id("user_permission_ids_#{permission.id}")
  field.element.attributes["disabled"].value.should == "disabled"
end

Then /^the access request "([^"]*)" should be "([^"]*)"$/ do |access_request, state|
  access_request = access_requests(access_request.to_sym)
  access_request.current_state.should == state
end

Then /^the user "([^"]*)" should be "([^"]*)"$/ do |user, state|
  
  @user ||= begin
    users(user.to_sym)
  rescue
    User.find_by_login(user)
  end
  @user.reload
  @user.current_state.should == state
end

Then /^there should be an access request created to terminate "([^"]*)" permissions from "([^"]*)"$/ do |permission, user|
  permission = permissions(permission.to_sym)
  user = users(user.to_sym)
  access_request = AccessRequest.where({:request_action => 'terminate', :user_id => user.id, :resource_id => permission.resource.id}).first
  access_request.should_not be_blank
  access_request.permission_requests.should have(1).item
  access_request.permission_requests.first.permission.should == permission
end

Then /^there should be (\d+) access request for "([^"]*)"$/ do |number, username|
  @user = users(username.to_sym)
  @user.access_requests.not_completed.should have(number.to_i).items
  @access_request = @user.access_requests.not_completed.last
end

Then /^the access request should request to "([^"]*)"$/ do |request_action|
  @access_request.request_action.should == request_action
end

Then /^the access request reason should be "([^"]*)"$/ do |reason|
  @access_request.reason.should == reason
end

Then /^the access request should be created by the manager of "([^"]*)"$/ do |user|
  @user.login.should == user
  @access_request.created_by.should == @user.manager
end

Then /^the access request should be created by "([^"]*)"$/ do |user|
  @access_request.created_by.login.should == user
end

Then /^the access request should have (\d+) permission request$/ do |number|
  @access_request.should have(number.to_i).permission_requests
end

Then /^the user should have (\d+) access requests$/ do |number|
  @user.access_requests.size.should == number.to_i
end

Then /^the access request should be by manager for subordinate$/ do
  @access_request.should be_by_manager_for_subordinate
end

Then /^the access request should be unassigned$/ do
  @access_request.current_worker.should be_nil
end

Then /^the permission request should be for "([^"]*)"$/ do |permission|
  permission = permissions(permission.to_sym)
  @permission_request = @access_request.permission_requests.first
  @permission_request.permission.should == permission
end

Then /^the permission request should be approved by "([^"]*)"$/ do |role|
  @permission_request.send("approved_by_#{role}").should == true
end

Then /^the permission request should not be approved by "([^"]*)"$/ do |role|
  @permission_request.send("approved_by_#{role}").should be_blank
end

Given /^I follow the link for "([^"]*)"$/ do |access_request|
  access_request = access_requests(access_request.to_sym)
  link_id = "dashboard_access_request_#{access_request.id}"
  click_link(link_id)
end

Given /^I follow the link to user "([^"]*)"$/ do |user|
  @user = users(user.to_sym)
  link_id = "users_#{@user.id}"
  click_link(link_id)
end

When /^I visit the show access request page for "([^"]*)"$/ do |access_request|
  access_request = access_requests(access_request.to_sym)
  visit(access_request_path(access_request))
end

When /^response body$/ do
  # puts "\n**\n #{response.inspect}"
  # puts "\n**\n response.original_headers: #{response.original_headers}"
  # puts "\n**\n response.headers: #{response.headers}"
  puts "\n**\n response.body: #{response.body}"
end

When /^inspect current user$/ do
  puts_current_user
end

When /^inspect fixtures/ do
  puts_fixtures
end

Then /debug access request "([^"]*)"$/ do |access_request| #"
  access_request = access_requests(access_request.to_sym)
  puts "\n*** access_request: #{access_request.inspect}"
  access_request.permission_requests.each do |perm|
    puts "\n* permission_request: #{perm.inspect}"
  end
end

And /^inspect user$/ do
  puts "\n*** user: #{@user.inspect}"
  @user.permissions.each do |perm|
    puts "** #{perm.inspect}"
    puts "** #{perm.resource.name}, #{perm.permission_type.name}"
  end
end

And /^inspect resource "([^"]*)"$/ do |resource| #"
  resource = resources(resource.to_sym)
  puts "\n\n\n*** #{resource.inspect}"
  ResourceGroup.all.each do |rg|
    puts "* #{rg.inspect}"
  end
  puts "*******\n\n"
end

And /^inspect access requests for "([^"]*)"$/ do |username| #"
  user = users(username.to_sym)
  user.access_requests.all.each do |rg|
    puts "* #{rg.inspect}"
  end
  puts "*******\n\n"
end

And /^roles$/ do
  puts "* #{Role.find_by_name(Role::ROLES[:help_desk]).inspect}"
  Role.all.each do |role|
    puts role.inspect
  end
end
# Webrat relies on the onclick attribute to "fake" HTTP request's
# method, so it cannot cope with the new Ruby on Rails 3's style
# which uses unobtrusive JavaScript and HTML5 data attributes.
# http://baldowl.github.com/2010/12/06/coercing-cucumber-and-webrat-to-cooperate.html
=begin
When /^(?:|I )follow "([^\"]*)" for #{capture_model}$/ do |arg1, arg2|
  id = "#user_#{model(arg2).id}"
  case arg1
  when 'Delete'
    within id do
      click_link arg1, :method => :delete
    end
  else
    click_link_within id, arg1
  end
end
=end
def print_users #"
  User.all.each_with_index do |user, index|
    puts "**!! #{index + 1}. #{user.inspect}"
  end
end

def puts_fixtures
  puts "*** users: #{User.all.map{|u| u.inspect}.join(', ')}"
  puts "*** resource_groups: #{ResourceGroup.all.map{|r| r.inspect}.join(', ')}"
  puts "*** permission_types: #{PermissionType.all.map{|p| p.inspect}.join(', ')}"
  puts "*** permissions: #{Permission.all.map{|p| p.inspect }.join(', ')}"
  puts "*** resource: #{@resource.inspect}"
  puts "*** resource.permissions: #{@resource.permissions.map{|r| r.inspect}.join(', ')}" unless @resource.nil?
end

def puts_current_user
  sess = UserSession.find(selenium.cookie("user_credentials"))
  cookie_jar = cookies
 # puts "*** current_user: #{cookie_jar.instance_variable_get(:@cookies).map(&:inspect)g.join("\n")}"
  #puts "*** session: #{current_user_session.id.to_s}"
end

def login_as(username)
  visit '/'
  fill_in 'Login', :with => username
  fill_in 'Password', :with => 'asdfasdf'
  click_button 'Login'
if Webrat.configuration.mode == :selenium
    selenium.wait_for_page_to_load
  end
end

