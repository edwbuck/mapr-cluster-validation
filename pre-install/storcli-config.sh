#!/bin/bash
# jbenninghoff 2013-Jan-06  vi: set ai et sw=3 tabstop=3:

[ $(id -u) -ne 0 ] && { echo This script must be run as root; exit 1; }

if type storcli >& /dev/null; then
   :
elif [ -x /opt/MegaRAID/storcli/storcli64 ]; then
   storcli() { /opt/MegaRAID/storcli/storcli64; }
else
   echo storcli command not found; exit 2
fi

storcli /c0 show all #Display all disk controller values
storcli /c0 /eall /sall show | awk '$3 == "UGood"{print $1}'; exit 

#Modify existing virtual drive 1 configuration (example)
#storcli /c0 /v1 set wrcache=wb rdcache=ra iopolicy=cached pdcache=off strip=1024 #strip size probably cannot be changed

#Loop over all UGood drives and create RAID0 single disk virtual drive (vd)
#storcli /c0 /eall /sall show | awk '$3 == "UGood"{print $1}' | xargs -i sudo storcli /c0 add vd drives={} type=r0 strip=1024 ra wb cached pdcache=off

#Assuming drive 17:7 is UGood.  1024 strip needs recent LSI/Avago controller and 7.x RHEL Linux kernel
#sudo storcli /c0 add vd drives=17:7 type=r0 strip=1024 ra wb cached pdcache=off

# Download 45MB zip file (July 2016):
# https://docs.broadcom.com/docs/1.20.15_StorCLI

# Use smartctl to examine MegaRAID virtual drives:
# smartctl -a -d megaraid,0 /dev/sdd
# Test unmount drives for bad spots and other problems:
# smartctl -d megaraid,0 -t short /dev/sdd
