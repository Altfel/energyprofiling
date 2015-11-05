#!/bin/bash

# functions to save the current component usage during stress phases
save_cpu_usage ()
{
	PREV_TOTAL=0
	PREV_IDLE=0

	let step=0	 

	while [ $step -lt $1 ]
	do
		CPU=(`cat /proc/stat | grep '^cpu '`) # Get the total CPU statistics.

		unset CPU[0]                          # Discard the "cpu" prefix.

		USER=${CPU[1]}
		NICE=${CPU[2]}
		SYSTEM=${CPU[3]}
		IDLE=${CPU[4]}                        # Get the idle CPU time.
		IOWAIT=${CPU[5]}
		IRQ=${CPU[6]}
		SOFT_IRQ=${CPU[7]}

		# Calculate the total CPU time.
		TOTAL=0
		for VALUE in "${CPU[@]}"; do
			let "TOTAL=$TOTAL+$VALUE"
		done

		echo $(date +%s) $USER $NICE $SYSTEM $IDLE $IOWAIT $IRQ $SOFT_IRQ $TOTAL >> cpu_output

		let step=$step+1

		# Wait before checking again.
		sleep 1
	done
}

save_disk_usage ()
{
	let step=0	 

	while [ $step -lt $1 ] 
	do
		DISK=(`iostat -d -k sda | grep '^sda '`) # Get the total disk statistics.
		KB_RD=${DISK[4]}			 # Get the kb read and written
		KB_WRT=${DISK[5]}

		echo $(date +%s) $KB_RD $KB_WRT >> disk_output
		
		let step=$step+1

		# Wait before checking again.
		sleep 1
	done
}

save_frequency ()
{
	let step=0	 

	while [ $step -lt $1 ] 
	do
		FREQ_0=(`cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq`) # Get the frequency of CPU 0
		FREQ_1=(`cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq`) # Get the frequency of CPU 1

		echo $(date +%s) $FREQ_0 $FREQ_1 >> frequency_output
		
		let step=$step+1

		# Wait before checking again.
		sleep 1
	done
}

save_voltage ()
{
	let step=0	 

	while [ $step -lt $1 ] 
	do
		VOLTAGE=(`sensors | grep '^Vcore Voltage: '`) # Get the frequency of CPU 0

		echo $(date +%s) ${VOLTAGE[2]} >> voltage_output
		
		let step=$step+1

		# Wait before checking again.
		sleep 1
	done
}

# how long each stress phase lasts
timeout_seconds=30

# how many steps should the stressing of a component have
total_steps=20

# go from 0 to 100  with a step of 5% the workload at each step for 1 min

echo "Starting the CPU workload simulator..."

for ((i=1; i < $total_steps; i++)); do
	let j=$i*100/$total_steps
	echo "Launching CPU usage at $j percent"

	timeout $timeout_seconds lookbusy -c $j & save_cpu_usage $timeout_seconds & save_disk_usage $timeout_seconds & save_frequency $timeout_seconds #& save_voltage $timeout_seconds
done

echo "CPU workload simulator done"


