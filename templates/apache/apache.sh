#! /bin/bash
#
# Name: apache
#
# Checks Apache activity.
#
# Author: Alejandro Michavila
# Modified for Scoreboard Values: Murat Koc, murat@profelis.com.tr
# Modified for using also as external script: Murat Koc, murat@profelis.com.tr
# Modified for outputting usage or ZBX_NOTSUPPORTED: Alejandro Michavila
# Modified for Rafael Igor: rafael.igor@gmail.com
# Habilit this session in Apache
# ------------------------------------
# ExtendedStatus On
#
#<Location /server-status>
#    SetHandler server-status
#    Order deny,allow
#    Deny from all
#    Allow from IP_OF_ZABBIX
#</Location>
#
# Habilit this session in zabbix_agentd.conf
# UserParameter=apache[*],/etc/zabbix/scripts/apache.sh "$1" "$2"
# ------------------------------------
#
# Version: 1.4
#

apachever="1.4"
rval=0

function usage()
{
    echo "apache version: $apachever"
    echo "usage:"
    echo "    $0 TotalAccesses                   -- Check total accesses."
    echo "    $0 TotalKBytes                     -- Check total KBytes."
    echo "    $0 CPULoad                         -- Check CPU load."
    echo "    $0 Uptime                          -- Check uptime."
    echo "    $0 ReqPerSec                       -- Check requests per second."
    echo "    $0 BytesPerSec                     -- Check Bytes per second."
    echo "    $0 BytesPerReq                     -- Check Bytes per request."
    echo "    $0 BusyWorkers                     -- Check busy workers."
    echo "    $0 IdleWorkers                     -- Check idle workers."
    echo "    $0 WaitingForConnection            -- Check Waiting for Connection processess."
    echo "    $0 StartingUp                      -- Check Starting Up processess."
    echo "    $0 ReadingRequest                  -- Check Reading Request processess."
    echo "    $0 SendingReply                    -- Check Sending Reply processess."
    echo "    $0 KeepAlive                       -- Check KeepAlive Processess."
    echo "    $0 DNSLookup                       -- Check DNSLookup Processess."
    echo "    $0 ClosingConnection               -- Check Closing Connection Processess."
    echo "    $0 Logging                         -- Check Logging Processess."
    echo "    $0 GracefullyFinishing             -- Check Gracefully Finishing Processess."
    echo "    $0 IdleCleanupOfWorker             -- Check Idle Cleanup of Worker Processess."
    echo "    $0 OpenSlotWithNoCurrentProcess    -- Check Open Slots with No Current Process."
    echo "    $0 Version                         -- Version of Apache Server."
    echo "    $0 ScriptVersion                   -- Version of this script."
}

########
# Main #
########

if [[ $# ==  1 ]];then
    #Agent Mode
    VAR=$(wget --quiet -O - http://localhost/server-status?auto)
    CASE_VALUE=$1
elif [[ $# == 2 ]];then
    #External Script Mode
    VAR=$(wget --quiet -O - http://$1/server-status?auto)
    CASE_VALUE=$2
else
    #No Parameter
    usage
    exit 0
fi

if [[ -z $VAR ]]; then
    echo "ZBX_NOTSUPPORTED"
    exit 1
fi

case $CASE_VALUE in
'TotalAccesses')
    echo "$VAR"|grep "Total Accesses:"|awk '{print $3}'
    rval=$?;;
'TotalKBytes')
    echo "$VAR"|grep "Total kBytes:"|awk '{print $3}'
    rval=$?;;
'CPULoad')
    CPULOADFULL=$(echo "$VAR"|grep "CPULoad:"|awk '{print $2}')
    CPULOADINT=$(echo $CPULOADFULL | awk -F"." '{print $1}')
    if [ "x$CPULOADINT" == "x" ]; then
    echo "0"$CPULOADFULL
    else
    echo $CPULOADFULL
    fi

    rval=$?;;
'Uptime')
    echo "$VAR"|grep "Uptime:"|awk '{print $2}'
    rval=$?;;
'ReqPerSec')
    echo "$VAR"|grep "ReqPerSec:"|awk '{print $2}'
    rval=$?;;
'BytesPerSec')
    echo "$VAR"|grep "BytesPerSec:"|awk '{print $2}'
    rval=$?;;
'BytesPerReq')
    echo "$VAR"|grep "BytesPerReq:"|awk '{print $2}'
    rval=$?;;
'BusyWorkers')
    echo "$VAR"|grep "BusyWorkers:"|awk '{print $2}'
    rval=$?;;
'IdleWorkers')
    echo "$VAR"|grep "IdleWorkers:"|awk '{print $2}'
    rval=$?;;
'WaitingForConnection')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "_" } ; { print NF-1 }'
    rval=$?;;
'StartingUp')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "S" } ; { print NF-1 }'
    rval=$?;;
'ReadingRequest')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "R" } ; { print NF-1 }'
    rval=$?;;
'SendingReply')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "W" } ; { print NF-1 }'
    rval=$?;;
'KeepAlive')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "K" } ; { print NF-1 }'
    rval=$?;;
'DNSLookup')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "D" } ; { print NF-1 }'
    rval=$?;;
'ClosingConnection')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "C" } ; { print NF-1 }'
    rval=$?;;
'Logging')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "L" } ; { print NF-1 }'
    rval=$?;;
'GracefullyFinishing')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "G" } ; { print NF-1 }'
    rval=$?;;
'IdleCleanupOfWorker')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "I" } ; { print NF-1 }'
    rval=$?;;
'OpenSlotWithNoCurrentProcess')
    echo "$VAR"|grep "Scoreboard:"| awk '{print $2}'| awk 'BEGIN { FS = "." } ; { print NF-1 }'
    rval=$?;;
'Version')
    httpd -v | grep Apache | awk '{print $3}' | awk -F"/" '{print $2}'
    exit $rval;;
'ScriptVersion')
    echo "$apachever"
    exit $rval;;
*)
    usage
    exit $rval;;
esac

if [ "$rval" -ne 0 ]; then
      echo "ZBX_NOTSUPPORTED"
fi

exit $rval

#
# end apache