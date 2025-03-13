#!/usr/bin/perl

# this perl script analyzes tcpdump files to find IP packets exceeding specified length
#
# Options:
#   -t4        Filter IPv4 packets only
#   -t6        Filter IPv6 packets only
#   -l length  Show packets larger than specified length
#
# Output: Prints matching IP addresses and packet lengths

use strict;
use warnings;
use Getopt::Long;

my $IP_type = '';  # Packet type filter: 't4', 't6', or '' (both)
my $length = 0;    # Minimum packet length threshold
my $packets = 0;   # Counter for matching packets

GetOptions(
	"t4" => sub { $IP_type = 't4' },
	"t6" => sub { $IP_type = 't6' },
	"l=i" => \$length
) or die "Usage: needs [-t4|-t6] [-l length]\n";

# get file
my $file = shift @ARGV;
open(FILE, "<", $file) or die "undetected file!\n";
my @lines = <FILE>; # read file into array
close(FILE);

# for IP4 packets
if ($IP_type eq 't4') {
	foreach (@lines) {
		if(/(IP [^>]+).*(length ([0-9]+))/) {	# regex matches: 'IP ... length x'
			# if the length of the packet ($3) is greater than the specified length, print the IP ($1) and the length ($2)
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
		if(/(IP [^>]+).* (\(([0-9]+)\))/) {	# regex matches: 'IP ... (x)'
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
	}
}
# for IP6 packets
elsif ($IP_type eq 't6') {
	foreach (@lines) {
		if(/(IP6 [^>]+).*(length ([0-9]+))/) {	# same idea aforementioned
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
		if(/(IP6 [^>]+).* (\(([0-9]+)\))/) {	# same idea aforementioned
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
	}
}
# if no IP type is specified: for both IP4 and IP6 packets
elsif ($IP_type eq '') {
	foreach (@lines) {
		if(/(IP[^>]+).*(length ([0-9]+))/) {	# same idea aforementioned
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
		if(/(IP[^>]+).* (\(([0-9]+)\))/) {	# same idea aforementioned
			if ($3 > $length) {
				print "IP: $1\n\t $2\n";
				$packets++;
			}
		}
	}	
}

print "\nNumber of packets with greater length than $length: $packets\n";

# end script
