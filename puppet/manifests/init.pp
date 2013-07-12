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
# package { "libxslt-dev":
#   ensure => installed,
#   require  => Exec[$update],
# }
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

include nodejs

include mongodb

include redis

# Redis
#-------
# $redis = 'redis-server'
# package { $redis:
#   ensure => 'installed',
#   require => Exec[$update]
# }

# Ruby
#----------
$home = '/home/vagrant'
$gemrc = "$home/.gemrc"
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

$app_user = 'vagrant'
rbenv::install { $app_user:
  home => $home
}

$ruby_version = '2.0.0-p247'
rbenv::compile { $ruby_version:
  user => $app_user,
  home => $home,
  global => true,
  require => File[$gemrc]
}

# rbenv::gem { "bundler":
#   user => $app_user,
#   ruby => $ruby_version,
# }

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
file { ['/data', $mongodb_data]:
  ensure => 'directory'
}



# User level
#-----------------
# $gems = '/home/vagrant/.rbenv/shims/bundle install'
# exec { $gems:
#   path => $app_root,
#   user => $app_user,
#   require => Rbenv::Compile[$ruby_version]
# }

# # Ensure that god is running
# $god = '/home/vagrant/.rbenv/shims/bundle exec /home/vagrant/.rbenv/shims/god -c config/god.vagrant.rb -l log/god.log'
# exec { $god:
#   path => $app_root,
#   user => $app_user,
#   require => [File[$mongodb_data], Class['redis'], Class['mongodb'], Class['redis'], Exec[$gems]]
# }

# # Set the development server running on the default port 3000
# exec { 'rails s':
#   path => $app_root,
#   user => $app_user,
#   require => Exec[$god]
# }
