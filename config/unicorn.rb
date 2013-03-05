rails_env = ENV['RAILS_ENV']

case rails_env.to_sym
  when :staging
    worker_processes 1
    preload_app true

  when :production
    worker_processes 1
    preload_app true

  else
    worker_processes 1
end

app_path = File.expand_path(File.join(File.dirname(File.expand_path(__FILE__)), '../../../current'))
working_directory app_path

# Load rails+github.git into the master before forking workers
# for super-fast worker spawn times
#preload_app true

# Restart any workers that haven't responded in 30 seconds
timeout 30

# socket
listen "/tmp/%app_name%_#{rails_env}.sock"

# pid
pid File.expand_path('tmp/pids/unicorn.pid', app_path)

# log
stderr_path File.expand_path('log/unicorn.log', app_path)
stdout_path File.expand_path('log/unicorn.log', app_path)

# http://www.rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
if GC.respond_to?(:copy_on_write_friendly=)
  GC.copy_on_write_friendly = true
end

# SEE: http://blog.willj.net/2011/08/02/fixing-the-gemfile-not-found-bundlergemfilenotfound-error/
before_exec do |server|
  ENV['BUNDLE_GEMFILE'] = app_path + "/Gemfile"
end

# SEE
# http://d.hatena.ne.jp/milk1000cc/20100804/1280893810
before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!

  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH

    end
  end
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection

  if $redis_url
    Sidekiq.configure_client do |config|
      config.redis = { :url => $redis_url , :namespace => 'sidekiq'}
    end
  end
end
