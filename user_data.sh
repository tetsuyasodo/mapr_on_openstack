#!/bin/bash

# You have to know all the fixed-ips of the nodes in advance.
cat <<EOF >>/etc/hosts
192.168.0.90 mapr-1
192.168.0.91 mapr-2
192.168.0.92 mapr-3
EOF

HOSTNAME=`curl -s http://169.254.169.254/latest/meta-data/hostname | sed 's/\..*//'`
hostname $HOSTNAME

cat <<EOF >>/etc/sysconfig/network
HOSTNAME=$HOSTNAME
EOF

# MapR's storage pool is created from the nodes' ephemeral disk (/dev/vdb) for now.
umount /mnt
echo '/dev/vdb' > /root/disks.txt

setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux

# allow mapr user can ssh-login
sed -i 's/^PasswordAuthentication no.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
service sshd restart

service iptables stop
service ip6tables stop
chkconfig iptables off
chkconfig ip6tables off

cat <<\EOF >>/etc/profile
export LANG="en_US.UTF-8"
export JAVA_HOME=/usr/lib/jvm/java
export PATH=$PATH:$JAVA_HOME/bin
EOF
. /etc/profile

cat <<EOF >>/etc/sysctl.conf
net.ipv4.tcp_retries2 = 5
EOF
sysctl -e -p

yum -y install java-1.7.0-openjdk java-1.7.0-openjdk-devel nc syslinux mtools sdparm glibc-common redhat-lsb rpm-build ntp

groupadd -g 500 mapr
useradd -u 500 -g 500 mapr
echo mapr:mapr | chpasswd
su - mapr -c "ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa"

yum install -y expect
HOSTS="mapr-1 mapr-2 mapr-3"
### memo: for single deployment
#HOSTS="mapr-1"
###

LOOPS=20
SLEEP=10
i=0
for host in $HOSTS
do
    until echo '' | nc $host 22 >/dev/null 2>&1; do
        i=$((i + 1))
        if [[ $i -gt $LOOPS ]]; then
            echo "instance not booting up. Exiting..."
            exit 1
        fi
        echo -n '.'
        sleep $SLEEP
    done
done

cat <<\EOF >/home/mapr/ssh-copy-id.expect
#!/usr/bin/env expect
set timeout 60
set host [lindex $argv 0]
set user [lindex $argv 1]
set password [lindex $argv 2]
spawn ssh-copy-id $user@$host
expect  "yes/no"    { send "yes\n"; } 
expect  "password:" { send "$password\n"; exp_continue }
EOF
chown mapr:mapr /home/mapr/ssh-copy-id.expect
chmod 755 /home/mapr/ssh-copy-id.expect
for host in $HOSTS; do su - mapr -c "./ssh-copy-id.expect $host mapr mapr"; done

cat <<EOF >/etc/yum.repos.d/maprtech.repo
[maprtech]
name=MapR Technologies
baseurl=http://package.mapr.com/releases/v3.1.1/redhat/
enabled=1
gpgcheck=0
protect=1
 
[maprecosystem]
name=MapR Technologies
baseurl=http://package.mapr.com/releases/ecosystem/redhat
enabled=1
gpgcheck=0
protect=1
EOF

rpm --import http://package.mapr.com/releases/pub/gnugpg.key

if [[ `hostname` == "mapr-1" ]]; then
yum -y install mapr-cldb mapr-jobtracker mapr-webserver mapr-zookeeper mapr-tasktracker mapr-fileserver mapr-nfs
elif [[ `hostname` == "mapr-2" || `hostname` == "mapr-3" ]]; then
yum -y install mapr-tasktracker mapr-fileserver mapr-zookeeper
fi
service rpcbind restart

### You can change any parameters here. (ex. cluster name etc.) 
/opt/mapr/server/configure.sh -on-prompt-cont y -N cluster01 -C mapr-1 -Z mapr-1,mapr-2,mapr-3 -F /root/disks.txt
service mapr-zookeeper start
service mapr-warden start
