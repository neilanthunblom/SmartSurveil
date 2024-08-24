#!/bin/bash

verbose=false
clean=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) verbose=true ;;
        -c|--clean) clean=true ;;
        -h|--help) 
            echo "Usage: $0 [-v|--verbose] [-h|--help] [-c|--clean]"
            exit 0 
            ;;
        *) 
            echo "Unknown parameter passed: $1"
            exit 1 
            ;;
    esac
    shift
done

output_message() {
    if [ "$verbose" == "true" ]; then
        echo "$1"
    fi
    
    if [ "$2" == "always" ]; then
        echo "Info: $1"
    fi
    
    if [ "$2" == "error" ]; then
        echo "ERROR: $1"
        exit 1
    fi
}

# SYSTEM -----------------------------------------------------
MOUNT_POINT="/mnt/shinobi_storage"
output_message "Mount point: $MOUNT_POINT"

# Check if the hard drive is connected
DRIVE_DEVICE="/dev/sda1"
output_message "Drive device: $DRIVE_DEVICE"
if [ ! -b "$DRIVE_DEVICE" ]; then
    output_message "Could not find the storage device at $DRIVE_DEVICE\n Please check the device path you have set in your .env file." "error"
fi

# Check if the storage path exists and create it if it doesn't
STORAGE_PATH="${MOUNT_POINT}/videos"
output_message "Storage path: $STORAGE_PATH"
if [ ! -f "$STORAGE_PATH" ]; then
    output_message "The storage path $STORAGE_PATH doesnt seem to exist. Creating it now." "always"
    sudo mkdir -p $STORAGE_PATH
    if [ ! -f "$STORAGE_PATH" ]; then
        output_message "Failed to create storage directory at $STORAGE_PATH" "error"
    fi
    sudo chmod -R 777 $STORAGE_PATH
    output_message "Storage directory created successfully" "always"
fi

output_message "Updating package list and upgrading installed packages" "always"
sudo apt-get update && sudo apt-get upgrade -y

# Docker -----------------------------------------------------
if [ ! docker --version ]; then
    output_message "Docker does not seem to be installed. Installing Docker and Docker Compose Now" "always"
    sudo apt-get install -y docker docker-compose
    
    if [ ! docker --version ]; then
        output_message "Failed to install Docker." "error"
    fi
    
    if [ ! docker-compose --version ]; then
        output_message "Failed to install Docker Compose." "error"
    fi
    
    output_message "Docker and Docker Compose were both installed successfully" "always"
fi




sudo mkdir -p $MOUNT_POINT
sudo mount $DRIVE_DEVICE $MOUNT_POINT

echo "$DRIVE_DEVICE $MOUNT_POINT ext4 defaults 0 0" | sudo tee -a /etc/fstab

if [ ! -f "$STORAGE_PATH" ]; then
    sudo mkdir -p $STORAGE_PATH
    if [ ! -f "$STORAGE_PATH" ]; then
        echo "Failed to create storage directory at $STORAGE_PATH"
        exit 1
    fi
    sudo chmod -R 777 $STORAGE_PATH
fi



docker-compose pull

docker-compose up -d

echo "Shinobi NVR setup complete. Videos will be stored at $STORAGE_PATH"