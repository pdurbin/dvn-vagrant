class packages {

  $dvn_packages = [
    'java-1.6.0-openjdk',
    'java-1.6.0-openjdk-devel',
    'postgresql-server',
    'subversion',
    'elinks',  # for testing
    'postfix', # unused 
  ]

  package { $dvn_packages:
    ensure => installed,
  }

}
