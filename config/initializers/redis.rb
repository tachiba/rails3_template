$redis = Redis.new(
  host: Settings.redis.host,
  port: Settings.redis.port,
  database: Settings.redis.database
)
$redis.auth(Settings.redis.auth) if Settings.redis.auth

$redis_url = "redis://:%s@%s:%d/%d" % [
  Settings.redis.auth,
  Settings.redis.host,
  Settings.redis.port,
  Settings.redis.database
]
