#!/usr/bin/perl

# this perl script takes a tcpdump log file and can either generate a histogram of IP addresses
# or calculate the average packet size for each IP address
# -c is for the histogram
# -s is for the average packet size

use strict;
use warnings;
use Getopt::Long;

my $flag = '';

GetOptions(
	"c" => sub { $flag = 'c' },
	"s" => sub { $flag = 's' },
) or die "Usage: needs [-c || -s]\n";

die "Usage: needs [-c || -s]\n" unless $flag;

# get file
my $file = shift @ARGV;
open(FILE, "<", $file) or die "undetected file!\n";
my @lines = <FILE>;
close(FILE);

my %count; # hash for histogram
my %size; # hash for average packet size

# if flag is c, generate histogram
if ($flag eq 'c') {
	foreach (@lines) {
		if(/(IP6? [^ >]+)/) {
			# $1 is the IP
			$count{$1}++;	# increments the count of the IP	
		}
	}

	my @sorted_IPs = sort { $count{$a} <=> $count{$b} } keys %count;	# sorts the IPs by count (least to greatest)	
	
	# prints the histogram
	foreach my $IP (@sorted_IPs) {
		my $occurrences = $count{$IP};
		my $bar = '#' x $occurrences;
		print "$IP: $bar\n";
	}
}
# if flag is s, calculate average packet size
elsif ($flag eq 's') {
	foreach(@lines) {
		if (/(IP6? [^ >]+).* (length ([0-9]+))/) {	# regex matches: 'IP ... length x'
			# $1 = the IP, $3 is the packet size
			if (exists $size{$1}) {	# if already found
				$size{$1}{total_size} += $3; # adds the size to the total size
				$size{$1}{packet_count}++; # increments the packet count
			} else { # if does not exist in hash
				# initializes the total size and packet count
				$size{$1} = {
					total_size => $3,
					packet_count => 1
				};
			}
		}
		elsif (/(IP6? [^ >]+).* \(([0-9]+)\)/) {	# regex matches: 'IP ... (x)'
			# $1 = the IP, $2 is the packet size
			# same idea aforementioned
			if (exists $size{$1}) {
				$size{$1}{total_size} += $2;
				$size{$1}{packet_count}++;
			} else {
				$size{$1} = {
					total_size => $2,
					packet_count => 1
				};
			}
		}
	}
	print "Average packet size for each port:\n";
	# for every distinct IP, calculates the average packet size
	foreach my $port (sort keys %size) {
		my $total_size = $size{$port}{total_size}; 
		my $packet_count = $size{$port}{packet_count};

		if($packet_count > 0) {
			my $avg = $total_size / $packet_count; # calculates the average
			printf "%s: %.1f\n", $port, $avg;
		} else {
			printf "%s: 0\n", $port;
		}
	}
}

# end script
