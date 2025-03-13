#!/usr/bin/perl

# this perl script takes a tcpdump log file and can either generate a histogram of ports
# or calculate the average packet size for each port
# -c is for the histogram
# -s is for the average packet size

use strict;
use warnings;
use Getopt::Long;

my $flag = ''; # flag for histogram or average packet size

my %count; # hash for histogram
my %size; # hash for average packet size

GetOptions(
	 "c" => sub {$flag = 'c'},
     "s" => sub {$flag = 's'}
) or die "please specify {-c || -s}\n";

# get file
my $file = shift @ARGV;
open(FILE, "<", $file) or die "undetected file!\n";
my @lines = <FILE>;
close(FILE);

# histogram of ports
if ($flag eq 'c') {
	foreach(@lines) {
		if (/(IP6? [^ >]+\.(.*?) >)/) {	# regex matches: 'IP ... port'
			# $2 is the port
			$count{$2}++;	
		}
	}

	my @sorted_ports = sort { $count{$a} <=> $count{$b} } keys %count;	# sorts the ports by count (least to greatest)

	# prints the histogram
	foreach my $port (@sorted_ports) {
		my $occurrences = $count{$port};
		my $bar = '#' x $occurrences;
		print "$port: $bar\n";
	}
}

# average size of ports
elsif ($flag eq 's') {
	foreach(@lines) {
		if (/(IP6? [^ >]+\.(.*?) >).* (length ([0-9]+))/) {	# regex matches: 'IP ... length x'
			# $2 = the port, $4 is the packet size
			if (exists $size{$2}) {	# if already found
				$size{$2}{total_size} += $4; # adds the size to the total size
				$size{$2}{packet_count}++; # increments the packet count
			} else { # if does not exist in hash yet
				# initializes the total size and packet count
				$size{$2} = {
					total_size => $4,
					packet_count => 1
				};
			}
		}
		elsif (/(IP6? [^ >]+\.(.*?) >).* \(([0-9]+)\)/) {	# regex matches 'IP ... (x)'
			# $2 = the port, $3 is the packet size
			# same idea aforementioned
			if (exists $size{$2}) {
				$size{$2}{total_size} += $3;
				$size{$2}{packet_count}++;
			} else {
				$size{$2} = {
					total_size => $3,
					packet_count => 1
				};
			}
		}		
	}
	print "Average packet size for each port:\n";
	# prints the average packet size for every port
	foreach my $port (sort keys %size) {
		my $total_size = $size{$port}{total_size};
		my $packet_count = $size{$port}{packet_count};

		if($packet_count > 0) {
			my $avg = $total_size / $packet_count; # calculates average
			printf "%s: %.1f\n", $port, $avg;
		} else {
			printf "%s: 0\n", $port;
		}
	}
}

#end script
