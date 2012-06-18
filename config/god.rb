# run with: god -c config/god.rb

GOD_RAILS_ROOT = File.expand_path("../..", __FILE__)
God.pid_file_directory = "#{GOD_RAILS_ROOT}/tmp/pids"

def watch(name)
   God.watch do |w|
      w.dir = "#{GOD_RAILS_ROOT}/log"
      w.log = "#{GOD_RAILS_ROOT}/log/#{name}.log"
      w.interval = 30.seconds
      w.env = {"RAILS_ROOT" => GOD_RAILS_ROOT, "RAILS_ENV" => "production"}
      w.name = "acpcpokerguiclient-#{name}"
      
      yield w
      
      w.start_if do |start|
         start.condition(:process_running) do |c|
            c.running = false
         end
      end
   
     w.restart_if do |restart|
         restart.condition(:memory_usage) do |c|
            c.above = 100.megabytes
            c.times = [3, 5] # 3 out of 5 intervals
         end
   
         restart.condition(:cpu_usage) do |c|
            c.above = 80.percent
            c.times = 5
         end
     end
   
      w.lifecycle do |on|
         on.condition(:flapping) do |c|
            c.to_state = [:start, :restart]
            c.times = 5
            c.within = 5.minute
            c.transition = :unmonitored
            c.retry_in = 10.minutes
            c.retry_times = 5
            c.retry_within = 2.hours
         end
      end
   end
end

def delete_matches_older_than(lifespan)
   # These are needed to monitor the Match database and they must be done after
   #  ensuring that the database (mongod in this case) is running
   require "#{GOD_RAILS_ROOT}/lib/config/database_config"
   require "#{GOD_RAILS_ROOT}/app/models/match"

   Match.delete_matches_older_than lifespan
end

def keep_match_database_tidy
   God.watch do |w|
      w.name = 'clean_match_database'
      w.dir = "#{GOD_RAILS_ROOT}/log"
      w.log = "#{GOD_RAILS_ROOT}/log/#{w.name}.log"
      w.env = {"RAILS_ROOT" => GOD_RAILS_ROOT, "RAILS_ENV" => "production"}
      
      interval = 1.hour
      w.interval = interval
      
      # Attempt to delete old Matches every 60 minutes, but
      #  if the database isn't up and an exception is raised,
      #  ignore it and try again in 60 minutes.
      w.start = lambda do
         begin
            # @todo This is using a magic number that should be synchronized with the dealer timeout constant in ApplicationHelpers. The constant should be moved to lib/ApplicationDefs, which could then be included here.
            delete_matches_older_than(24.hours)
         rescue
         end
      end
   end
end

watch('mongod') do |w|
   w.start = '/home/morrill/workspace/mongoDB/mongodb-linux-x86_64-2.0.3/bin/mongod --dbpath /home/morrill/workspace/mongoDB/data'
end

watch('beanstalkd') do |w|
   w.start = '/home/morrill/workspace/beanstalkd/beanstalkd'
end

watch('worker') do |w|
   w.start = "stalk #{GOD_RAILS_ROOT}/script/worker.rb"
end

watch('apache') do |w|
   w.start = '/usr/sbin/apache2 -f /home/morrill/httpd.conf -k start'
   w.stop = '/usr/sbin/apache2 -f /home/morrill/httpd.conf -k stop'
   w.restart = '/usr/sbin/apache2 -f /home/morrill/httpd.conf -k graceful'
   w.start_grace = 10.seconds
   w.restart_grace = 10.seconds
end

keep_match_database_tidy
