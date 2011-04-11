Webrat.configure do |config|
  config.mode = :selenium
  config.application_framework = :rack
  config.selenium_server_port = 4445
  config.selenium_browser_key = '*firefox'
  config.selenium_browser_startup_timeout = 20
  config.open_error_files = false # Set to true if you want error pages to pop up in the browser
  config.selenium_verbose_output = true
  # Selenium defaults to using the selenium environment. Use the following to override this.
  config.application_environment = :test
end

module Rack
  module Test
    DEFAULT_HOST = "localhost"
  end
end

Cucumber::Rails::World.use_transactional_fixtures = false
# this is necessary to have webrat "wait_for" the response body to be available
# when writing steps that match against the response body returned by selenium
World(Webrat::Selenium::Matchers)
World(Webrat::Selenium::Methods)


World(Webrat::Methods)

