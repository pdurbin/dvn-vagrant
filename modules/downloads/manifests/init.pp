class downloads {

  exec { "download_dvn_zip":
    command => '/usr/bin/wget -O - http://sourceforge.net/projects/dvn/files/dvn/3.3/dvninstall_v3_3.zip/download > /root/dvninstall_v3_3.zip',
    onlyif  => "/bin/touch /root/dvninstall_v3_3.zip && /usr/bin/test `/usr/bin/md5sum /root/dvninstall_v3_3.zip | cut -d' ' -f1` != '3418b7d024fa2bb2c1164f4ebf8bc91a'",
    timeout => 0,
  }

  exec { "download_dvn_war":
    command => '/usr/bin/wget -O - http://sourceforge.net/projects/dvn/files/dvn/3.3/DVN-web_v3_3.war/download > /root/DVN-web_v3_3.war',
    onlyif  => "/bin/touch /root/DVN-web_v3_3.war && /usr/bin/test `/usr/bin/md5sum /root/DVN-web_v3_3.war | cut -d' ' -f1` != '42458c9cdad269119d670f6591dae2c5'",
    timeout => 0,
  }

}
