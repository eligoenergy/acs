set :deploy_to, "/export/web/acs"
set :rails_env, :production

role :web, "acs.cashnetusa.com"                          # Your HTTP server, Apache/etc
role :app, "acs.cashnetusa.com"                          # This may be the same as your `Web` server
role :db,  "acs.cashnetusa.com", :primary => true # This is where Rails migrations will run