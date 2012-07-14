#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

RAILS_ROOT = File.expand_path('../', __FILE__)
require_relative 'config/application'

AcpcPokerGuiClient::Application.load_tasks

desc 'Compile the ACPC Dealer server'
task :compile_dealer => :install_gems do
  `acpc_dealer compile`
end

VENDOR_DIRECTORY = "#{RAILS_ROOT}/vendor"
file VENDOR_DIRECTORY do
  print "Creating #{VENDOR_DIRECTORY}..."
  FileUtils.mkpath VENDOR_DIRECTORY
  puts "Done"
end

MONGODB_DIRECTORY = 'mongoDB'
MONGODB_DATA_DIRECTORY = "#{VENDOR_DIRECTORY}/#{MONGODB_DIRECTORY}/data/db"
MONGOD_EXECUTABLE = "#{VENDOR_DIRECTORY}/#{MONGODB_DIRECTORY}/bin/mongod"

MONGODB_SOURCE = 'mongodb-linux-x86_64-2.0.6'
MONGODB_SOURCE_DIRECTORY = "#{VENDOR_DIRECTORY}/#{MONGODB_SOURCE}"
file MONGODB_DIRECTORY => VENDOR_DIRECTORY do
  FileUtils.rm_f MONGODB_DIRECTORY
  FileUtils.cd VENDOR_DIRECTORY do
    print 'Downloading MongoDb 2.0.6...'
    sh %{ wget http://fastdl.mongodb.org/linux/#{MONGODB_SOURCE}.tgz }
    puts 'Done'

    print 'Unpacking MongoDb...'
    sh %{ gunzip #{MONGODB_SOURCE}.tgz }
    sh %{ tar xvf #{MONGODB_SOURCE}.tar }
    FileUtils.rm_f "#{MONGODB_SOURCE}.tar"
    FileUtils.mv MONGODB_SOURCE, MONGODB_DIRECTORY, force: true
    puts 'Done'
  end
end

file MONGOD_EXECUTABLE => MONGODB_DIRECTORY
file MONGODB_DATA_DIRECTORY => MONGODB_DIRECTORY do
  FileUtils.mkpath MONGODB_DATA_DIRECTORY
end

desc 'Install MongoDB database'
task :install_mongodb => [MONGODB_DATA_DIRECTORY, MONGOD_EXECUTABLE]

BEANSTALKD_NAME = 'beanstalkd'
BEANSTALKD_EXECUTABLE = "#{VENDOR_DIRECTORY}/#{BEANSTALKD_NAME}"
file BEANSTALKD_EXECUTABLE => VENDOR_DIRECTORY do
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

desc 'Installs Beanstalkd background process server'
task :install_beanstalkd => BEANSTALKD_EXECUTABLE

desc 'Installs gem dependencies'
task :install_gems do
  print "Running 'bundle install'..."
  sh %{ bundle install }
  puts "Done"
end

desc 'Installs all dependencies'
task :install => [:install_gems, :compile_dealer, :install_mongodb, :install_beanstalkd]

# @todo I tried making this dependent on +:install+, but all the file tasks end up getting run even when there haven't been any updates in their dependencies.
desc 'Starts a development server'
task :start_dev_server do
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

desc 'Kill all server processes'
task :kill_server do
  sh %{ god terminate }
  sh %{ apache2ctl -f ~/httpd.conf -k stop }
  sh %{ killall ruby }
  sh %{ killall beanstalkd }
  sh %{ killall mongod }
end

desc 'Update code and gem dependencies'
task :update => :kill_server do
  sh %{ git pull }
  Rake::Task[:install_gems].invoke
end

desc 'Start production server'
task :start_prod_server do
  sh %{ god -c config/god.rb }
  sh %{ bundle exec rake assets:precompile RAILS_ENV=production }
end
