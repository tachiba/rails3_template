#
#= RVM integration
# https://rvm.io/integration/capistrano/
#
#set :rvm_ruby_string, '1.9.3'
#require "rvm/capistrano"

#
#= Bundler integration
#
require "bundler/capistrano"

#
#= Whenever integration
#
require "whenever/capistrano"
set :whenever_roles, defer { :app }
set :whenever_command, "bundle exec whenever"
set :whenever_environment, defer { stage }

#
#= separate by env
#
require 'capistrano/ext/multistage'

#= colorful!
require 'capistrano_colors'

set :application, "NaverMatome"
set :application_underscore, "naver_matome_admin"
set :default_stage, "production"

#
#= git
#
set :repository,  "git@gitlab.wondershake.com:naver_matome_admin.git"
set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

#
#= ssh
#
set :user, "naver"
set :use_sudo, false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

after "deploy:update", "deploy:cleanup"

#
#= precompile
#
namespace :assets do
  task :precompile, :roles => :app do
    run "cd #{latest_release} && RAILS_ENV=#{stage} bundle exec rake assets:precompile"
  end

  task :cleanup, :roles => :app do
    run "cd #{latest_release} && RAILS_ENV=#{stage} bundle exec rake assets:clean"
  end
end

after "deploy:update_code", "assets:precompile"

#
#= god
#
namespace :god do
  task :reload do
    run "rvmsudo RAILS_ENV=#{stage} BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec god load /etc/god/god.rb"
  end

  task :restart_unicorn do
    run "rvmsudo RAILS_ENV=#{stage} BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec god restart unicorn_#{application_underscore}"
  end
end

after "deploy:restart", "god:reload"
after "deploy:restart", "god:restart_unicorn"