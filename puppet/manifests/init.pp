group { "puppet":
  ensure => "present",
}

# $Update apt
$update = 'apt-get update'
exec { $update:
  path => "/usr/bin",
}

# Basic libraries (libz, libxml, etc.)
#---------------
package { "build-essential":
  ensure => installed,
  require  => Exec[$update],
}
package { "git":
  ensure => installed,
  require  => Exec[$update],
}
package { "openssl":
  ensure => installed,
  require  => Exec[$update],
}
package { "libreadline6":
  ensure => installed,
  require  => Exec[$update],
}
package { "libreadline6-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "zlib1g":
  ensure => installed,
  require  => Exec[$update],
}
package { "zlib1g-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "libssl-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "libyaml-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "libxml2-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "libxslt-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "autoconf":
  ensure => installed,
  require  => Exec[$update],
}
package { "libc6-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "ncurses-dev":
  ensure => installed,
  require  => Exec[$update],
}
package { "automake":
  ensure => installed,
  require  => Exec[$update],
}
package { "libtool":
  ensure => installed,
  require  => Exec[$update],
}
package { "bison":
  ensure => installed,
  require  => Exec[$update],
}

# NodeJS
#---------
package { 'python-software-properties':
  ensure => installed,
  require => Exec[$update]
}
package { 'python':
  ensure => installed,
  require => Exec[$update]
}
package { 'g++':
  ensure => installed,
  require => Exec[$update]
}
package { 'make':
  ensure => installed,
  require => Exec[$update]
}
$nodejs_repo = 'sudo add-apt-repository -y ppa:chris-lea/node.js'
exec { $nodejs_repo:
  path => "/usr/bin"
}
$nodejs = "nodejs"
package { $nodejs:
  ensure => installed,
  require  => [Exec[$update], Package['python'], Package['g++'], Package['make'], Exec[$nodejs_repo], Exec[$update]]
}

# MongoDB
#------------
$mongodb_key = 'sudo apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10'
exec { $mongodb_key:
  path => '/usr/bin'
}
$mongodb_source_list_entry = "echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/10gen.list"
exec { $mongodb_source_list_entry:
  path => '/usr/bin'
}
$mongodb = 'mongodb-10gen'
package { $mongodb:
  ensure => 'installed',
  require => [Exec[$mongodb_key], Exec[$mongodb_source_list_entry], Exec[$update]]
}

# Redis
#-------
$redis = 'redis-server'
package { $redis:
  ensure => 'installed',
  require => Exec[$update]
}

# Ruby
#----------
$gemrc = '/home/vagrant/.gemrc'
file { $gemrc:
  ensure => file,
  content => '---
:verbose: true
gem: --no-ri --no-rdoc
:backtrace: false
:bulk_threshold: 1000
:benchmark: false
'
}

class { 'ruby':
  version => '2.0.0-p247',
  gems_version  => 'latest',
  require => File[$gemrc]
}

# $ruby_version = '2.0.0-p247'

# rbenv rehash
# rbenv global $ruby_version

# $rbenv = '~/.rbenv'
# $clone_rbenv = 'clone_rbenv'
# exec { $clone_rbenv:
#   command => "git clone https://github.com/sstephenson/rbenv.git $rbenv",
#   creates => $rbenv
# }

# $ruby_build = '~/.rbenv/plugins/ruby-build'
# $clone_ruby_build = 'clone_ruby_build'
# exec { $clone_ruby_build:
#   command => "git clone https://github.com/sstephenson/ruby-build.git $ruby_build"
#   creates => $ruby_build
#   require => Exec[$clone_rbenv]
# }

# $restart_shell = 'exec $SHELL -l'
# exec { $restart_shell }

# $rbenv_install =
# exec { $rbenv_install:
#   command => "rbenv install $ruby_version",
#   creates => '$rbenv/shims/ruby'
#   require => [Exec[$restart_shell], Exec[$ruby_build]]
# }

# $rbenv_init = 'echo \'eval "$(rbenv init -)"\' >> ~/.profile'
# exec { $rbenv_init:
#   before => $restart_shell
# }

# $rbenv_path = 'echo \'export PATH="$HOME/.rbenv/bin:$PATH"\' >> ~/.profile'
# exec { $rbenv_path:
#   before => $rbenv_init
# }

# Start the application
#-----------
$app_root = '/vagrant'
$mongodb_data = '/data/db'
# Ensure that mongoDB data directory is present
file { $mongodb_data:
  ensure => 'directory'
}
# Install gems
$bundler = 'gem install bundler'
package { $bundler:
  require => [File[$gemrc], Class['ruby']]
}
$bundle_install = 'bundle install'
exec { $bundle_install:
  path => $app_root,
  require => [Package[$nodejs], Package[$bundler]]
}

# Ensure that god is running
$god = 'bundle exec god -c config/god.vagrant.rb -l log/god.log'
exec { $god:
  path => $app_root,
  require => [File[$mongodb_data], Package[$redis], Package[$mongodb], Exec[$bundle_install]]
}
# Set the development server running on the default port 3000
exec { 'rails s':
  path => $app_root,
  require => [Exec[$god]]
}
