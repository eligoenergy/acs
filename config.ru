# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Acs::Application

Sass::Plugin.options[:syntax] = :scss
