# ???
group { "puppet":
  ensure => "present",
}

# $Update apt
$update = 'apt-get update'
exec { $update:
  path => "/usr/bin",
}

# Ensure that basic libraries are installed (libz, libxml, etc.) are installed
package { "build-essential":
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

# Ensure that NodeJS is installed
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
$nodejs_repo = 'sudo apt-get-repository ppa:chris-lea/node.js'
exec { $nodejs_repo:
  path => "/usr/bin"
}
# @todo How do I require packages?
package { "nodejs":
  ensure => installed,
  require  => [Exec[$update], Exec[$nodejs_repo], Exec[$update], Package['python'], Package['g++'], Package['make'], Exec[$nodejs_repo]]
}

$app_root = '/vagrant'
$app_user = 'vagrant'
# Install gem dependencies
bundler::install { $app_root:
  user       => $app_user,
  # group      => $app_group,
  # deployment => true,
  # without    => 'development test doc',
}
exec { "bundle install":
  path => "/vagrant"
}

# Ensure that redis is installed
package { 'redis-server':
  ensure => installed,


}
# Ensure that mongoDB data directory is present
# Ensure that mongoDB is installed

# Ensure that god is running