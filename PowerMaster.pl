#!/usr/bin/perl
use strict;

my $MaxTemp = 80;
my $MinTemp = 60;
my $PowerIncrement = 1;

my $MaxFan = 90;
my $MinFan = 25;
my $FanIncrement = 2;

#my @StatsIn = `nvidia-smi --format=csv,nounits,noheader --query-gpu=index,name,power.min_limit,power.max_limit,power.draw,enforced.power.limit,temperature.gpu,fan.speed`;
my @StatsIn = `ethos-smi -s`;
my $date = time();
my $LogFile;

open(LOG,">/var/log/SetPower.log");
printf LOG "$date\n";

printf "\n\n$date\n";

my $output;
my $MinPower = 80;
my $MaxPower;


foreach my $line (@StatsIn) 
	{
	chomp $line;
	my ($gpu,$epoch,$pciID,$gpuname,$bios,$pwrtune,$coreclock,$coreoffset,$defaultcore,$maxcore,$memclock,$memoffset,$defaultmem,$maxmem,$temp,$throttletemp,$shutdowntemp,$fanspeed,$fanrpm,$pwr,$pwrlmt,$defaultPwr) = split(/\|/,$line);
	printf "\n$line\n";
#	printf ("GPU $gpu [$pciID]: $gpuname, $bios\n");
#	printf ("DPM/Performance Level : $pwrtune\n");
#	printf ("Core Clock : $coreclock\n");
#	printf ("Core Clock Offset: $coreoffset\n");
#	printf ("Mem Clock : $memclock\n");
#	printf ("Temp : $temp\n");
#	printf ("Min Temp : $MinTemp\n");
#	printf ("Max Temp : $MaxTemp\n");
#	printf ("Fan : $fanspeed\n");	
	#printf("Examining GPU $gpu\n");
	# Adjustify power
		
	# Almost right	
	if ( $temp > (($MinTemp+$MaxTemp)/2) )
		{
		if  ($fanspeed < $MaxFan)
			{
			#my $NewFan = $fanspeed + ($FanIncrement*2);
			my $NewFan = $fanspeed + 5;
			print "\tTemp rising, Increasing Fan on GPU $gpu to $NewFan\n";
			print LOG "\t$fanspeed : Temp rising, Increasing Fan on GPU $gpu to $NewFan\n";
			#my $cmd = "nvidia-settings -a '[fan:$gpu]/GPUTargetFanSpeed=$NewFan'";
			my $cmd = "ethos-smi -g $gpu -F $NewFan";
			$output = system($cmd);
			print LOG "$output\n";
			}
		}	
	# Too damn hot
	elsif ( $temp >= $MaxTemp )
		{ 
		if ($pwrlmt > $MinPower)
			{
			my $NewPwr = $pwrlmt - $PowerIncrement;
			printf "\tDecreasing GPU $gpu Power Limit to $NewPwr\n";
			printf LOG "\tDecreasing GPU $gpu Power Limit to $NewPwr\n";
			#$output = `nvidia-smi -i $gpu -pl $NewPwr`;
			$output = `ethos-smi -g $gpu -p $NewPwr`;
			printf LOG "$output\n";
			}
		}
	
	
	# Getting chilly
	elsif  (($temp < ($MaxTemp * 0.90)) && ($pwrlmt < $defaultPwr))
		{
		if ($fanspeed > $MinFan)
			{
			#my $NewFan = $fanspeed - $FanIncrement;
			my $NewFan = $fanspeed - 1;
			print "\tSlowing Fan on GPU $gpu to $NewFan\n";
			print LOG "\tSlowing Fan on GPU $gpu to $NewFan\n";
			#my $cmd = "nvidia-settings -a '[fan:$gpu]/GPUTargetFanSpeed=$NewFan'";
			$output = `ethos-smi -g $gpu -F $NewFan`;
			print LOG "$output\n";
			}
#		elsif (($fanspeed <= $MinFan) && ($pwrlmt < $defaultPwr))
#			{
#			my $NewPwr = $pwrlmt + $PowerIncrement;
#			print "\tIncreasing GPU $gpu Power Limit to $NewPwr\n";
#			print LOG "\tIncreasing GPU $gpu Power Limit to $NewPwr\n";
#			$output = `ethos-smi -g $gpu -p $NewPwr`;
#			print LOG "$output\n";
#			}
		}
	}
