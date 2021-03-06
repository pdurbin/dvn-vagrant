class postgres {

  file { '/var/lib/pgsql/data/pg_hba.conf':
    source  => 'puppet:///modules/bucket/var/lib/pgsql/data/pg_hba.conf',
    owner   => 'postgres',
    group   => 'postgres',
    mode    => '0600',
    require => Package['postgresql-server'],
  }

  service { 'postgresql':
    ensure  => running,
    enable  => true,
    require => File['/var/lib/pgsql/data/pg_hba.conf'],
  }

  exec { "install_glassfish":
    command => "/bin/bash /root/glassfish-install.sh",
    onlyif  => "/usr/bin/test ! -e /opt/glassfish",
    timeout => 0,
  }

}
