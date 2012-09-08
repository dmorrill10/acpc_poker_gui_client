# run with: god -c config/god.rb

require_relative '../lib/application_defs'

GOD_RAILS_ROOT = File.expand_path("../..", __FILE__)
God.pid_file_directory = "#{GOD_RAILS_ROOT}/tmp/pids"

MONGODB_ROOT = "#{GOD_RAILS_ROOT}/vendor/mongoDB/"
BEANSTALKD_PATH = "#{GOD_RAILS_ROOT}/vendor/beanstalkd"

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
        c.above = 1.gigabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 90.percent
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
  require "#{GOD_RAILS_ROOT}/lib/database_config"
  require "#{GOD_RAILS_ROOT}/app/models/match"

  Match.delete_matches_older_than lifespan
end

def keep_match_database_tidy
  God.watch do |w|
    w.name = 'clean_match_database'
    w.dir = "#{GOD_RAILS_ROOT}/log"
    w.log = "#{GOD_RAILS_ROOT}/log/#{w.name}.log"
    w.env = {"RAILS_ROOT" => GOD_RAILS_ROOT, "RAILS_ENV" => "production"}

    w.interval = 1.day

    # Attempt to delete old Matches every day, but
    #  if the database isn't up and an exception is raised,
    #  ignore it and try again tomorrow.
    w.start = lambda do
      begin
        delete_matches_older_than(DEALER_MILLISECOND_TIMEOUT * 10**(-3))
      rescue
      end
    end
  end
end

watch('mongod') do |w|
  w.start = "#{MONGODB_ROOT}/bin/mongod --dbpath #{GOD_RAILS_ROOT}/db"
end

watch('beanstalkd') do |w|
  w.start = BEANSTALKD_PATH
end

watch('worker') do |w|
  w.start = "stalk #{GOD_RAILS_ROOT}/lib/background/worker.rb"
end

watch('apache') do |w|
  w.start = '/usr/sbin/apache2 -f ~/httpd.conf -k start'
  w.stop = '/usr/sbin/apache2 -f ~/httpd.conf -k stop'
  w.restart = '/usr/sbin/apache2 -f ~/httpd.conf -k graceful'
  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds
end

keep_match_database_tidy
