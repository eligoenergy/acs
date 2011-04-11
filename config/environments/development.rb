Acs::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.active_support.deprecation = :log
    
  # config.middleware.use "Rack::Bug",
    # :secret_key => "askldjfowehgoieliosjgo9weyo9w78hgwkgl4i&^@kejwerl098uwe9rWHE*(&GWF)"
  # config.after_initialize do
    # Bullet.enable = true
    # Bullet.alert = true
    # Bullet.bullet_logger = true
    # Bullet.console = true
    # Bullet.growl = true
    # Bullet.xmpp = { :account => 'bullets_account@jabber.org',
                  # :password => 'bullets_password_for_jabber',
                  # :receiver => 'your_account@jabber.org',
                  # :show_online_status => true }
    # Bullet.rails_logger = true
    # Bullet.disable_browser_cache = true
  # end
  config.action_mailer.default_url_options = { :host => "localhost:3000" }
end