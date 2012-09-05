#
# Application Template
#

p File.basename(__FILE__)

gems = {}

#
# Gemfile
#
gem 'mysql2', git: 'git://github.com/tachiba/mysql2.git'

# colorful logging(ANSI color)
gem 'rainbow'

# pagination
gem 'kaminari'

# form
gem 'dynamic_form'

# process monitor
gem 'god', require: false

# capistrano
gem_group :deployment do
  gem 'rvm-capistrano'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_colors'
end

# test
gem_group :test do
  gem "rspec-rails"
  gem "factory_girl_rails", "~> 3.0"
  gem 'faker'
  gem 'sqlite3'
end

comment_lines 'Gemfile', "gem 'sqlite3'"
uncomment_lines 'Gemfile', "gem 'therubyracer'"
uncomment_lines 'Gemfile', "gem 'unicorn'"

# whenever
if yes?("Would you like to install whenever?")
  gem 'whenever', require: false
end

# redis
gems[:redis] = yes?("Would you like to install redis?")
if gems[:redis]
  gem 'redis'

  # resque
  gems[:resque] = yes?("Would you like to install resque?")
  if gems[:resque]
    gem 'resque'
  end

  # redis-rails
  gems[:redis_rails] = yes?("Would you like to install redis-rails?")
  if gems[:redis_rails]
    gem 'redis-rails'
  end
end

# twitter bootstrap
gems[:bootstrap] = yes?("Would you like to install bootstrap?")
if gems[:bootstrap]
  gem 'less-rails'
  gem 'twitter-bootstrap-rails', group: 'assets'
end

# feedzirra
if yes?("Would you like to install feedzirra?")
  gem 'feedzirra'
end

# nokogiri
if yes?("Would you like to install nokogiri?")
  gem 'nokogiri'
end

# xml-sitemap
if yes?("Would you like to install xml-sitemap?")
  gem 'xml-sitemap'
end

#
# Bundle install
#
run "bundle install"

# capify application
capify!

#
# Files and Directories
#

remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"

# lib
empty_directory "lib/runner"
empty_directory "lib/jobs"

# config
create_file "config/config.yml", "empty: true"
create_file "config/schedule.rb"
remove_file "config/deploy.rb"

# initializers
gsub_file "config/initializers/session_store.rb", /:cookie_store, .+/, ":redis_store, servers: $redis_store, expires_in: 30.minutes"

#
# Generators
#

if gems[:bootstrap]
  generate 'bootstrap:install'

  if yes?("Would you like to create FIXED layout?(yes=FIXED, no-FLUID)")
    generate 'bootstrap:layout application fixed'
  else
    generate 'bootstrap:layout application fluid'
  end
end

#
# Git
#
git :init
git :add => '.'
git :commit => '-am "Initial commit"'
