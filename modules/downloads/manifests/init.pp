class downloads {

  exec { "download_dvn_zip":
    command => '/usr/bin/wget -O - http://sourceforge.net/projects/dvn/files/dvn/3.2/dvninstall_v3_2.zip/download > /root/dvninstall_v3_2.zip',
    onlyif  => "/bin/touch /root/dvninstall_v3_2.zip && /usr/bin/test `/usr/bin/md5sum /root/dvninstall_v3_2.zip | cut -d' ' -f1` != '917881752ada86bb15a0136b55cddd2a'",
    timeout => 0,
  }

  exec { "download_dvn_war":
    command => '/usr/bin/wget -O - http://sourceforge.net/projects/dvn/files/dvn/3.2/DVN-web_v3_2.war/download > /root/DVN-web_v3_2.war',
    onlyif  => "/bin/touch /root/DVN-web_v3_2.war && /usr/bin/test `/usr/bin/md5sum /root/DVN-web_v3_2.war | cut -d' ' -f1` != '0062bd312e0b8963532876a44a1acdc6'",
    timeout => 0,
  }

}
