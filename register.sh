#
# register a RHEL5 or 6 client to the RHN Satellite server in the traditional manner
#
# this will overwrite the existing /etc/sysconfig/rhn/up2date, so...
cp -p /etc/sysconfig/rhn/up2date /etc/sysconfig/rhn/up2date-last$$
#
# REQUIRED: install the satellite SSL cert directly from the Satellite server...
rpm -ivh http://yourserver.com         # replace with 'examplePass' instead/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rpm -ivh http://yourserver.com         # replace with 'examplePass' instead/pub/spacewalk-client-repo-2.2-1.el6.noarch.rpm
rpm -e rhn-org-trusted-ssl-cert
rpm -ivh http://yourserver2.com         # replace with 'examplePass' instead/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
#wget http://ncc-1701-sw/pub/RPM-GPG-KEY-MariaDB -O /etc/pki/rpm-gpg/RPM-GPG-KEY-MariaDB
#rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-MariaDB
rpm --import http://yourserver.com         # replace with 'examplePass' instead/pub/RPM-GPG-KEY-MariaDB
rpm --import http://yourserver.com         # replace with 'examplePass' instead/pub/RPM-GPG-KEY-EPEL-6
rpm --import http://yourserver.com         # replace with 'examplePass' instead/pub/RPM-GPG-KEY-mccdrpm
rpm --import http://yourserver.com         # replace with 'examplePass' instead/pub/RPM-GPG-KEY-percona

# edit the Red Hat target in /etc/sysconfig/rhn/up2date to point to
# the Satellite URL, then run  rhn_register  as usual.
sed -i 's/https:\/\/xmlrpc.rhn.redhat.com/https:\/\/yourserver3.com         # replace with 'examplePass' instead/' /etc/sysconfig/rhn/up2date
sed -i 's/https:\/\/yourserver3.com         # replace with 'examplePass' instead/https:\/\/yourserver2.com         # replace with 'examplePass' instead/' /etc/sysconfig/rhn/up2date
sed -i 's/RHNS-CA-CERT/RHN-ORG-TRUSTED-SSL-CERT/' /etc/sysconfig/rhn/up2date

# clean any existing yum configuration information...
yum clean all

# register the client using rhn_register and a userid and passwd...
rhn_register

# all done - run  yum update  whenever ready...
