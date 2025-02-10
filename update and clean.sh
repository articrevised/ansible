#!/bin/bash

# Enhanced script to clear cache, logs, temporary files, and update all Proxmox containers

# Function to check and fix /tmp directory
check_and_fix_tmp() {
    local container_id=$1
    
    echo "Checking and fixing /tmp directory for container $container_id..."
    
    # Ensure /tmp exists and has correct permissions
    pct exec $container_id -- bash -c "mkdir -p /tmp && chmod 1777 /tmp" || echo "Failed to set up /tmp directory for container $container_id"
    
    # Check available space
    local available_space=$(pct exec $container_id -- bash -c "df /tmp | awk 'NR==2 {print \$4}'")
    if [ "$available_space" -lt 1000000 ]; then  # Less than ~1GB
        echo "Low disk space on /tmp for container $container_id. Attempting to free up space..."
        pct exec $container_id -- bash -c "find /tmp -type f -atime +1 -delete"
    fi
}

# Function to clear cache, logs, and unnecessary files in a container
clear_container_cache_logs() {
    local container_id=$1

    echo "Processing container $container_id..."

    # Check and fix /tmp directory
    check_and_fix_tmp $container_id

    # Clear cache
    pct exec $container_id -- bash -c "sync && echo 3 > /proc/sys/vm/drop_caches" || echo "Failed to clear cache for container $container_id"

    # Clear logs (be more conservative)
    pct exec $container_id -- bash -c "find /var/log -type f -name '*.log' -size +10M -exec truncate -s 10M {} \;" || echo "Failed to truncate large logs for container $container_id"
    pct exec $container_id -- bash -c "journalctl --vacuum-size=100M" || echo "Failed to clear old journal logs for container $container_id"

    # Clear various cache directories (excluding /tmp for now)
    pct exec $container_id -- bash -c "find /var/cache /var/backups -type f -delete" || echo "Failed to clear cache files for container $container_id"

    # Remove unnecessary packages and configurations
    pct exec $container_id -- bash -c "apt-get autoremove -y && apt-get autoclean" || echo "Failed to remove unnecessary packages for container $container_id"

    # Clear old crash reports and core dumps
    pct exec $container_id -- bash -c "find /var/crash -type f -delete" || echo "Failed to clear crash reports for container $container_id"
    pct exec $container_id -- bash -c "find /var/lib/systemd/coredump -type f -delete" || echo "Failed to clear core dumps for container $container_id"

    # Clear old thumbnails
    pct exec $container_id -- bash -c 'find /home/*/.thumbnails -type f -atime +30 -delete' || echo "Failed to clear old thumbnails for container $container_id"

    # Update container (with detailed error reporting)
    echo "Attempting to update container $container_id..."
    if ! pct exec $container_id -- bash -c "apt-get update -y && apt-get upgrade -y && apt-get clean -y"; then
        echo "Failed to update container $container_id. Detailed error:"
        pct exec $container_id -- bash -c "apt-get update -y" || true
        echo "APT sources list:"
        pct exec $container_id -- bash -c "cat /etc/apt/sources.list /etc/apt/sources.list.d/*" || true
        echo "APT keys:"
        pct exec $container_id -- bash -c "apt-key list" || true
    else
        echo "Successfully updated container $container_id"
    fi

    echo "Finished processing container $container_id"
}

# Main script execution
main() {
    echo "Starting enhanced Proxmox container cleanup and update process..."

    # Get list of all running containers
    containers=$(pct list | awk 'NR>1 && $2=="running" {print $1}')

    if [ -z "$containers" ]; then
        echo "No running containers found."
        exit 0
    fi

    # Iterate through each container and perform cleanup
    for ct_id in $containers; do
        clear_container_cache_logs $ct_id
    done

    echo "Cleanup complete. Temporary files removed, logs truncated, and containers updated where possible."
}

# Run the main function
main

# Error handling
if [ $? -ne 0 ]; then
    echo "An error occurred during script execution."
    exit 1
fi