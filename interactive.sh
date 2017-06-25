#!/bin/bash

time=1
od=0 # whether run on "on demand" nodes
nodes=1
ppn=4
pmem=4
large=0 # whether run on large mem nodes
default_allocation="remills_flux"  # Large memory node names are automatically generated based on default_allocation
ondemand_allocation="remills_fluxod" 
allocation=$default_allocation
queue="fluxod"
q="flux"
temp="/tmp/chickenIfile$USER.pbs"
fileloc=   
fileinput=0
#outputloc=
fileoutput=0
name=$(echo $USER)_improvise_$(date +"%Y%m%d_%H%M%S")

function usage
{
    echo "Bash script:   interactive (This script generates and executes interactive HPC jobs on umich Flux by given parameters)"
    echo "Version:       1.2.5"
    echo 
    echo "Usage:    bash interactive.sh [options]"
    echo
    echo "options:     -t | --time        [int] Wall time of your interactive jobs in hours [default: $time]" 
    echo "             -N | --name        [str] Name of current job [default: $name]" 
    echo "             -o | --od          [int] Whether run on \"on demand\" nodes [default: $od]"
    echo "             -n | --nodes       [int] Number of nodes required [default: $nodes]"
    echo "             -p | --ppn         [int] Number of processors on each node [default: $ppn]"
    echo "             -m | --pmem        [int] Memory required for each processor in GB [default: $pmem]"
    echo "             -l | --large       [int] Whether you'd like to run on large mem nodes [default: $large]"
    echo "             -h | --help        Display this chicken message"
    echo "             -f | --file        Input a bash script file and convert it into bps file [default: ]"
    echo "             -s | --save        Print out generated PBS script to stdout, you may redirect it to save"
}

## Main, reading parameters
while [ "$1" != "" ]; do
    case $1 in
        -t | --time )           shift
                                time=$1
                                ;;
        -N | --name )           shift
                                name=$1
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
        -f | --file )           shift
                                fileloc=$1
                                ;;
        -s | --save )           shift
                                fileoutput=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ -n "$fileloc" ]; then
    fileinput=1
fi

## Proper Adjustment 
echo
if [ "$od" = "0" ]; then
#    echo "Job will be executed on normal nodes inseated of \"on demand\" nodes"
    queue="flux"
else
    allocation=$ondemand_allocation
#    echo "Job will be executed on \"on demand\" nodes"
fi

if [ "$large" != "0" ]; then
    if [ $pmem -le 4 ]; then
	echo "Memory per core is $pmem gb, no need to submit to large memory nodes"
	exit 
    fi
    if [ "$od" = "0" ]; then
	allocation=$(echo $default_allocation"m") 
    fi
    queue="fluxm"
else
    if [ $pmem -gt 4 ]; then
	echo "Memory per core is $pmem gb, please submit to large memory nodes"
	exit 
    fi
fi


pmemf=$(echo $pmem\gb) # format memory into pbs-acceptable form

## Generate PBS file using given parameters

if [ "$fileinput" -eq "1" ]; then
    echo "#PBS -N $name" >  $temp
    echo "#PBS -m abe" >> $temp
    echo "#PBS -M $USER@umich.edu" >> $temp
    echo "#PBS -d ." >> $temp
    echo "#PBS -o /home/$USER/.logs/$name.log" >> $temp
    echo "#PBS -e /home/$USER/.logs/$name.err" >> $temp
else
    echo "#PBS -N $(echo $USER)_interactive" >  $temp
fi


echo "#PBS -V" >> $temp
echo "#PBS -A $allocation" >> $temp
echo "#PBS -l qos=flux" >> $temp
echo "#PBS -q $queue" >> $temp
echo "#PBS -l nodes=$nodes:ppn=$ppn,pmem=$pmemf,walltime=$time:00:00" >> $temp
echo >> $temp
echo >> $temp

if [ "$fileinput" -eq "1" ] ; then
    less $fileloc | grep -v "#!/bin/bash" >> $temp&
fi

## if user wants to save the file, then output only
if [ "$fileoutput" -eq "1" ] ; then
    echo "#!/bin/bash"
    cat $temp
    less $fileloc | grep -v "#!/bin/bash" | cat
else
    ## else submit the job
    if [ "$od" = "0" ]; then
        echo "Job will be executed on normal nodes inseated of \"on demand\" nodes"
    else
        echo "Job will be executed on \"on demand\" nodes"
    fi
    echo "=========JOB OVERVIEW========="
    echo "Job Name: $name"
    echo "Total Cores: $(( $ppn * $nodes ))"
    echo "Nodes: $nodes"
    echo "Total Memory: $(( $ppn * $pmem * $nodes )) gb"
    echo "Wall Time: $time:00:00"
    echo "Large Memory Nodes: $(if [ $large == '0' ]; then echo "no"; else echo "yes"; fi)"
    echo "Allocation: $allocation"
    if [ "$fileinput" -eq "1" ] ; then
        echo
        echo "------------------------------"
        echo "EXECUTING FOLLOWING COMMANDS:"
        echo "------------------------------"
        less $fileloc | grep -v "#!/bin/bash" | cat
    fi
    echo "=============================="


    read -n1 -r -p "Does this look okay? Press Return to submit..." key

    if [ -z $key ]; then # Pressed, therefore submit
        if [ "$fileinput" -eq "1" ] ; then
            qsub $temp
    #   emacs $temp
        echo
        else
            qsub -I $temp 
    #   emacs $temp
        echo
        fi
    else
        echo 
        echo 
        echo Operation canceled
    fi
fi

## Delete the temp chicken file
rm -f $temp
