#!/bin/bash
#
# Script for deploying zabbix agent to Symantec NetBackup 5xxx appliances
# with minimal third party requirements, to be called as described below:
#   wget -O - http://${MASTER}/deploy/deploy_zabbix_to_appliance.sh | sh -
#
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

MASTER=XXX.IP

pkill -9 zabbix_agentd

mkdir /tmp/zabbixtmp
cd /tmp/zabbixtmp

TGZURL="http://${MASTER}/deploy/downloads/zabbix_agents_2.0.6.linux2_6_23.i386.tar.gz"

wget -O - $TGZURL | tar xzvf -

cp sbin/zabbix_agentd /usr/local/bin/

useradd zabbix
groupadd zabbix
mkdir /var/log/zabbix
chown -R zabbix:zabbix /var/log/zabbix
mkdir /etc/zabbix
chown -R zabbix:zabbix /etc/zabbix

wget -O /usr/local/bin/zabbix_discoverdisks.py http://${MASTER}/deploy/zabbix_discoverdisks.py
chown zabbix:zabbix /usr/local/bin/zabbix_discoverdisks.py
chmod +x /usr/local/bin/zabbix_discoverdisks.py


# Setup zabbix_agent.conf
cat > /etc/zabbix/zabbix_agent.conf <<EOF
Server=${MASTER}
### DISK I/O###
UserParameter=custom.vfs.dev.disks,/usr/local/bin/zabbix_discoverdisks.py
UserParameter=custom.vfs.dev.read.ops[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$4}'
UserParameter=custom.vfs.dev.read.ms[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$7}'
UserParameter=custom.vfs.dev.write.ops[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$8}'
UserParameter=custom.vfs.dev.write.ms[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$11}'
UserParameter=custom.vfs.dev.io.active[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$12}'
UserParameter=custom.vfs.dev.io.ms[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$\$13}'
#UserParameter=custom.vfs.dev.read.sectors[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$6}'
#UserParameter=custom.vfs.dev.write.sectors[*],cat /proc/diskstats | egrep \$1 | head -1 | awk '{print \$10}'
### DISK I/O###
EOF

# Setup daily redeploy of self from cron
cat > /etc/cron.daily/zabbixagent_redeploy.sh <<EOF
#!/bin/bash
wget -O - http://${MASTER}/deploy/deploy_zabbix_to_appliance.sh | sh -
EOF
chmod 755 /etc/cron.daily/zabbixagent_redeploy.sh

/usr/local/bin/zabbix_agentd -c /etc/zabbix/zabbix_agent.conf
if ! grep -q "zabbix_agentd" /etc/rc.d/rc.local; then
    echo "/usr/local/bin/zabbix_agentd -c /etc/zabbix/zabbix_agent.conf" >> /etc/rc.d/rc.local
fi

if test -f /etc/puredisk/custom_iptables_rules; then
    if ! grep -q "10050" /etc/puredisk/custom_iptables_rules; then
        echo -e "tcp 0.0.0.0/0 10050" >> /etc/puredisk/custom_iptables_rules
        /etc/init.d/pdiptables change
    fi
fi
