#!/usr/bin/env rake

RAILS_ROOT = File.expand_path('../', __FILE__)
require_relative 'config/application'

AcpcPokerGuiClient::Application.load_tasks


namespace :in do
  desc 'Change to production environment'
  task :prod do
    Rails.env = 'production'
  end
  desc 'Change to test environment'
  task :test do
    Rails.env = 'test'
  end
  desc 'Change to development environment'
  task :dev do
    Rails.env = 'development'
  end
end

namespace :compile do
  desc 'Compile acpc_dealer'
  task :dealer do
    sh %{ acpc_dealer compile }
  end
  # Assets
  desc 'Precompiles assets. Only do in production.'
  task :assets => ['in:prod', 'assets:precompile']
end

namespace :install do
  # Project hierarchy
  VENDOR_DIRECTORY = "#{RAILS_ROOT}/vendor"
  directory VENDOR_DIRECTORY
  DB_DATA_DIRECTORY = "#{RAILS_ROOT}/db/data"
  directory DB_DATA_DIRECTORY

  # MongoDB
  MONGODB_DIRECTORY = "#{VENDOR_DIRECTORY}/mongoDB"
  file MONGODB_DIRECTORY do
    puts(
      "Please download a MongoDB version compatible with your system " +
      "from http://www.mongodb.org/downloads, unpack the compressed file to " +
      "`<project root>/vendor`, and rename the resulting directory to `mongoDB`."
    )
    raise
  end
  MONGOD_EXECUTABLE = "#{MONGODB_DIRECTORY}/bin/mongod"
  file MONGOD_EXECUTABLE => MONGODB_DIRECTORY

  desc 'Complete MongoDB setup'
  task :mongodb => [DB_DATA_DIRECTORY, MONGOD_EXECUTABLE]

  # Redis
  REDIS_DIRECTORY = File.join(VENDOR_DIRECTORY, 'redis-stable')
  file REDIS_DIRECTORY => VENDOR_DIRECTORY do
    Dir.chdir(VENDOR_DIRECTORY) do
      sh %{ wget http://download.redis.io/redis-stable.tar.gz }
      sh %{ tar xvzf redis-stable.tar.gz }
      sh %{ rm -f xvzf redis-stable.tar.gz }
    end
  end
  REDIS_EXECUTABLE = File.join(REDIS_DIRECTORY, 'src', 'redis-server')
  file REDIS_EXECUTABLE => REDIS_DIRECTORY do
    Dir.chdir(File.join(REDIS_DIRECTORY, 'src')) do
      sh %{ make }
    end
  end

  desc 'Complete Redis setup'
  task :redis => [REDIS_EXECUTABLE]

  # Gems
  namespace :gems do
    desc 'Installs gem dependencies for development'
    task :dev do
      sh %{ bundle install }
    end

    desc 'Installs gem dependencies for production'
    task :prod do
      sh %{ bundle install --without development test }
    end
  end

  # Full installation
  desc 'Installs all dependencies for development'
  task :dev => ['in:dev', :mongodb, :redis, 'gems:dev', 'compile:dealer']

  desc 'Installs all dependencies for production, other than production web server'
  task :prod => ['in:prod', :mongodb, :redis, 'gems:prod', 'compile:dealer', 'compile:assets']
end

namespace :update do
  desc 'Update gems and assets in production'
  task :prod => ['in:prod', 'install:gems:prod', 'install:assets']

  desc 'Update gems and assets in development'
  task :prod => ['in:dev', 'install:gems:dev']
end
