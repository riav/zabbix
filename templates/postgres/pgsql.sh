#! /bin/bash
#
# Name: pgsql
#
# Checks Postgres activity.
#
# Author: Rafael Igor (rafael.igor@gmail.com)
# http://www.hjort.co/2009/12/postgresql-monitoring-on-zabbix.html
#-------------------------------------
# CREATE USER zabbix WITH PASSWORD '123@zabbix'; GRANT SELECT ON pg_stat_activity to zabbix; GRANT SELECT ON pg_stat_activity to zabbix; GRANT SELECT ON pg_database to zabbix; GRANT SELECT ON pg_authid to zabbix; GRANT SELECT ON pg_stat_bgwriter to zabbix; GRANT SELECT ON pg_locks to zabbix; GRANT SELECT ON pg_stat_database to zabbix;
# vi {HOME_ZABBIX}/.pgpass
# hostname:port:database:username:password
# hostname:5432:*:zabbix:123@zabbix
# chmod 0600 ~/.pgpass
#-------------------------------------
# Habilit this session in zabbix_agentd.conf
# Create a file in /etc/zabbix/zabbix_agentd.d/userparameter_postgres.conf and add the following content:
# UserParameter=pgsql[*],/etc/zabbix/scripts/pgsql.sh "$1" "$2" "$3"
# ------------------------------------
#
# Version: 1.1
#

agentversion="1.1"
rval=0
PGUSER="zabbix"

function usage()
{
    echo "pgsql  version: $agentversion"
    echo "usage:"
    echo "    $0 hostname summary                  -- Overview of existing databases in the instance."
    echo "    $0 hostname totalsize                -- Total size (sum) of databases (in bytes)."
    echo "    $0 hostname processes                -- Total number of server processes that are active."
    echo "    $0 hostname db.connections dbname    -- Total number of active connections in the single database."
    echo "    $0 hostname db.size dbname           -- Total size on  database (in bytes)."
    echo "    $0 hostname db.cache dbname          -- Cache hit ratio (in percentage) on database."
    echo "    $0 hostname db.success dbname        -- Percentage of successful transactions."
    echo "    $0 hostname db.commited dbname       -- Total number of commited transactions on database."
    echo "    $0 hostname db.rollback dbname       -- Total number of rolled back transactions on database."
    echo "    $0 hostname version                  -- Version of PostgreSQL Server."
    echo "    $0 hostname agentversion             -- Version of this agent."
    echo "    $0 hostname db.discovery             -- Discovery postgres databases."
}

########
# Main #
########

if [ $# -lt 2 ];then
    #Missied Parameter
    usage
    exit 0
fi

PGHOST=$1
CASE_VALUE=$2
DBNAME=$3

case $CASE_VALUE in
'summary')
    psql -h $PGHOST -U $PGUSER -d postgres -w -c "select a.datname, pg_size_pretty(pg_database_size(a.datid)) as size, cast(blks_hit/(blks_read+blks_hit+0.000001)*100.0 as numeric(5,2)) as cache, cast(xact_commit/(xact_rollback+xact_commit+0.000001)*100.0 as numeric(5,2)) as success from pg_stat_database a order by a.datname"
    rval=$?
;;
'totalsize')
    psql -h $PGHOST -U $PGUSER -d postgres -Atc "select sum(pg_database_size(datid)) as total_size from pg_stat_database"
    rval=$?
;;
'processes')
    psql -h $PGHOST -U $PGUSER -d postgres -Atc "select sum(numbackends) from pg_stat_database"
    rval=$?
;;
'db.size')
    if [ $# -ne 3 ];then
       #Missied Parameter
       usage
    else
       psql -h $PGHOST -U $PGUSER -d postgres -Atc "select pg_database_size('$DBNAME') as size"
       rval=$?
    fi
;;
'db.connections'|'db.cache'|'db.success'|'db.commited'|'db.rollback')
    if [ $# -ne 3 ];then
       #Missied Parameter
       usage
    else
       SQL=""
       case $CASE_VALUE in
       'db.connections') SQL="select numbackends";;
       'db.cache') SQL="select cast(blks_hit/(blks_read+blks_hit+0.000001)*100.0 as numeric(5,2)) as cache";;
       'db.success') SQL="select cast(xact_commit/(xact_rollback+xact_commit+0.000001)*100.0 as numeric(5,2)) as success";;
       'db.commited') SQL="select xact_commit";;
       'db.rollback') SQL="select xact_rollback";;
       esac
       if [ "$SQL" != "" ]; then
           psql -h $PGHOST -U $PGUSER -d postgres -Atc "$SQL from pg_stat_database where datname = '$DBNAME'"
           rval=$?
       else
       usage
       fi
    fi
;;
'version')
    psql -h $PGHOST -U $PGUSER -d postgres -Atc 'select version()' | awk '{print $2}'
    rval=$?
;;
'agentversion')
    echo "$agentversion"
    exit $rval
;;
'db.discovery')
    BEGIN="{\"data\":["
    END="]}"
    LIST=""
    PGDBLIST=$(psql -h $PGHOST -U $PGUSER -d postgres -w -Atc "select a.datname from pg_stat_database a where a.datname not in ('postgres') and a.datname not like 'template%' order by a.datname")
    rval=$?
    for PGDB in $PGDBLIST; do
       if [ "$LIST" != "" ]; then
          LIST=$LIST",{\"{#PGDBNAME}\":\""$PGDB"\"}"
       else
          LIST=$LIST"{\"{#PGDBNAME}\":\""$PGDB"\"}"
       fi
    done
    echo $BEGIN$LIST$END
;;
*)
    usage
    exit $rval
;;
esac

if [ "$rval" -ne 0 ]; then
      echo "ZBX_NOTSUPPORTED"
fi

exit $rval

#
# end pgsql