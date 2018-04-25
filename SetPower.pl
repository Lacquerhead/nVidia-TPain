#!/usr/bin/perl
use strict;
use Scalar::Util qw(looks_like_number);

my $MaxTemp = 75;
my $MinTemp = 60;
my $MaxPower = 170;
my $MinPower = 60;
my $PowerIncrement = 1;

my $MaxFan = 100;
my $MinFan = 60;
my $FanIncrement = 2;

my @StatsIn = `nvidia-smi --format=csv,nounits --query-gpu=index,power.draw,enforced.power.limit,temperature.gpu,fan.speed`;
my $date = time();
my $LogFile;

open(LOG,">/var/log/SetPower.log");
printf LOG "$date\n";
printf "$date\n";

foreach my $line (@StatsIn) 
	{
	chomp $line;
	my ($gpu,$pwr,$pwrlmt,$temp,$fanspeed) = split(/,\s+/,$line);

	printf("Examining GPU $gpu\n");
	if (looks_like_number($gpu)) 
		{
		my $output;
		# Adjustify power
		printf LOG ("GPU: $gpu\tPwr: $pwr\tPwr Lmt: $pwrlmt\tTemp: $temp\n");
		if (($temp >= $MaxTemp) && ($pwrlmt > $MinPower))
			{
			my $NewPwr = $pwrlmt - $PowerIncrement;
			printf "$date - Decreasing GPU $gpu Power Limit to $NewPwr\n";
			printf LOG "Decreasing GPU $gpu Power Limit to $NewPwr\n";
			$output = `nvidia-smi -i $gpu -pl $NewPwr`;
			printf LOG "$output\n";
			}
		printf("PowerLimit $pwrlmt $MaxPower - FannSpeed $fanspeed $MaxFan\n");
		if (($pwrlmt < $MaxPower) && ($fanspeed < $MaxFan))
			{
			my $NewPwr = $pwrlmt + $PowerIncrement;
			print "$date - Increasing GPU $gpu Power Limit to $NewPwr\n";
			print LOG "Increasing GPU $gpu Power Limit to $NewPwr\n";
			$output = `nvidia-smi -i $gpu -pl $NewPwr`;
			print LOG "$output\n";
			}


		# Set Fan Speeds
		printf "Temp: $temp\tFan: $fanspeed\tPwr: $pwr\n";
		if (($temp < $MinTemp) && ($fanspeed > $MinFan))
			{
			my $NewFan = $fanspeed - $FanIncrement;
			print "$date - Slowing Fan on GPU $gpu to $NewFan\n";
			print LOG "Slowing Fan on GPU $gpu to $NewFan\n";
			my $cmd = "nvidia-settings -a '[fan:$gpu]/GPUTargetFanSpeed=$NewFan'";
			$output = system($cmd);
			print LOG "$output\n";
			}
		if (($temp > $MinTemp) && ($fanspeed < $MaxFan))
			{
			my $NewFan = $fanspeed + $FanIncrement;
			print "$date - Temp rising, Increasing Fan on GPU $gpu to $NewFan\n";
			print LOG "$fanspeed : Temp rising, Increasing Fan on GPU $gpu to $NewFan\n";
			my $cmd = "nvidia-settings -a '[fan:$gpu]/GPUTargetFanSpeed=$NewFan'";
			$output = system($cmd);
			print LOG "$output\n";
			}	

		}
	}
