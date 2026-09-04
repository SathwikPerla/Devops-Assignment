#!/bin/bash

# ==============================================================================
# Script Name: system_info.sh
# Description: Gathers system details (date, hostname, user, disk, processes)
#              and saves process information to a user-defined directory and file.
# Author: Sathwik Perla
# Roll No: 590
# Email: perla.24bcs10590@sst.scaler.com
# ==============================================================================

echo "=========================================="
echo "      SYSTEM INFORMATION REPORT          "
echo "=========================================="

# 1. Variables to store system information
current_date=$(date)
system_hostname=$(hostname)
current_user=$(whoami)

# 2. Print basic system information using echo and variables
echo "Current Date & Time : $current_date"
echo "System Hostname     : $system_hostname"
echo "Current User        : $current_user"
echo ""

# 3. Print disk usage using df
echo "------------------------------------------"
echo "Disk Usage Summary:"
echo "------------------------------------------"
df -h
echo ""

# 4. Print running processes using ps
echo "------------------------------------------"
echo "Top Running Processes Snapshot:"
echo "------------------------------------------"
ps aux | head -n 10
echo ""

# 5. User Input using read -p
echo "=========================================="
echo "          BACKUP & LOGGING SETUP          "
echo "=========================================="
read -p "Enter directory name to create: " dir_name
read -p "Enter filename to save process logs: " file_name

# 6. Create directory using mkdir
mkdir -p "$dir_name"
echo "Directory '$dir_name' created successfully."

# 7. Create file using touch
touch "$dir_name/$file_name"
echo "File '$dir_name/$file_name' created successfully."

# 8. Store running processes in the file using > output redirection
ps aux > "$dir_name/$file_name"
echo "Running processes successfully written to '$dir_name/$file_name'."

echo ""
echo "Verification: First 5 lines of the saved file:"
echo "------------------------------------------"
head -n 5 "$dir_name/$file_name"
echo "=========================================="
echo "Report generation complete!"
