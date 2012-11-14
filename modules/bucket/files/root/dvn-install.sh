#/bin/bash -x
mkdir /root/dvn-app && \
cd /root/dvn-app && \
svn co https://dvn.svn.sourceforge.net/svnroot/dvn/dvn-app/trunk@8507 && \
mkdir /root/dvn-app/trunk/src/DVN-web/dist && \
cp /root/DVN-web_v3_2.war /root/dvn-app/trunk/src/DVN-web/dist/DVN-web.war && \
cd /root/dvn-app/trunk/tools/installer/dvninstall && \
perl /root/dvn-vagrant-install.pl && \
/opt/glassfish/bin/asadmin start-domain domain1
