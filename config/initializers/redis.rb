root = File.dirname(__FILE__) + '/../..'
c = YAML.load_file(root + '/config/redis.yml')
e = Rails.env || 'development'

if c[e]
  $redis = Redis.new(:host => c[e]['host'], :port => c[e]['port'])
  $redis_store = "redis://#{c[e]['host']}:#{c[e]['port']}/0/sessions"
end