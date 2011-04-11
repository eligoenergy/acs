set :deploy_to, "/export/web/acs"
set :rails_env, :production

role :web, "acs.example.com"                          # Your HTTP server, Apache/etc
role :app, "acs.example.com"                          # This may be the same as your `Web` server
role :db,  "acs.example.com", :primary => true # This is where Rails migrations will run
