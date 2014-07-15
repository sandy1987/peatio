require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'mina/rbenv'
require 'mina/slack/tasks'

# set :repository, 'https://github.com/peatio/peatio.git'
# set :user, 'deploy'
# set :deploy_to, '/home/deploy/peatio'
# set :branch, 'master'
# set :domain, 'demo.peat.io'
require "rvm/capistrano"
require "bundler/capistrano"
set :application, "107.170.114.144"
set :deploy_to, "/home//root/peatio/#{application}"
set :repository,  "git@github.com:sachinshar/Pixsume_Prod.git"
set :port, 3000
set :use_sudo, true
set :user_sudo, false
set :rails_env, "production" # sets your server environment to Production mode
set :ssh_options, { :forward_agent => true }
set :scm, :git  # sets version control
set :shared_paths, [
  'config/database.yml',
  'config/application.yml',
  'config/currencies.yml',
  'config/markets.yml',
  'config/amqp.yml',
  'config/deposit_channels.yml',
  'config/withdraw_channels.yml',
  'tmp',
  'log'
]


task :environment do
  invoke :'rbenv:load'
end

task :setup => :environment do
  queue! %[mkdir -p "#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/log"]

  queue! %[mkdir -p "#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/config"]

  queue! %[mkdir -p "#{deploy_to}/shared/tmp"]
  queue! %[chmod g+rx,u+rwx "#{deploy_to}/shared/tmp"]

  queue! %[touch "#{deploy_to}/shared/config/database.yml"]
  queue! %[touch "#{deploy_to}/shared/config/currencies.yml"]
  queue! %[touch "#{deploy_to}/shared/config/application.yml"]
  queue! %[touch "#{deploy_to}/shared/config/markets.yml"]
  queue! %[touch "#{deploy_to}/shared/config/amqp.yml"]
  queue! %[touch "#{deploy_to}/shared/config/deposit_channels.yml"]
  queue! %[touch "#{deploy_to}/shared/config/withdraw_channels.yml"]
end

desc "Deploys the current version to the server."
task deploy: :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    invoke :'bundle:install'
    invoke :'rails:db_migrate'
    invoke :'rails:assets_precompile'

    to :launch do
      invoke :'passenger:restart'
    end
  end
end

namespace :passenger do
  desc "Restart Passenger"
  task :restart do
    queue %{
      echo "-----> Restarting passenger"
      cd #{deploy_to}/current
      #{echo_cmd %[mkdir -p tmp]}
      #{echo_cmd %[touch tmp/restart.txt]}
    }
  end
end

namespace :daemons do
  desc "Start Daemons"
  task start: :environment do
    queue %{
      cd #{deploy_to}/current
      RAILS_ENV=production bundle exec ./bin/rake daemons:start
      echo Daemons START DONE!!!
    }
  end

  desc "Stop Daemons"
  task stop: :environment do
    queue %{
      cd #{deploy_to}/current
      RAILS_ENV=production bundle exec ./bin/rake daemons:stop
      echo Daemons STOP DONE!!!
    }
  end

  desc "Query Daemons"
  task status: :environment do
    queue %{
      cd #{deploy_to}/current
      RAILS_ENV=production bundle exec ./bin/rake daemons:status
    }
  end
end

desc "Generate liability proof"
task 'solvency:liability_proof' do
  queue "cd #{deploy_to}/current && RAILS_ENV=production bundle exec rake solvency:liability_proof"
end