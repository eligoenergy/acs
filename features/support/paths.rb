module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'
    when /the new permissions page/
      '/access_requests/new/permissions'
    when /the new user page/
      '/admin/users/new'
    when /the admin users page/
      '/admin/users'
    when /the admin users edit page for "([^"]*)"/
      "/admin/users/#{User.find(fixture($1)).id}/edit"
    when /the show access request page for "([^"]*)"$/
      "/access_requests/#{AccessRequest.find(fixture($1)).id}"
    when /the manager approval page for "([^"]*)"/
      "/access_requests/#{(AccessRequest.find(fixture($1)).id)}/manager_approval"
    when /the resource owner approval page for "([^"]*)"/
      "/access_requests/#{(AccessRequest.find(fixture($1)).id)}/resource_owner_approval"
    when /the revoke access request page/
      "/access_requests/revoke"
    when /the user page for "([^"]*)"/
      case Webrat.configure.mode
      when :selenium
      "/users/#{User.find_by_login($1).id}"
      else
      "/users/#{users($1.to_sym).id}"
      end
    when /the login page/
      "/"
    when /the transfer page for "([^"]*)"/
#      "/transfer/new?id=#{User.find_by_login($1).id}"
      "/transfer/new"
    when /the search page/
      "/search/users"
    when /the preferences page/
      "/preferences"  
    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #   when /^(.*)'s profile page$/i
    #     user_profile_path(User.find_by_login($1))

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)

