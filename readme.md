# The Dataverse Network (DVN) on Vagrant

"The Dataverse Network is an open source application to publish, share, reference, extract and analyze research data." -- http://thedata.org

"Vagrant lowers development environment setup time, maximizes dev/prod parity, and makes the 'works on my machine' excuse a relic of the past." -- http://vagrantup.com

## What is this?

This git repo allows you spin up your own DVN installation on a virtual machine (VM) on your computer in roughly half an hour with a single command: `vagrant up`

The VM will be running CentOS 6 and the following software will be installed:

- DVN 3.2
- Glassfish 3.1.2.2
- PostgreSQL 8.4.13
- OpenJDK 1.6.0

## Installing dependencies

Before you can use this git repo, you need to install VirtualBox from https://virtualbox.org and Vagrant from http://vagrantup.com 

## Using this git repo to create your own DVN VM

From a terminal, type the following commands but please not that `vagrant up` will take a while, especially the first time you run it.

    git clone https://github.com/pdurbin/dvn-vagrant.git
    cd dvn-vagrant
    vagrant up

Assuming `vagrant up` completes successfully, you should be able to log into your new DVN installation with the following credentials:

- <http://localhost:8081/dvn>
- username: networkAdmin
- password: networkAdmin

You can ssh into the VM with `vagrant ssh` and start over by running `vagrant destroy` and `vagrant up` again.

## Details from `vagrant up`

Just to give you a sense of what `vagrant up` is doing, here's some output from a run:

    [pdurbin@tabby dvn-vagrant]$ vagrant up
    [default] Importing base box 'centos'...
    [default] The guest additions on this VM do not match the install version of
    VirtualBox! This may cause things such as forwarded ports, shared
    folders, and more to not work properly. If any of those things fail on
    this machine, please update the guest additions and repackage the
    box.

    Guest Additions Version: 4.1.18
    VirtualBox Version: 4.2.4
    [default] Matching MAC address for NAT networking...
    [default] Clearing any previously set forwarded ports...
    [default] Forwarding ports...
    [default] -- 22 => 2222 (adapter 1)
    [default] -- 8080 => 8081 (adapter 1)
    [default] Creating shared folders metadata...
    [default] Clearing any previously set network interfaces...
    [default] Preparing network interfaces based on configuration...
    [default] Running any VM customizations...
    [default] Booting VM...
    [default] Waiting for VM to boot. This can take a few minutes.
    [default] VM booted and ready for use!
    [default] Configuring and enabling network interfaces...
    [default] Mounting shared folders...
    [default] -- v-root: /vagrant
    [default] -- manifests: /tmp/vagrant-puppet/manifests
    [default] -- v-pp-m0: /tmp/vagrant-puppet/modules-0
    [default] Running provisioner: Vagrant::Provisioners::Puppet...
    [default] Running Puppet with /tmp/vagrant-puppet/manifests/init.pp...
    notice: /Stage[downloads]/Downloads/Exec[download_dvn_zip]/returns: executed successfully

    notice: /Stage[downloads]/Downloads/Exec[download_dvn_war]/returns: executed successfully

    notice: /Stage[packages]/Packages/Package[subversion]/ensure: created
    notice: /Stage[packages]/Packages/Package[postgresql-server]/ensure: created
    notice: /Stage[packages]/Packages/Package[java-1.6.0-openjdk]/ensure: created
    notice: /Stage[packages]/Packages/Package[java-1.6.0-openjdk-devel]/ensure: created
    notice: /Stage[packages]/Packages/Package[postfix]/ensure: created
    notice: /Stage[packages]/Packages/Package[elinks]/ensure: created
    notice: /Stage[main]/Dvn/File[/root/glassfish-install.sh]/ensure: defined content as '{md5}f6074a40ed3c9d7974a13397f111b7c8'

    notice: /Stage[main]/Dvn/Exec[postgres_init]/returns: executed successfully

    notice: /Stage[main]/Dvn/File[/root/glassfish-answerfile]/ensure: defined content as '{md5}6b331fe27e5b95e73d71c77abf2d5d6c'

    notice: /Stage[main]/Dvn/File[/root/dvn-vagrant-install.pl]/ensure: defined content as '{md5}d5a8d921ee9ad1252de69c430389c2ed'

    notice: /Stage[main]/Dvn/File[/etc/sysconfig/iptables]/content: content changed '{md5}5ee09def44bd598f82e3717df846e2fc' to '{md5}1d3b22448720bea45f69f37088be40fd'

    notice: /Stage[main]/Dvn/File[/root/dvn-install.sh]/ensure: defined content as '{md5}d15eb2a0ff1dac16c9465b0bb30cd27b'

    notice: /Stage[postgres]/Postgres/Exec[install_glassfish]/returns: executed successfully

    notice: /Stage[postgres]/Postgres/File[/var/lib/pgsql/data/pg_hba.conf]/content: content changed '{md5}a21038ed8e80ad95d01da9cb6b0ae403' to '{md5}a634189d83263d566f9a6874c11fcd57'

    notice: /Stage[postgres]/Postgres/Service[postgresql]/ensure: ensure changed 'stopped' to 'running'
    notice: /Stage[last]/Last/Service[iptables]: Triggered 'refresh' from 1 events
    notice: /Stage[last]/Last/Exec[dvn-install]/returns: executed successfully

    notice: Finished catalog run in 1621.53 seconds
    [pdurbin@tabby dvn-vagrant]$ 
