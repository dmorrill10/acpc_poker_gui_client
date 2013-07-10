# ???
group { "puppet":
  ensure => "present",
}

# Update apt
update = 'apt-get update'
exec { update:
  path => "/usr/bin",
}

package { "build-essential":
  ensure => installed,
  require  => Exec[update],
}
package { "openssl":
  ensure => installed,
  require  => Exec[update],
}
package { "libreadline6":
  ensure => installed,
  require  => Exec[update],
}
package { "libreadline6-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "zlib1g":
  ensure => installed,
  require  => Exec[update],
}
package { "zlib1g-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "libssl-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "libyaml-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "libxml2-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "libxslt-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "autoconf":
  ensure => installed,
  require  => Exec[update],
}
package { "libc6-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "ncurses-dev":
  ensure => installed,
  require  => Exec[update],
}
package { "automake":
  ensure => installed,
  require  => Exec[update],
}
package { "libtool":
  ensure => installed,
  require  => Exec[update],
}
package { "bison":
  ensure => installed,
  require  => Exec[update],
}
package { "bison":
  ensure => installed,
  require  => Exec[update],
}

# Ensure that NodeJS is installed
# @todo Include NodeJS Puppet module as Git submodule in acpc_poker_gui_client
class { 'nodejs': } -> package { 'serve': ensure => present, provider => 'npm', }

# Ensure that libreadline is installed
# Ensure that basic libraries are installed (libz, libxml, etc.) are installed

# Install gem dependencies
exec { "bundle install":
  path => "/vagrant"
}

# Ensure that redis is running
# Ensure that sidekiq is running
# Ensure that mongoDB data directory is present
# Ensure that mongoDB is running
# Ensure that thin is running
