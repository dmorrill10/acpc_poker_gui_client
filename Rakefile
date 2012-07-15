#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

RAILS_ROOT = File.expand_path('../', __FILE__)
require_relative 'config/application'

AcpcPokerGuiClient::Application.load_tasks

desc 'Compile the ACPC Dealer server'
task :compile_dealer => :install_gems do
  sh %{ acpc_dealer compile }
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
MONGODB_DATA_DIRECTORY = "#{MONGODB_DIRECTORY}/data/db"

file MONGODB_DATA_DIRECTORY => MONGODB_DIRECTORY do
  FileUtils.mkpath MONGODB_DATA_DIRECTORY
end

desc 'Complete MongoDB set up. Requires that the '
task :setup_mongodb => [MONGODB_DATA_DIRECTORY, MONGOD_EXECUTABLE]

BEANSTALKD_NAME = 'beanstalkd'
BEANSTALKD_EXECUTABLE = "#{VENDOR_DIRECTORY}/#{BEANSTALKD_NAME}"
task :reinstall_beanstalkd do
  FileUtils.rm_f BEANSTALKD_EXECUTABLE
  FileUtils.cd VENDOR_DIRECTORY do
    print "Cloning #{BEANSTALKD_NAME} from GitHub..."
    sh %{ git clone git://github.com/kr/beanstalkd.git }
    puts 'Done'
    
    print "Building #{BEANSTALKD_NAME}..."
    temp_name = 'beanstalkd_executable'
    FileUtils.cd BEANSTALKD_NAME do
      sh %{ make }
      puts 'Done'

      print 'Cleaning up...' 
      FileUtils.cp BEANSTALKD_NAME, "../#{temp_name}"
    end

    FileUtils.rm_rf BEANSTALKD_NAME
    FileUtils.mv temp_name, BEANSTALKD_NAME
    puts 'Done'
  end
end
file BEANSTALKD_EXECUTABLE => VENDOR_DIRECTORY do
  unless File.exists?(BEANSTALKD_EXECUTABLE)
    Rake::Task[:reinstall_beanstalkd].invoke
  end
end

desc 'Installs Beanstalkd background process server'
task :install_beanstalkd => BEANSTALKD_EXECUTABLE

desc 'Installs gem dependencies'
task :install_gems do
  print "Running 'bundle install'..."
  sh %{ bundle install }
  puts "Done"
end

desc 'Installs gems and Beanstalkd, compiles the ACPC Dealer, and sets up MongoDB'
task :install => [:install_gems, :compile_dealer, :setup_mongodb, :install_beanstalkd]

desc 'Starts a development server'
task :start_dev_server => [MONGOD_EXECUTABLE, MONGODB_DATA_DIRECTORY, BEANSTALKD_EXECUTABLE] do
  mongod_command = "#{MONGOD_EXECUTABLE} --nojournal --dbpath #{MONGODB_DATA_DIRECTORY} &"
  print "Running '#{mongod_command}'..."
  sh %{ #{mongod_command} }
  puts "Done"

  beanstalkd_command = "#{BEANSTALKD_EXECUTABLE} &"
  print "Running '#{beanstalkd_command}'"
  sh %{ #{beanstalkd_command} }
  puts "Done"

  stalk_command = "stalk #{RAILS_ROOT}/lib/background/worker.rb &"
  print "Running '#{stalk_command}'..."
  sh %{ #{stalk_command} }
  puts "Done"

  rails_command = 'rails s'
  print "Running '#{rails_command}'..."
  sh %{ #{rails_command} }
  puts "Done"
end

desc 'Update code and gem dependencies'
task :update do
  sh %{ git pull }
  Rake::Task[:install_gems].invoke
end

desc 'Start production server'
task :start_prod_server do
  sh %{ god -c config/god.rb }
  sh %{ bundle exec rake assets:precompile RAILS_ENV=production }
end

desc 'Kill production server'
task :kill_prod_server do
  begin; sh %{ god terminate }; rescue; end
  begin; sh %{ apache2ctl -f ~/httpd.conf -k stop }; rescue; end
end

desc 'Kill the background process and database servers'
task :kill_background do
  begin; sh %{ killall mongod }; rescue; end
  begin; sh %{ killall beanstalkd }; rescue; end
end