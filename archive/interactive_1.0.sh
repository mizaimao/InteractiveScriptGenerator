#!/bin/bash

time=1
od=0 # whether run on "on demand" nodes
nodes=1
ppn=4
pmem=4
large=0 # whether run on large mem nodes
allocation="remills_fluxod"
queue="fluxod"
q="flux"
temp="/tmp/chickenIfile$USER.pbs"


function usage
{
    echo "Bash script:   interactive (This script generates and executes interactive HPC jobs on umich Flux by given parameters)"
    echo "Version:       1.0"
    echo 
    echo "Usage:    bash interactive.sh [options]"
    echo
    echo "options:     -t | --time        [int] Wall time of your interactive jobs in hours [default: $time]" 
    echo "             -o | --od          [int] Whether run on \"on demand\" nodes [default: $od]"
    echo "             -n | --nodes       [int] Number of nodes required [default: $nodes]"
    echo "             -p | --ppn         [int] Number of processors on each node [default: $ppn]"
    echo "             -m | --pmem        [int] Memory required for each processor in GB [default: $pmem gb]"
    echo "             -l | --large       [int] Whether you'd like to run on large mem nodes [default: $large]"
    echo "             -h | --help        Display this chicken message"
#    echo "             -t | --time "
#    echo "             -t | --time "
#    echo "             -t | --time "
}


## Main, reading parameters
#if [ "$1" == "" ]; then    usage; exit; fi

while [ "$1" != "" ]; do
    case $1 in
        -t | --time )           shift
                                time=$1
                                ;;
        -o | --od )             shift
	                        od=$1
                                ;;
        -n | --nodes )          shift
	                        nodes=$1
                                ;;
        -p | --ppn )            shift
	                        ppn=$1
                                ;;
        -m | --pmem )           shift
	                        pmem=$1
                                ;;
        -l | --large )          shift
	                        large=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done


## Proper Adjustment 
if [ "$od" = "0" ]; then
    echo "Job will be executed on normal nodes inseated of \"on demand\" nodes"
    allocation="remills_flux"
    queue="flux"
else
    echo "Job will be executed on \"on demand\" nodes"
fi

if [ "$large" != "0" ]; then
    if [ $pmem -le 4 ]; then
	echo "Memory per core is $pmem gb, no need to submit to large memory nodes"
	exit 
    fi
    allocation="remills_fluxm"
    q="fluxm"
else
    if [ $pmem -gt 4 ]; then
	echo "Memory per core is $pmem gb, please submit to large memory nodes"
	exit 
    fi
fi

pmemf=$(echo $pmem\gb) # format memory into pbs-acceptable form

## Generate PBS file using given parameters


echo "#PBS -N $(echo $USER)_interactive" >  $temp
echo "#PBS -V" >> $temp
echo "#PBS -A $allocation" >> $temp
echo "#PBS -l qos=$queue" >> $temp
echo "#PBS -q $q" >> $temp
echo "#PBS -l nodes=$nodes:ppn=$ppn,pmem=$pmemf,walltime=$time:00:00" >> $temp

## Submit the job
echo "=======JOB OVERVIEW======="
echo "Cores: $(( $ppn * $nodes ))"
echo "Nodes: $nodes"
echo "Total Memory: $(( $ppn * $pmem )) gb"
echo "Wall Time: $time:00:00"
echo "Large Memory Nodes: $(if [ $large == '0' ]; then echo "no"; else echo "yes"; fi)"
echo "Allocation: $allocation"
echo "=========================="


read -n1 -r -p "Does this look okay? Press Return to submit..." key

if [ -z $key ]; then # Pressed, therefore submit
    qsub -I $temp 
#    emacs $temp
else
    echo
    echo Operation canceled
fi

## Delete the temp chicken file
rm -f $temp
