# frozen_string_literal: true

require 'rake/testtask'
require 'fileutils'
require_relative 'require_app'
require 'bundler/setup'
# Bundler.require(:default)

task :default do
  puts `rake -T`
end

# run all test
desc 'Run tests once'
Rake::TestTask.new(:spec) do |t|
  t.libs << 'lib' << 'spec'
  t.pattern = 'spec/**/*_spec.rb'
  # t.pattern = 'spec/spotify_api_spec.rb'
  # t.pattern = 'spec/gateway_database_spec.rb'
  t.warning = false
end

desc 'Keep rerunning tests upon changes'
task :respec do
  sh "rerun -c 'rake spec' --ignore 'coverage/*'"
end

desc 'Run application console (irb)'
task :console do
  sh 'pry -r ./load_all'
end

# manage vcr record file
namespace :vcr do
  desc 'delete cassette fixtures (*.yml)'
  task :wipe do
    files = Dir['spec/fixtures/cassettes/*.yml']
    if files.empty?
      puts 'No cassettes found'
    else
      FileUtils.rm_f(files)
      puts "Cassettes deleted: #{files.size}"
    end
  end
end

# check code quality
namespace :quality do
  desc 'run all quality checks'
  task all: %i[rubocop reek flog]

  desc 'Run RuboCop'
  task :rubocop do
    puts '[RuboCop]'
    sh 'bundle', 'exec', 'rubocop', *CODE_DIRS do
      puts # avoid aborting
    end
  end

  desc 'Run Reek'
  task :reek do
    puts '[Reek]'
    sh 'bundle', 'exec', 'reek', *CODE_DIRS do
      puts # avoid aborting
    end
  end

  desc 'Run Flog'
  task :flog do
    puts '[Flog]'
    sh 'bundle', 'exec', 'flog', *CODE_DIRS
  end
end

# run application
desc 'Run the webserver and application and restart if code changes'
task :rerun do
  # --- Kill old Puma or rerun processes ---
  puts '[rerun] Killing previous Puma processes...'
  sh 'pkill -f puma || true'
  sh 'pkill -f rerun || true'

  # --- Start new rerun watcher ---
  sh "rerun -c --ignore 'coverage/*' -- bundle exec rake run"
end

desc 'Run web app in default (dev) mode'
task run: ['run:dev']

namespace :run do
  desc 'Run API in dev mode'
  task :dev do
    sh 'bundle exec puma -p 9000'
  end

  desc 'Run API in test mode'
  task :test do
    sh 'RACK_ENV=test bundle exec puma -p 9000'
  end
end

# session
desc 'Generates a 64 by secret for Rack::Session'
task :new_session_secret do
  require 'base64'
  require 'securerandom'
  secret = SecureRandom.random_bytes(64).then { Base64.urlsafe_encode64(it) }
  puts "SESSION_SECRET: #{secret}"
end
