app_name = "%app_name%"
user = "%working_user%"
app_root = "%working_dir%/current"
app_env = ENV['RAILS_ENV'] || "development"

# SEE: https://github.com/blog/519-unicorn-god
# SEE also: http://unicorn.bogomips.org/SIGNALS.html

God.watch do |w|
  w.name = "unicorn_#{app_name}"
  w.group = "unicorn"
  w.interval = 30.seconds

  w.dir = app_root

  w.env = {
    'BUNDLE_GEMFILE'  => "#{app_root}/Gemfile"
  }

  # unicorn needs to be run from the rails root
  w.start = "bundle exec unicorn_rails -c #{app_root}/config/unicorn.rb -E #{app_env} -D"

  # QUIT gracefully shuts down workers
  w.stop = "kill -QUIT `cat #{app_root}/tmp/pids/unicorn.pid`"

  # USR2 causes the master to re-create itself and spawn a new worker pool
  w.restart = "kill -USR2 `cat #{app_root}/tmp/pids/unicorn.pid`"

  w.start_grace = 10.seconds
  w.restart_grace = 10.seconds

  w.pid_file = "#{app_root}/tmp/pids/unicorn.pid"
  w.log = "#{app_root}/log/unicorn.log"

  w.uid = user
  w.gid = user

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.above = 300.megabytes
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.above = 50.percent
      c.times = 5
    end
  end

  # lifecycle
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