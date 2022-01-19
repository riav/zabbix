#!/usr/bin/perl -w
#
# script to send jabber message to Google Talk Instant Messaging
#   using XMPP protocol and SASL PLAIN authentication.
#
# author: Thus0 <Thus0@free.fr>
# Copyright (c) 2005, Thus0 <thus0@free.fr>. All rights reserved.
#
# released under the terms of the GNU General Public License v2
#IO ::Socket ::SSL (>=0.81 ?)
#XML ::Stream
#Net ::XMPP
#Authen ::SASL
#(perl-XML-Stream.noarch perl-Net-XMPP.noarch)
#Modificado por Rafael Igor/rafael.igor@gmail.com
#https://www.zabbix.com/forum/showthread.php?t=11649
#http://www.pervasive-network.org/SPIP/Google-Talk-with-perl-bis
#Versao: 1.2.1

use strict;
use warnings;
use Net::XMPP;
#
my $time = substr((localtime()),4);
#
#
use IO::Socket::SSL;
{
    no warnings 'redefine';
    my $old_connect_SSL = \&IO::Socket::SSL::connect_SSL;
    *IO::Socket::SSL::connect_SSL = sub {
        my $sock = $_[0];
        ${*$sock}{_SSL_arguments}{SSL_cipher_list} = 'RC4-MD5';
        goto $old_connect_SSL;
    };
}

## Configuration


my $username = 'username';
my $password = 'password';

my $to = $ARGV[0];
die "$0 \"Username Recipient\" $!" unless defined $ARGV[0];
my $body = $time . "\n" . $ARGV[1] . "\n" . $ARGV[2];
#my $body = $ARGV[1] . "\n" . $ARGV[2];
die "$0 \"Username Recipient\" \"Msg Title\" \"Msg Body\" $!" unless defined $ARGV[1] or defined $ARGV[2];

my $resource = 'ZBX';

## End of configuration
#------------------------------------

# Google Talk & Jabber parameters :
my $hostname = 'talk.google.com';
my $port = 5222;
my $componentname = 'gmail.com';
my $dstdomain = 'dstdomain.com.br';
my $connectiontype = 'tcpip';
my $tls = 1;
#------------------------------------

my $Connection = new Net::XMPP::Client();

# Connect to talk.google.com
my $status = $Connection->Connect(hostname => $hostname, port => $port, componentname => $componentname, connectiontype => $connectiontype, tls => $tls);
die "ERROR: XMPP connection failed. ($!)\n" unless defined $status;

# Change hostname
my $sid = $Connection->{SESSION}->{id};
$Connection->{STREAM}->{SIDS}->{$sid}->{hostname} = $componentname;

# Authenticate
my @result = $Connection->AuthSend(username => $username, password => $password, resource => $resource);
die "ERROR: Authorization failed", defined $result[1] ? $result[1] : '', " $!" unless defined $result[0] and $result[0] eq 'ok';

# Send message
#$Connection->MessageSend(to => "$to\@$dstdomain", type => 'chat', resource => $resource, body => $body);
$Connection->MessageSend(to => "$to", type => 'chat', resource => $resource, body => $body);

#Close
$Connection->Disconnect();
