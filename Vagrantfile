# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu-precise-32bit-vanilla"

  # The url from where the 'config.vm.box' box will be fetched if it
  # doesn't already exist on the user's system.
  config.vm.box_url = "https://dl.dropboxusercontent.com/u/165709740/boxes/precise32-vanilla.box"

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  config.vm.network :forwarded_port, guest: 3000, host: 3000

  config.vm.provision :shell, path: 'puppet/ubuntu.sh'

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.manifest_file  = "init.pp"
  end

  config.vm.provider "virtualbox" do |v|
    # @todo These are supposed to make installing gems faster
    #   (because they are intolerably slow by default)
    #   but I haven't tested yet
    v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    # @todo Need to enable IO ACPI for this to work properly
    # v.customize ["modifyvm", :id, "--cpus", 2]
  end
end
