# run with: god -c config/god.rb

GOD_RAILS_ROOT = File.expand_path("../..", __FILE__)
God.pid_file_directory = "#{GOD_RAILS_ROOT}/tmp/pids"

MONGODB_ROOT = "#{GOD_RAILS_ROOT}/vendor/mongoDB/"

def watch(name)
  God.watch do |w|
    w.dir = "#{GOD_RAILS_ROOT}"
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
        c.above = 2.gigabytes
        c.times = [3, 5] # 3 out of 5 intervals
      end

      restart.condition(:cpu_usage) do |c|
        c.above = 100.percent
        c.times = 15
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

watch('mongod') do |w|
  vendor_mongod = "#{MONGODB_ROOT}/bin/mongod"
  w.start = if File.exists?(vendor_mongod)
    "#{MONGODB_ROOT}/bin/mongod --dbpath #{GOD_RAILS_ROOT}/db"
  else
    "mongod --dbpath #{GOD_RAILS_ROOT}/db"
  end
end

watch('redis') do |w|
  w.start = "#{GOD_RAILS_ROOT}/vendor/redis-stable/src/redis-server"
end

watch('worker') do |w|
  w.start = "bundle exec sidekiq -r #{GOD_RAILS_ROOT} -L #{GOD_RAILS_ROOT}/log/sidekiq.log -t 1"
end

watch('node') do |w|
  w.dir = "#{GOD_RAILS_ROOT}/realtime"
  w.start = "node ."
end
