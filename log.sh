#!/bin/bash 
grep -w "SRC" /var/log/messages | awk '{print $10}' | cut -d= -f 2 | sort | uniq >> /tmp/badips.tmp

for x in `cat /tmp/badips.tmp` ; do echo $x; /usr/sbin/ipset add voipblip $x 2>/dev/null ;done
/usr/sbin/ipset list | wc -l 