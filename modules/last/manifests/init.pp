class last {

  service { 'iptables':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/sysconfig/iptables'],
  }

  exec { "dvn-install":
    command => '/bin/bash /root/dvn-install.sh',
    onlyif  => "/usr/bin/test ! -e /opt/glassfish/glassfish/domains/domain1/applications/DVN-web",
    timeout => 0,
  }

}
