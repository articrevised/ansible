#!/bin/bash

# Update the package list
echo "Updating package list..."
sudo apt-get update -y

# Upgrade installed packages
echo "Upgrading installed packages..."
sudo apt-get upgrade -y

# Remove unnecessary packages and dependencies
echo "Removing unnecessary packages and dependencies..."
sudo apt-get autoremove -y

# Clean up package cache
echo "Cleaning up package cache..."
sudo apt-get autoclean -y

# Clear temporary files
echo "Clearing temporary files..."
sudo rm -rf /tmp/*

# Clear system cache
echo "Clearing system cache..."
sudo sync && sudo sysctl -w vm.drop_caches=3

# Clear user cache
echo "Clearing user cache..."
rm -rf ~/.cache/*

echo "System update and cleanup complete!"
