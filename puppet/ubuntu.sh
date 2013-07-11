#!/usr/bin/env bash
# Based on https://github.com/hashicorp/puppet-bootstrap
#
# This bootstraps Puppet on Ubuntu 12.04 LTS.
#
if which puppet > /dev/null 2>&1; then
  echo "Puppet is already installed"
else
  echo -n "Adding Puppet repo..."
  wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
  sudo dpkg -i puppetlabs-release-precise.deb > /dev/null
  sudo apt-get update -y > /dev/null
  echo 'Done'

  echo "Installing Puppet..."
  sudo apt-get install -y puppet > /dev/null
  echo "Puppet installed!"
fi

# dmorrill10: Customizations
# Instal Puppet modules
function install_puppet_module {
  module=$1
  if [[ -z $(puppet module list | grep "$module") ]]; then
    puppet module install $module
  fi
}
install_puppet_module 'puppetlabs-ruby'
