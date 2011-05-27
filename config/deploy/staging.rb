$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.

set :rvm_ruby_string, '1.9.2'        # Or whatever env you want it to run in.
set :rvm_type, :system

# staging environment is used instead of production so we are able to
# what user we login as. eg. username: ldapusername-otheruseryouwanttologinas, password: ldap password
set :deploy_to, "/export/web/acs3"
set :rails_env, :staging
# set :branch, "css3buttons"

role :web, "acs3.opssupport.cashnetusa.com"                          # Your HTTP server, Apache/etc
role :app, "acs3.opssupport.cashnetusa.com"                          # This may be the same as your `Web` server
role :db,  "acs3.opssupport.cashnetusa.com", :primary => true # This is where Rails migrations will run

set :use_sudo, false

# before "deploy:update_code", "deploy:stop"
# after "deploy:update_code", "deploy:start"

namespace :deploy do
  # task :start do
    # run "cd #{File.join(deploy_to, "current")}; passenger start -a 127.0.0.1 -p 3001 -d -e staging --log-file #{File.join(deploy_to, "shared", "log", "passenger.3001.log")} --pid-file #{File.join(deploy_to, "shared", "tmp", "pids", "passenger.3001.pid")}"
  # end

  # task :stop  do
    # run "cd #{File.join(deploy_to, "current")}; passenger stop --port 3001 --pid-file #{File.join(deploy_to, "shared", "tmp", "pids", "passenger.3001.pid")}"
  # end

  # task :restart, :roles => :app, :except => { :no_release => true } do
    # run "touch #{File.join(current_path, "tmp/restart.txt")}"
  # end

  task :update_shared_symlinks do
    %w(config/database.yml).each do |path|
      run "rm -rf #{File.join(release_path, path)}"
      run "ln -s #{File.join(deploy_to, "shared", path)} #{File.join(release_path, path)}"
    end
  end
end