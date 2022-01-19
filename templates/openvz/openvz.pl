#!/usr/bin/perl
#
## Checks Postgres activity.
##
## Author: Rafael Igor (rafael.igor@gmail.com)
## Version: 1.1.0
#
##------------------------------------------------------------------------------------------------------
## Habilit this session in zabbix_agentd.conf
## Create a file in /etc/zabbix/zabbix_agent.d/userparameter_openvz.conf and add the following content:
## UserParameter=openvz[*],sudo /etc/zabbix/scripts/openvz.pl "$1" "$2"
##------------------------------------------------------------------------------------------------------
## visudo
## #Defaults    requiretty
## Cmnd_Alias ZBX_CMD = /etc/zabbix/scripts/openvz.pl
## zabbix  ALL=(ALL)       NOPASSWD: ZBX_CMD
##------------------------------------------------------------------------------------------------------

use strict;
use Switch;

my $num_args = $#ARGV;
#print "\n$num_args";

sub usage {
    print "Usage:\n";
    print "./openvz.pl discovery                     -- Discovers existing containers. \n";
    print "./openvz.pl total                         -- Total of containers. \n";
    print "./openvz.pl vz.memory.total veid          -- Total memory of container. \n";
    print "./openvz.pl vz.memory.free veid           -- Free memory of container. \n";
    print "./openvz.pl vz.memory.pfree veid          -- Free Percentual memory of container. \n";
    print "./openvz.pl vz.disk.total veid            -- Total disk space of container. \n";
    print "./openvz.pl vz.disk.used veid             -- Used disk space of container. \n";
    print "./openvz.pl vz.disk.pfree veid            -- Free Percentual disk space of container. \n";
    print "./openvz.pl vz.cpu.usage veid             -- Percentual CPU usage of container. \n";
    print "./openvz.pl vz.cpu.load1 veid             -- Load CPU averaged over 1m of container. \n";
    print "./openvz.pl vz.cpu.load5 veid             -- Load CPU averaged over 5m of container. \n";
    print "./openvz.pl vz.cpu.load15 veid            -- Load CPU averaged over 15m of container. \n";
    print "./openvz.pl vz.net.bps.in veid            -- Network traffic bytes IN. \n";
    print "./openvz.pl vz.net.bps.out veid           -- Network traffic bytes OUT. \n";
    print "./openvz.pl vz.net.pps.in veid            -- Network traffic packets IN. \n";
    print "./openvz.pl vz.net.pps.out veid           -- Network traffic packets OUT. \n";
    print "./openvz.pl vz.status veid                -- Status of container. \n";
}

# Rotina que lista as vps existentes
sub discovery_vz {
   my $first = 1;
   #my $vzresult = `sudo /usr/sbin/vzlist -a -o veid,hostname,status,laverage -H`;
   my $vzresult = `sudo /usr/sbin/vzlist -a -o veid,hostname -H`;
   my @lines = split /\n/, $vzresult;

   print "{\n";
   print "\t\"data\":[\n\n";

   foreach my $l (@lines) {
   #   if ($l =~ /^(\s*?)(\d+) (.*?)(\s+)(\S+)/){
      if ($l =~ /^(\s*?)(\d+)(\s*)(\S+)/){
      #print "$l\n";
   
         my $id = $2;
         my $hostname = $4;
         #my $status = $5;
         print ",\n" if not $first;
         $first = 0;

         print "\t{\n";
         print "\t\t\"{#VZID}\":\"$id\",\n";
         print "\t\t\"{#VZHOST}\":\"$hostname\"\n";
         #print "\t\t\"{#VZSTATUS}\":\"$status\"\n";
         print "\t}";
      }
   }
   print "\n\t]\n";
   print "}\n";
}

sub total_vz {
   my $totalvz = `sudo /usr/sbin/vzlist -a -H $_[0] | wc -l`;
   print "$totalvz";
}

# Memory
sub vz_memory {
   if (-e "/proc/bc/$_[0]/meminfo") {
      if ($_[1] eq "Pfree") {
         my $vz_mem = `/bin/echo "scale=2;\$(/bin/cat /proc/bc/$_[0]/meminfo | /bin/grep MemFree | /bin/awk '{print \$2}')*100/\$(/bin/cat /proc/bc/$_[0]/meminfo | /bin/grep MemTotal | /bin/awk '{print \$2}')"|/usr/bin/bc -l`;
         print "$vz_mem";
      }else{
         my $vz_mem = `/bin/cat /proc/bc/$_[0]/meminfo | /bin/grep $_[1] | /bin/awk '{print \$2}'`;
         print "$vz_mem";
      }
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}

# Disk
sub vz_disk {
   if (-e "/proc/bc/$_[0]/meminfo") {
      if ($_[1] eq "pfree"){
         #my $vz_disk = `sudo /usr/sbin/vzctl exec $_[0] /bin/df | /bin/grep \/dev\/ploop | /bin/awk '{print \$5}' | /bin/awk -F"%" '{print 100 - \$1}'`;
         my $vz_disk = `sudo /usr/sbin/vzlist -a -H -o veid,diskspace.s,diskspace | /bin/grep  " $_[0] " | /bin/awk '{print 100 - \$3*100/\$2}'`;
         print "$vz_disk";
      }else{
         #my $vz_disk = `sudo /usr/sbin/vzctl exec $_[0] /bin/df | /bin/grep \/dev\/ploop | /bin/awk '{print \$$_[1]}'`;
         my $vz_disk = `sudo /usr/sbin/vzlist -a -H -o veid,$_[1] | /bin/grep  " $_[0] " | /bin/awk '{print \$2}'`;
         print "$vz_disk";
      }
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}

# CPU
# http://juliano.info/en/Blog:Memory_Leak/Understanding_the_Linux_load_average
sub vz_cpu {
   if (-e "/proc/bc/$_[0]/meminfo") {
      #my $vz_cpu = `/usr/sbin/vzctl exec $_[0] /usr/bin/top -bn1 | /bin/grep "Cpu(s)" | /bin/awk '{print \$5}' | /bin/awk -F"%" '{print 100 - \$1}'`;
      my $vz_cpu = `sudo /usr/sbin/vzctl exec $_[0] /bin/cat /proc/stat | /bin/grep "cpu " | /bin/awk '{usage=(\$2+\$4)*100/(\$2+\$4+\$5)} END {print usage}'`;
      print "$vz_cpu";
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}
# CPU Load
sub vz_cpu_load {
   if (-e "/proc/bc/$_[0]/meminfo") {
      my $vz_cpu = `/usr/sbin/vzctl exec $_[0] /bin/cat /proc/loadavg | /bin/awk '{print \$$_[1]}'`;
      print "$vz_cpu";
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}

#Network Traffic
sub vz_network_traffic {
   if (-e "/proc/bc/$_[0]/meminfo") {
      my $vz_net = "ZBX_NOTSUPPORTED";
      switch($_[1]){
         case "bps.in" {
            $vz_net = `/usr/sbin/vzctl exec $_[0] "grep venet0 /proc/net/dev" | awk '{print \$2}'`;
         }
         case "bps.out" {
            $vz_net = `/usr/sbin/vzctl exec $_[0] "grep venet0 /proc/net/dev" | awk '{print \$10}'`;
         }
         case "pps.in" {
            $vz_net = `/usr/sbin/vzctl exec $_[0] "grep venet0 /proc/net/dev" | awk '{print \$3}'`;
         }
         case "pps.out" {
            $vz_net = `/usr/sbin/vzctl exec $_[0] "grep venet0 /proc/net/dev" | awk '{print \$11}'`;
         }
      }
      print $vz_net;
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}

#Status
sub vz_status {
   if (-e "/etc/vz/conf/$_[0].conf") {
      my $vz_status = `sudo /usr/sbin/vzlist $_[0] -H | /bin/awk '{print \$3}' | /bin/grep running | /usr/bin/wc -l`;
      print "$vz_status";
   }else{
      print "ZBX_NOTSUPPORTED\n";
   }
}

if ($num_args == -1) {
   usage();
}else{
   my $flag = $ARGV[0];
   my $veid = $ARGV[1];
   switch($flag){
      case "discovery"           { discovery_vz() }
      case "total"               { total_vz() }
      case "total.running"       { total_vz("| /bin/grep running") }
      case "vz.memory.total"     { vz_memory($veid,"MemTotal") }
      case "vz.memory.free"      { vz_memory($veid,"MemFree") }
      case "vz.memory.pfree"     { vz_memory($veid,"Pfree") }
      case "vz.disk.total"       { vz_disk($veid,"diskspace.s") }
      case "vz.disk.used"        { vz_disk($veid,"diskspace") }
      case "vz.disk.pfree"       { vz_disk($veid,"pfree") }
      case "vz.cpu.usage"        { vz_cpu($veid) }
      case "vz.cpu.load1"        { vz_cpu_load($veid,"1") }
      case "vz.cpu.load5"        { vz_cpu_load($veid,"2") }
      case "vz.cpu.load15"       { vz_cpu_load($veid,"3") }
      case "vz.net.bps.in"       { vz_network_traffic($veid,"bps.in") }
      case "vz.net.bps.out"      { vz_network_traffic($veid,"bps.out") }
      case "vz.net.pps.in"       { vz_network_traffic($veid,"pps.in") }
      case "vz.net.pps.out"      { vz_network_traffic($veid,"pps.out") }
      case "vz.status"           { vz_status($veid) }
      else                       { usage() }
   }
}
#
