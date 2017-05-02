# InteractiveScriptGenerator
umich Flux automatic interactive script generator and submitter 


Bash script:   interactive (This script generates and executes interactive HPC jobs on umich Flux by given parameters)
Version:       1.2

Usage:    bash interactive.sh [options]

options:     -t | --time        [int] Wall time of your interactive jobs in hours [default: 1]
             -o | --od          [int] Whether run on "on demand" nodes [default: 0]
             -n | --nodes       [int] Number of nodes required [default: 1]
             -p | --ppn         [int] Number of processors on each node [default: 4]
             -m | --pmem        [int] Memory required for each processor in GB [default: 4 gb]
             -l | --large       [int] Whether you'd like to run on large mem nodes [default: 0]
             -h | --help        Display this chicken message
             -f | --file        Input a bash script file and convert it into bps file [default: ]
