#!/bin/bash
# meshing-around shell script for sysinfo
# runShell.sh
cd "$(dirname "$0")"
program_path=$(pwd)

# get basic telemetry data. Free space, CPU, RAM, and temperature for a raspberry pi
free_space=$(df -h | grep ' /$' | awk '{print $4}')
free_space2=$(df -h | grep 'euler' | awk '{print $4}')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
ram_usage=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
ram_free=$(echo "scale=2; 100 - $ram_usage" | bc)

# if command vcgencmd is found, part of raspberrypi tools, use it to get temperature
if command -v cputemp &> /dev/null
then
    temp=$(cputemp)
    # temp in fahrenheit
    tempf=$(echo "scale=2; $temp * 9 / 5 + 32" | bc)
elif command -v vcgencmd &> /dev/null
then
    # get temperature
    temp=$(vcgencmd measure_temp | sed "s/temp=//" | sed "s/'C//")
    # temp in fahrenheit
    tempf=$(echo "scale=2; $temp * 9 / 5 + 32" | bc)
else
    # get temperature from thermal zone
    temp=$(paste <(cat /sys/class/thermal/thermal_zone*/type) <(cat /sys/class/thermal/thermal_zone*/temp) | grep "temp" | awk '{print $2/1000}' | awk '{s+=$1} END {print s/NR}')
    tempf=$(echo "scale=2; $temp * 9 / 5 + 32" | bc)
fi

printf "SysFree:%s DataFree:%s RAM:%.2f%% CPU:%.2f%% CPU-T:%.2f°C (%.2f°F)\n" "$free_space" "$free_space2" "$ram_usage" "$cpu_usage" "$temp" "$tempf"

