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
end

#
# Gemfile
#
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

# config
gem 'rails_config'

# haml integration
gem 'haml-rails'

# awesome debugging
gem 'tapp'

# sitemap.xml
gem 'xml-sitemap'

# crontab integration
gem 'whenever', require: false

gem 'cells'

gem_group :deployment do
  # capistrano
  gem 'rvm-capistrano'
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_colors'
#  gem 'capistrano_rsync_with_remote_cache'
end

gem_group :test, :development do
  # test
  gem "rspec-rails", "~> 2.12.0"
  gem "factory_girl_rails", "~> 3.0"
  gem 'faker'
  gem 'sqlite3'
end

gem 'webmock', :require => false

gem_group :development do
  gem 'pry-rails'
end

gem_group :assets do
  gem 'less-rails'
  gem 'twitter-bootstrap-rails'
  gem 'turbo-sprockets-rails3'
end

# TODO presenter, view model gem?
#gem 'active_decorator'

# logical deletion
gem 'permanent_records'

uncomment_lines 'Gemfile', "gem 'therubyracer'"
uncomment_lines 'Gemfile', "gem 'unicorn'"

# redis
gems[:redis] = yes?("Would you like to use redis?")
if gems[:redis]
  gem 'redis'

  # sidekiq
  gems[:sidekiq] = yes?("Would you like to use sidekiq?")
  if gems[:sidekiq]
    gem 'sidekiq'
  end
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

@deploy_via_remote = yes?("Do you deploy via remote capistrano?(or rsync)") ? true : false

@working_user = ask("What is your remote working user?")
@working_dir = ask("What is your remote working dir? e.g.) /path/to/working_dir")

if @deploy_via_remote
  @remote_repo = ask("What is your remote git repo?")
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
  gsub_file 'config/deploy.rb', /%deploy_repo%/, "#@remote_repo"
  uncomment_lines 'config/deploy.rb', %(set :deploy_via, :remote_cache)
else
  gsub_file 'config/deploy.rb', /%deploy_repo%/, '.'
  uncomment_lines 'config/deploy.rb', %(set :deploy_via, :rsync_with_remote_cache)
end

get_and_gsub "#{repo_url}/config/unicorn.rb", 'config/unicorn.rb'

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

insert_into_file "config/environments/production.rb",
                 %(  config.action_controller.page_cache_directory = Rails.root.join("public", "system", "cache")\n),
                 after: "# config.cache_store = :mem_cache_store\n"

insert_into_file "config/environments/production.rb",
                 %(  config.assets.static_cache_control = "public, max-age=#{60 * 60 * 24}"\n),
                 after: "# config.cache_store = :mem_cache_store\n"

# config/god
empty_directory "config/god"
get_and_gsub "#{repo_url}/config/god/unicorn.rb", 'config/god/unicorn.rb'
get_and_gsub "#{repo_url}/config/god/unicorn_worker.rb", 'config/god/unicorn_worker.rb'

# config/deploy
empty_directory "config/deploy"
get_and_gsub "#{repo_url}/config/deploy/production.rb", 'config/deploy/production.rb'

get "#{repo_url}/config/initializers/rainbow.rb", 'config/initializers/rainbow.rb'

if gems[:redis]
  get "#{repo_url}/config/initializers/redis.rb", 'config/initializers/redis.rb'

  if gems[:sidekiq]
    get "#{repo_url}/config/initializers/sidekiq.rb", 'config/initializers/sidekiq.rb'
  end
end

#
# Generators
#

# bootstrap
generate 'bootstrap:install'

if yes?("Would you like to create FIXED layout?(yes=FIXED, no-FLUID)")
  generate 'bootstrap:layout application fixed'
else
  generate 'bootstrap:layout application fluid'
end

gsub_file "app/views/layouts/application.html.haml", /lang="en"/, %(lang="ja")

# rspec
generate 'rspec:install'

# rails_config
generate 'rails_config:install'

#
# Git
#
git :init
git :add => '.'
git :commit => '-am "Initial commit"'

if @deploy_via_remote && @remote_repo
  git :remote => "add origin #@remote_repo"
end
