#
#= git
#
set :repository,  "%remote_repo%:%app_name%.git"
set :scm, :git
set :branch, "master"
set :deploy_via, :remote_cache

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
#= precompile
#
#namespace :deploy do
#  namespace :assets do
#    task :precompile, :roles => :web, :except => { :no_release => true } do
#      from = source.next_revision(current_revision)
#      if releases.length <= 1 ||
#          capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
#        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
#      else
#        logger.info "Skipping asset pre-compilation because there were no asset changes"
#      end
#    end
#  end
#end


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