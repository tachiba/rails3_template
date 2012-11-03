#
# Application Template
#

repo_url = "https://raw.github.com/tachiba/rails3_template/master"
gems = {}

@app_name = app_name

def get_and_gsub(source_path, local_path)
  get source_path, local_path

  gsub_file local_path, /%app_name%/, @app_name
  gsub_file local_path, /%app_name_classify%/, @app_name.classify
  gsub_file local_path, /%working_user%/, @working_user
  gsub_file local_path, /%working_dir%/, @working_dir
  #gsub_file local_path, /%remote_repo%/, @remote_repo if @remote_repo
end

def gsub_database(localpath)
  return unless @mysql

  gsub_file localpath, /%database_name%/, @mysql[:database_name] ? @mysql[:database_name] : @app_name

  gsub_file localpath, /%mysql_username_development%/, @mysql[:username_development]
  gsub_file localpath, /%mysql_remote_host_development%/, @mysql[:remote_host_development]

  gsub_file localpath, /%mysql_username_production%/, @mysql[:username_production]
  gsub_file localpath, /%mysql_password_production%/, @mysql[:password_production]
  gsub_file localpath, /%mysql_remote_host_production%/, @mysql[:remote_host_production]
end

#
# Gemfile
#
#gem 'mysql2', git: 'git://github.com/tachiba/mysql2.git'
gem 'mysql2'#, git: 'git://github.com/tachiba/mysql2.git'

# colorful logging(ANSI color)
gem 'rainbow'

# pagination
gem 'kaminari'

# form
gem 'dynamic_form'

# process monitor
gem 'god', require: false

# rails-sh
# https://github.com/jugyo/rails-sh
gem 'rails-sh', require: false

gem 'rails_config'

gem_group :deployment do
  # capistrano
  gem 'rvm-capistrano'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_colors'
  gem 'capistrano_rsync_with_remote_cache'
end

gem_group :test, :development do
  # test
  gem "rspec-rails"
  gem "factory_girl_rails", "~> 3.0"
  gem 'faker'
  gem 'sqlite3'

  gem 'thin'
end

gem_group :development do
  gem 'pry-rails'
end

gem 'haml-rails'

#gem 'active_decorator'
gem 'permanent_records'

gem 'cells'

gem 'tapp'

#gem 'turbo-sprockets-rails3'

comment_lines 'Gemfile', "gem 'sqlite3'"
uncomment_lines 'Gemfile', "gem 'therubyracer'"
uncomment_lines 'Gemfile', "gem 'unicorn'"

# xml-sitemap
#if yes?("Would you like to install xml-sitemap?")
gem 'xml-sitemap'
#end

# whenever
#if yes?("Would you like to install whenever?")
gem 'whenever', require: false
#end

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
  #gems[:redis_rails] = yes?("Would you like to install redis-rails?")
  #if gems[:redis_rails]
  #  gem 'redis-rails'
  #end
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

#
# Bundle install
#
run "bundle install"

# capify application
capify!

@deploy_via_remote = false
if yes?("Do you deploy via remote capistrano?")
  @deploy_via_remote = true
else
  # deploy via rsync
end

@working_user = ask("What is your remote working user?")
@working_dir = ask("What is your remote working dir? e.g.) /path/to/working_dir")

if @deploy_via_remote
  @remote_repo = ask("What is your remote git repo? e.g.) username@hostname")
end

@mysql = false
if yes?("set up mysql now?")
  @mysql = {}
  @mysql[:database_name] = ask("database name?")

  @mysql[:remote_host_development] = ask("mysql:development remote host?")
  @mysql[:username_development] = ask("mysql:development username?")

  @mysql[:remote_host_production] = ask("mysql:production remote host?")
  @mysql[:username_production] = ask("mysql:production username?")
  @mysql[:password_production] = ask("mysql:production password?")
end

if gems[:redis]
  @redis = {}
  @redis[:development] = ask("redis development server?")
  @redis[:production] = ask("redis production server?")
end

#
# Files and Directories
#

# use Rspec instead of TestUnit
remove_dir 'test'

application <<-APPEND_APPLICATION
config.generators do |generate|
      generate.test_framework   :rspec, :fixture => true, :views => false
      generate.integration_tool :rspec, :fixture => true, :views => true
    end
APPEND_APPLICATION

# Capfile
uncomment_lines "Capfile", "load 'deploy/assets'"

# .gitignore
remove_file '.gitignore'
get "#{repo_url}/gitignore", '.gitignore'

remove_file "public/index.html"
remove_file "app/views/layouts/application.html.erb"

# locales/ja.yml
get "#{repo_url}/config/locales/ja.yml", "config/locales/ja.yml"

# helpers
remove_file "app/helpers/application_helper.rb"
get "#{repo_url}/app/helpers/application_helper.rb", "app/helpers/application_helper.rb"

# views
empty_directory "app/views/shared"
%w(socialize socialize_lib paginate socialize_facebook socialize_google socialize_hatebu socialize_twitter).each do |key|
  get "#{repo_url}/app/views/shared/_#{key}.html.erb", "app/views/shared/_#{key}.html.erb"
end

empty_directory "app/views/kaminari"
%w(first_page gap last_page next_page page paginator prev_page).each do |key|
  get "#{repo_url}/app/views/kaminari/_#{key}.html.erb", "app/views/kaminari/_#{key}.html.erb"
end

# public
empty_directory "public/system/cache"

# lib
empty_directory "lib/runner"
empty_directory "lib/jobs"
get "#{repo_url}/lib/sitemap.rb", 'lib/sitemap.rb'

# config
create_file "config/schedule.rb"
remove_file "config/deploy.rb"

get_and_gsub "#{repo_url}/config/deploy.rb", 'config/deploy.rb'
if @deploy_via_remote
  gsub_file 'config/deploy.rb', /%deploy_repo%/, "#@remote_repo:#@app_name.git"
  uncomment_lines 'config/deploy.rb', %(set :deploy_via, :remote_cache)
else
  gsub_file 'config/deploy.rb', /%deploy_repo%/, '.'
  uncomment_lines 'config/deploy.rb', %(set :deploy_via, :rsync_with_remote_cache)
end

get_and_gsub "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'

# config/database.yml
if @mysql
  remove_file "config/database.yml"
  get_and_gsub "#{repo_url}/config/database.yml", 'config/database.yml'
  gsub_database 'config/database.yml'
end

# config/application.rb
insert_into_file "config/application.rb",
                 %(    config.autoload_paths += Dir[Rails.root.join('lib')]\n),
                 after: "# Custom directories with classes and modules you want to be autoloadable.\n"

insert_into_file "config/application.rb",
                 %(    config.i18n.default_locale = :ja\n),
                 after: "# config.i18n.default_locale = :de\n"

insert_into_file "config/application.rb",
                 %(    config.autoload_paths += Dir[Rails.root.join('app', 'models')]\n),
                 after: "# Custom directories with classes and modules you want to be autoloadable.\n"

insert_into_file "config/application.rb",
                 %(    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]\n),
                 after: "# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.\n"

# config/environments
#insert_into_file "config/environments/production.rb",
#                 %(  config.assets.precompile += %w( *.css *.js )\n),
#                 after: "# Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)\n"

insert_into_file "config/environments/production.rb",
                 %(  config.action_controller.page_cache_directory = Rails.root.join("public", "system", "cache")\n),
                 after: "# config.cache_store = :mem_cache_store\n"

insert_into_file "config/environments/production.rb",
                 %(  config.assets.static_cache_control = "public, max-age=#{60 * 60 * 24}"\n),
                 after: "# config.cache_store = :mem_cache_store\n"

# config/god
empty_directory "config/god"
get_and_gsub "#{repo_url}/config/god/unicorn.rb", 'config/god/unicorn.rb'

# config/deploy
empty_directory "config/deploy"
get_and_gsub "#{repo_url}/config/deploy/production.rb", 'config/deploy/production.rb'

# config/initializers
#if gems[:redis_rails]
#  gsub_file "config/initializers/session_store.rb", /:cookie_store, .+/, ":redis_store, servers: $redis_store, expires_in: 30.minutes"
#end

#get "#{repo_url}/config/initializers/config.rb", 'config/initializers/config.rb'
get "#{repo_url}/config/initializers/rainbow.rb", 'config/initializers/rainbow.rb'

if gems[:redis]
  get "#{repo_url}/config/initializers/redis.rb", 'config/initializers/redis.rb'
  get "#{repo_url}/config/redis.yml", 'config/redis.yml'

  gsub_file 'config/redis.yml', /%redis_development%/, @redis[:development]
  gsub_file 'config/redis.yml', /%redis_production%/, @redis[:production]

  if gems[:resque]
    get "#{repo_url}/config/initializers/resque.rb", 'config/initializers/resque.rb'
    #get "#{repo_url}/lib/tasks/resque.rake", 'lib/tasks/resque.rake'

    insert_into_file "Rakefile",
                     %(require 'resque/tasks'),
                     after: "require File.expand_path('../config/application', __FILE__)\n"
  end
end

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

  gsub_file "app/views/layouts/application.html.haml", /lang="en"/, %(lang="ja")
end

generate 'rspec:install'

generate 'rails_config:install'

#
# Git
#
git :init
git :add => '.'
git :commit => '-am "Initial commit"'

if @deploy_via_remote && @remote_repo
  git :remote => "add origin #@remote_repo:#@app_name.git"
end