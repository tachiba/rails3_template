require 'resque'

Resque.redis = $redis

# deprecated
#Resque.after_fork = Proc.new do
#  Rails.logger.auto_flushing = true
#end

require 'resque/server'

#Resque::Server.use Rack::Auth::Basic do |username, password|
#  username == CONFIG['auth']['resque']['username']
#  password == CONFIG['auth']['resque']['password']
#end