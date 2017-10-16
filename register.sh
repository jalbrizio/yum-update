#
# register a RHEL5 or 6 client to the RHN Satellite server in the traditional manner
#
# this will overwrite the existing /etc/sysconfig/rhn/up2date, so...
cp -p /etc/sysconfig/rhn/up2date /etc/sysconfig/rhn/up2date-last$$
yourspacewalkserver=yourserver.com
yourspacewalkserver2=yourserver2.com
youroldsateliteserver=youroldserver.com
#
# REQUIRED: install the satellite SSL cert directly from the Satellite server...
rpm -ivh http://$yourspacewalkserver/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
rpm -ivh http://$yourspacewalkserver/pub/spacewalk-client-repo-2.2-1.el6.noarch.rpm
rpm -e rhn-org-trusted-ssl-cert
rpm -ivh http://$yourspacewalkserver2/pub/rhn-org-trusted-ssl-cert-1.0-1.noarch.rpm
#wget http://ncc-1701-sw/pub/RPM-GPG-KEY-MariaDB -O /etc/pki/rpm-gpg/RPM-GPG-KEY-MariaDB
#rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-MariaDB
rpm --import http://$yourspacewalkserver/pub/RPM-GPG-KEY-MariaDB
rpm --import http://$yourspacewalkserver/pub/RPM-GPG-KEY-EPEL-6
rpm --import http://$yourspacewalkserver/pub/RPM-GPG-KEY-mccdrpm
rpm --import http://$yourspacewalkserver/pub/RPM-GPG-KEY-percona

# edit the Red Hat target in /etc/sysconfig/rhn/up2date to point to
# the Satellite URL, then run  rhn_register  as usual.
sed -i 's/https:\/\/xmlrpc.rhn.redhat.com/https:\/\/$youroldsateliteserver/' /etc/sysconfig/rhn/up2date
sed -i 's/https:\/\/$youroldsateliteserver/https:\/\/$yourspacewalkserver2/' /etc/sysconfig/rhn/up2date
sed -i 's/RHNS-CA-CERT/RHN-ORG-TRUSTED-SSL-CERT/' /etc/sysconfig/rhn/up2date

# clean any existing yum configuration information...
yum clean all

# register the client using rhn_register and a userid and passwd...
rhn_register

# all done - run  yum update  whenever ready...
