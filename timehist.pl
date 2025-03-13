#!/usr/bin/perl  # SHEBANG!!!

# this perl script takes a tcpdump log file and can either count teh frequency of IP addresses in a given time frame
# or calculate the average packet size for each IP address
# -c is for the frequency
# -s is for the average packet size
# -n is for the number of hours to analyze

use strict;
use warnings;
use Getopt::Long;

my $flag = ''; # flag getter
my $time = 0;  # gets time (hours)
my %count;     # hash for frequency
my %size;      # hash for average packet size
my $first_hour; # stores the first hour of the file

GetOptions(
	"c" => sub { $flag = 'c' },
	"s" => sub { $flag = 's' },
	"n=i" => \$time
) or die "Usage: needs [-c || -s] [-n # of hours]\n";

die "Usage: needs [-c || -s] [-n # of hours]\n" unless $flag;
if ($time eq 0) {
	die "Usage: cannot output data of 0 hours\n";
}

# git file
my $file = shift @ARGV;
open(FILE, "<", $file) or die "undetected file!\n";
my @lines = <FILE>;
close(FILE);

# for frequency using histogram
if ($flag eq 'c') {
	foreach (@lines) {
		if(/(^[^:]+).*(IP6? [^ >]+)/) {
			# $1 is the hour, $2 is the IP address
			$first_hour //= $1;	# stores the first hour of the file, NEVER changes afterwards.
			my $last_hour = $first_hour + $time;	# calculates the last hour from the given amount of hours the user entered
			if ($1 <= $last_hour) {
				$count{$2}++;	#add the IP into the histogram hash	
			}
		}
	}

	my @sorted_IPs = sort { $count{$a} <=> $count{$b} } keys %count;	# sorts the IPs by count (least to greatest)
	
	foreach my $IP (@sorted_IPs) {
		my $occurrences = $count{$IP};
		my $bar = '#' x $occurrences;
		print "$IP: $bar\n";
	}
}
elsif ($flag eq 's') {
	foreach(@lines) {
		if (/(^[^:]+).*(IP6? [^ >]+).* (length ([0-9]+))/) {	# regex matches 'IP ... length x'
			# $2 = the IP, $4 is the packet size
			$first_hour //= $1;	# stores the first hour of the file, NEVER changes afterwards.
			my $last_hour = $first_hour + $time;	# calculates the last hour from the given amount of hours the user enteered

			if ($1 <= $last_hour) { # if $1 hour is less than or equal to the last hour
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
		}
		elsif (/(^[^:]+).*(IP6? [^ >]+).* \(([0-9]+)\)/) {	# regex matches 'IP ... (x)'
			# $2 = the IP, $3 is the packet size
			# same idea aforementioned
			$first_hour //= $1;
			my $last_hour = $first_hour + $time;

			if ($1 <= $last_hour) {
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
	}
	print "Average packet size for each port:\n";
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

# end script
