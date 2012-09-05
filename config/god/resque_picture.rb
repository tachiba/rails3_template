case (app_env = ENV['RAILS_ENV'] || "development")
  when 'production'
    app_root = "/home/naver/web/admin/current"
    worker_count = 1

  when 'development'
    app_root = "/home/naver/web/admin/development"
    worker_count = 1

  else
    worker_count = 0
    exit(1)
end

# SEE: https://github.com/defunkt/resque/blob/master/examples/god/resque.god
worker_count.times do |i|
  God.watch do |w|
    w.dir = app_root
    w.name = "resque-pic-#{i}"
    w.group = "resque-naver"
    w.interval = 30.seconds

    w.env = {
      "QUEUE"           => 'naver_matome_picture_high, naver_matome_picture',
      'BUNDLE_GEMFILE'  => "#{app_root}/Gemfile",
      "RAILS_ENV"       => app_env,
      #"PATH"            => USER_PATH
    }

    w.start = "bundle exec rake environment resque:work"

    w.log = "#{app_root}/log/resque.log"
    #w.log = GOD_LOG

    w.uid = 'naver'
    w.gid = 'naver'

    #w.restart_if do |restart|
    #  restart.condition(:memory_usage) do |c|
    #    c.above = 100.megabytes
    #    c.times = 5
    #  end
    #
    #  restart.condition(:cpu_usage) do |c|
    #    c.above = 50.percent
    #    c.times = 5
    #  end
    #end

    w.start_if do |start|
      start.condition(:process_running) do |c|
        c.interval = 5.seconds
        c.running = false
      end
    end

    # lifecycle
    #w.lifecycle do |on|
    #  on.condition(:flapping) do |c|
    #    c.to_state = [:start, :restart]
    #    c.times = 5
    #    c.within = 5.minute
    #    c.transition = :unmonitored
    #    c.retry_in = 10.minutes
    #    c.retry_times = 5
    #    c.retry_within = 2.hours
    #  end
    #end
  end
end