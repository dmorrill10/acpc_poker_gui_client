#!/usr/bin/env rake

RAILS_ROOT = File.expand_path('../', __FILE__)
require_relative 'config/application'

AcpcPokerGuiClient::Application.load_tasks

desc 'Compile the ACPC Dealer server'
task :compile_dealer => :install_gems do
  sh %{ bundle exec acpc_dealer compile }
end

VENDOR_DIRECTORY = "#{RAILS_ROOT}/vendor"
file VENDOR_DIRECTORY do
  print "Creating #{VENDOR_DIRECTORY}..."
  FileUtils.mkpath VENDOR_DIRECTORY
  puts "Done"
end

MONGODB_DIRECTORY = "#{VENDOR_DIRECTORY}/mongoDB"
file MONGODB_DIRECTORY do
  puts(
    "Please download a MongoDB version compatible with your system " +
    "from http://www.mongodb.org/downloads, unpack the compressed file to " +
    "`<project root>/vendor`, and rename the resulting directory to `mongoDB`."
  )
  raise
end

MONGOD_EXECUTABLE = "#{MONGODB_DIRECTORY}/bin/mongod"
file MONGOD_EXECUTABLE => MONGODB_DIRECTORY
MONGODB_DATA_DIRECTORY = "#{RAILS_ROOT}/db/data"

file MONGODB_DATA_DIRECTORY => MONGODB_DIRECTORY do
  FileUtils.mkpath MONGODB_DATA_DIRECTORY
end

desc 'Complete MongoDB set up. Requires that the '
task :setup_mongodb => [MONGODB_DATA_DIRECTORY, MONGOD_EXECUTABLE]

desc 'Installs gem dependencies'
task :install_gems do
  print "Running 'bundle install'..."
  sh %{ bundle install }
  puts "Done"
end

desc 'Installs gems and Beanstalkd, compiles the ACPC Dealer, and sets up MongoDB'
task :install => [:install_gems, :compile_dealer, :setup_mongodb]

desc 'Start god process manager'
task :god do
  sh %{ bundle exec god -c config/god.rb -l log/god.log}
end

desc 'Stop god process manager'
task :kill_god do
  begin; sh %{ bundle exec god terminate }; rescue; end
end

desc 'Starts a development server'
task :start_dev_server => [MONGOD_EXECUTABLE, MONGODB_DATA_DIRECTORY] do
  print "Starting god..."
  Rake::Task[:god].invoke

  rails_command = 'rails s'
  print "Running '#{rails_command}'..."
  sh %{ #{rails_command} }
  puts "Done"
end

task :precompile_assets do
  sh %{ bundle exec rake assets:precompile RAILS_ENV=production }
end

desc 'Update code and gem dependencies'
task :update do
  sh %{ git fetch && git merge }
  Rake::Task[:install_gems].invoke
  Rake::Task[:precompile_assets].invoke
end

desc 'Start production server'
task :start_prod_server => [MONGOD_EXECUTABLE, MONGODB_DATA_DIRECTORY] do
  Rake::Task[:god].invoke
  # Start production server here
end

desc 'Kill production server'
task :kill_prod_server do
  Rake::Task[:kill_god].invoke
  begin; sh %{ killall dealer }; rescue; end
  # Stop production server here
end

desc 'Restart production server'
task :restart_prod_server do
  Rake::Task[:kill_prod_server].invoke
  Rake::Task[:start_prod_server].invoke
end

desc 'Kill the background process and database servers'
task :kill_background do
  begin; sh %{ killall mongod }; rescue; end
  begin; sh %{ killall dealer }; rescue; end
end