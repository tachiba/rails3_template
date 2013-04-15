#
#= git
#
set :repository, "%deploy_repo%"
set :scm, :git
set :branch, "master"
#set :deploy_via, :remote_cache
#set :deploy_via, :rsync_with_remote_cache

#
#= ssh
#
set :user, "%working_user%"
set :use_sudo, false
default_run_options[:pty] = true
ssh_options[:forward_agent] = true

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

set :application, "%app_name_classify%"
set :application_underscore, "%app_name%"
set :default_stage, "production"

after "deploy:update", "deploy:cleanup"

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
