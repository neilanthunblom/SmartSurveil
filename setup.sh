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

# Setup -----------------------------------------------------
# Legal and disclaimer
output_message "This script is provided as is and without any warranty. Use at your own risk." "always"
output_message "This script installs a combination of first and third party software and packages. Please review the licenses of each package before using this script.\\n\\n" "always"
output_message "Starting the Surveillance Local AI setup script. This script will install a full featured local video surveillance system with AI capabilities." "always"
output_message "Ensure you update the .env file with the correct values before running this script for a more automated setup." "always"

# Check if the .env file exists
if [ ! -f .env ]; then
    output_message "Could not find the .env file. For a more automated setup, please copy the sample.env file to .env and update the values." "error"
fi

# Storage -----------------------------------------------------

mount_external_drive() {
    output_message "Mounting external drive" "always"
    sudo mkdir -p /mnt/external_drive
    sudo mount $DRIVE_DEVICE /mnt/external_drive
}

create_storage_directory() {
    output_message "Creating storage directory" "always"
    sudo mkdir -p $STORAGE_PATH
    sudo chmod -R 777 $STORAGE_PATH
}

update_env_file() {
    output_message "Updating the .env file" "always"
    sed -i "s/DRIVE_DEVICE=.*/DRIVE_DEVICE=$DRIVE_DEVICE/" .env
    sed -i "s/USE_EXTERNAL_STORAGE=.*/USE_EXTERNAL_STORAGE=$USE_EXTERNAL_STORAGE/" .env
    sed -i "s/MOUNT_POINT=.*/MOUNT_POINT=$MOUNT_POINT/" .env
    sed -i "s/LOCAL_STORAGE_PATH=.*/LOCAL_STORAGE_PATH=$STORAGE_PATH/" .env
}

format_external_drive() {
    output_message "The drive device $DRIVE_DEVICE does not seem to be formatted. Would you like to format it now? (y/n): " "always"
    read -r format_drive
    
    # If the user wants to format the drive, format it with ext4
    if [ "$format_drive" == "y" ]; then
        output_message "Formatting drive $DRIVE_DEVICE with ext4.\\n WARNING: This will erase all data on the drive. Are you sure you want to erase the drive? (y/n): " "always"
        read -r erase_drive
        
        if [ "$erase_drive" != "y" ]; then
            output_message "We will not format the drive. Please select a different drive and define it in the .env file. Would you like to continue using the internal storage? (y/n): " "always"
            read -r use_internal_storage
            
            if [ "$use_internal_storage" == "y" ]; then
                internal_drive_config
            else
                output_message "Please format the drive as ext4 and run the script again." "error"
            fi
        fi
        
        sudo mkfs.ext4 $DRIVE_DEVICE
        
        if [ ! -b "$DRIVE_DEVICE" ]; then
            output_message "Failed to format the drive. Please format it as ext4 and run the script again." "error"
        fi
    else
        output_message "Failed to automatically format the drive." "always"
        internal_drive_config
    fi
}

external_drive_config() {
    output_message "Searching for external drives" "always"
    
    DRIVE_DEVICE=$(lsblk -b -o NAME,SIZE | grep -v NAME | sort -k2 -n | tail -n1 | awk '{print $1}')
    output_message "Found drive device: $DRIVE_DEVICE. Do you want to use this drive for storage? (y/n): " "always"
    read -r use_drive
    
    if [ "$use_drive" == "y" ]; then
        # Check if the drive is formatted
        if [ ! -b "$DRIVE_DEVICE" ]; then
            format_external_drive
        fi
        
        # Check if the drive is mounted
        MOUNT_POINT="/mnt/external_footage"
        if [ ! -d "$MOUNT_POINT" ]; then
            mount_external_drive
        fi
        
        # Check if the storage path is defined in the .env file
        storage_path=$(grep -i "LOCAL_STORAGE_PATH" .env | cut -d '=' -f2)
        if [ -z "$storage_path" ]; then
            output_message "The LOCAL_STORAGE_PATH is not defined in the .env file. Using the default path: $MOUNT_POINT/videos" "always"
        fi
        
        STORAGE_PATH="$MOUNT_POINT/footage"
        
        if [ ! -f "$STORAGE_PATH" ]; then
            output_message "The storage path $STORAGE_PATH doesnt seem to exist. Creating it now." "always"
            sudo mkdir -p $STORAGE_PATH
            if [ ! -f "$STORAGE_PATH" ]; then
                output_message "Failed to create storage directory at $STORAGE_PATH" "error"
            fi
            sudo chmod -R 777 $STORAGE_PATH
            output_message "Storage directory created successfully" "always"
        fi
        
        # Update the .env file with the drive device and the mount point
        sed -i "s/DRIVE_DEVICE=.*/DRIVE_DEVICE=$DRIVE_DEVICE/" .env
        sed -i "s/USE_EXTERNAL_STORAGE=.*/USE_EXTERNAL_STORAGE=$USE_EXTERNAL_STORAGE/" .env
        sed -i "s/MOUNT_POINT=.*/MOUNT_POINT=$MOUNT_POINT/" .env
        sed -i "s/LOCAL_STORAGE_PATH=.*/LOCAL_STORAGE_PATH=$STORAGE_PATH/" .env
    else
        internal_drive_config
    fi
}

internal_drive_config() {
    output_message "Using internal storage. WARNING: This will use the internal storage of the device for video storage. This is not recommended for devices with sd cards (ie Raspberry Pi) as it may reduce the lifespan of the sd card." "always"
    USE_EXTERNAL_STORAGE="false"
    
    #check if the storage path is defined in the .env file
    storage_path=$(grep -i "LOCAL_STORAGE_PATH" .env | cut -d '=' -f2)
    if [ -z "$storage_path" ]; then
        output_message "The LOCAL_STORAGE_PATH is not defined in the .env file. Using the default path: ./footage" "always"
    fi
    
    STORAGE_PATH="./footage"
    if [ ! -f "$STORAGE_PATH" ]; then
        output_message "The storage path $STORAGE_PATH doesnt seem to exist. Creating it now." "always"
        sudo mkdir -p $STORAGE_PATH
        if [ ! -f "$STORAGE_PATH" ]; then
            output_message "Failed to create storage directory at $STORAGE_PATH" "error"
        fi
        sudo chmod -R 777 $STORAGE_PATH
        output_message "Storage directory created successfully" "always"
    fi
    
    # Update the .env file with LOCAL_STORAGE_PATH and USE_EXTERNAL_STORAGE
    sed -i "s/LOCAL_STORAGE_PATH=.*/LOCAL_STORAGE_PATH=$STORAGE_PATH/" .env
    sed -i "s/USE_EXTERNAL_STORAGE=.*/USE_EXTERNAL_STORAGE=$USE_EXTERNAL_STORAGE/" .env
}

# Check if the user wants to use an external drive for storage from the USE_EXTERNAL_STORAGE variable in the .env file
USE_EXTERNAL_STORAGE=$(grep -i "USE_EXTERNAL_STORAGE" .env | cut -d '=' -f2)
output_message "Using external storage: $USE_EXTERNAL_STORAGE"

if [ "$USE_EXTERNAL_STORAGE" == "true" ]; then
    # Check if the local storage path is defined in the .env file
    DRIVE_DEVICE=$(grep -i "DRIVE_DEVICE" .env | cut -d '=' -f2)
    if [ -z "$DRIVE_DEVICE" ]; then
        output_message "The DRIVE_DEVICE is not defined in the .env file. Starting the external drive configuration." "always"
        
        external_drive_config
    fi
else
    internal_drive_config
fi

# Install -----------------------------------------------------
# Check for docker and docker-compose
output_message "Checking for docker and docker-compose" "always"
if ! command -v docker &> /dev/null; then
    output_message "Docker not found. Installing docker" "always"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl enable docker
    sudo systemctl start docker
    output_message "Docker installed successfully" "always"
fi

if ! command -v docker-compose &> /dev/null; then
    output_message "Docker-compose not found. Installing docker-compose" "always"
    sudo apt install -y docker-compose
    output_message "Docker-compose installed successfully" "always"
fi

# Install shinobi -----------------------------------------------------
output_message "Installing Shinobi" "always"
output_message "Creating and setting permissions for the Shinobi MySQL data directory..."
# check if the directory exists
if [ ! -d "./shinobi/mysql" ]; then
    mkdir -p ./shinobi/mysql
    sudo chown -R 999:999 ./shinobi/mysql
fi

output_message "Creating and setting permissions for the Shinobi videos directory..."
# check if the directory exists
if [ ! -d "./shinobi/shinobi" ]; then
    mkdir -p ./shinobi/shinobi
    sudo chown -R 999:999 ./shinobi/shinobi
fi