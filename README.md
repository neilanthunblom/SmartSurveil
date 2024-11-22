# SmartSurveil Stack

## Overview

This is a docker compose stack that is used to (almost) automatically deploy a local surveillance system using wyze cameras and a raspberry pi. The stack is designed to be modular, so you can pick and choose which services you want to run. The stack is designed to be run on a Raspberry Pi, but can be run on any device that supports docker and docker-compose and has ample resources.

### Configurations

- **Apple HomeKit Secure Video**: This configuration uses the Wyze Bridge to connect to your Wyze cameras and stream them to Apple's HomeKit Secure Video via Scrypted. This is the easiest configuration, and allows you to view your cameras in the Home app on an iOS, iPadOS, TVOS, or MacOS device. Currently, it does not allow you to record video locally to the pi, instead it uses Apple's iCloud service to store the video this requires a subscription to iCloud and ample storage space.
- **Local Recording**: This configuration uses the Wyze Bridge to connect to your Wyze cameras and stream them to a local Shinobi instance. This allows you to record video locally to the pi, and view the cameras in a web interface. This configuration is more complex to set up (most of the complexity for you, but extra config is needed), but is more flexible and does not require a subscription to iCloud+.
- **Both**: You can run both configurations at the same time, but this will require more resources from the pi but allows you to store video locally and in iCloud and view the cameras from non-Apple devices easily. This is the most complex configuration to set up, but is the most flexible and fault tolerant.

## Features

Both of these configurations have the option for local facial recognition using either HomeKit Secure Video in combination with your iCloud Photos face data and a Home Hub, or Shinobi in combination with the custom facial recognition plugin(coming soon).

### The core stack is composed of the following services

- [Wyze Bridge](https://github.com/mrlt8/docker-wyze-bridge) - Connects to your Wyze cameras and creates a local RTSP stream, allowing you to access the feed from other services.
- [Shinobi](https://shinobi.video/) - Records the RTSP stream from the Wyze Bridge and provides a web interface to view the cameras. It also manages the storage of the video files and integrates with the custom facial recognition plugin(coming soon).
- [MySQL](https://www.mysql.com/) - Used by Shinobi to store configurations, and video metadata, among other things. **NOTE** For compatibility with Shinobi which uses still uses ``mysql_native_password``, the MySQL image version must be less than [8.4](https://dev.mysql.com/doc/refman/8.0/en/native-pluggable-authentication.html) to avoid authentication between Shinobi and MySQL.
- [Scrypted](https://scrypted.app/) - Processes and rebroadcasts network video streams. Currently, it is used as an interface between the Wyze Bridge and HomeKit Secure Video, but I have plans to expand its use in the future.

### Supporting Services
- [Nginx](https://www.nginx.com/) -acts as the interface (reverse proxy) for communication to the core services, allowing the use of domain names and SSL certificates.

## Requirements

- A Raspberry Pi (or other device that supports docker and docker-compose)
- Wyze Account and [cameras](https://github.com/mrlt8/docker-wyze-bridge?tab=readme-ov-file#supported-cameras)
- An external hard drive (optional, but recommended)

### Tested Hardware

- [Raspberry Pi 5 4GB](https://vilros.com/products/raspberry-pi-5)
- [SanDisk 128GB MicroSD Card](https://www.westerndigital.com/products/memory-cards/sandisk-extreme-uhs-i-microsd?sku=SDSQXAA-128G-AN6MA)
- [Western Digital My Passport Ultra 5TB](https://www.westerndigital.com/products/portable-drives/wd-my-passport-ultra-usb-c-hdd?sku=WDBFTM0050BBL-WESN)
- [Wyze Cam V3](https://www.wyze.com/products/wyze-cam-v3)
- [Wyze Cam V2](https://www.wyze.com/products/wyze-cam-v2)
- [Wyze Video Doorbell V2](https://www.wyze.com/products/wyze-video-doorbell-v2)

## Installation

### 1. Clone this repository and navigate to the directory

```bash
git clone https://github.com/neilanthunblom/SmartSurveil
cd local-surveillance-stack
```

### 2. Copy the `sample.env` file to `.env`

Fill in the required fields. Here you can decide which services you want to run. If you already have a configured external hard drive, add its information here to automatically mount it.

```bash
cp sample.env .env
vim .env
```

**Note**: For most Linux distros (like Raspberry Pi OS) you can find the device path for the external hard drive by running `lsblk` and looking for the device that matches the size of your hard drive. It will be something like `/dev/sda1`.

### 3. Run the `setup.sh` script

This will set up the base of the stack based on the configurations in the `.env` file.

```bash
./setup.sh
```

#### This script does the following

- If you have `USE_EXTERNAL_STORAGE` set to true:
    - Mounts the external hard drive to the `/mnt` directory
    - Formats the external hard drive to ext4 (if it is not already)
    - Creates the necessary directories for footage storage
- If you have `USE_EXTERNAL_STORAGE` set to false:
    - Creates the necessary directories for footage storage in the root filesystem
- Creates the necessary directories for shinobi, mysql, and scrypted
- Installs docker and docker-compose (if not already installed)

**Note**: You shouldnt run scripts from the internet especially as sudo. However, this script creates directories in the root filesystem and deals with mounting and formatting drives, for time's sake I used a method that requires sudo. I know this script is safe(I wrote it), but as a best practice, I recommend manually creating the directories and mounting the drives if you have the skill (and the time).

**TL:DR Don't run internet scripts as sudo. Run the commands manually or read the script first**

### 4. Add SSL Certificates for nginx

Generate SSL certificates for each domain name you have set in the `.env` file. As this server is not intended to be public facing, you can use self-signed certificates. In the future, I will add a way to do this automatically, in the meantime you can generate self-signed certs using the command below or check out my automated private Certificate Authority project on my GitHub.

**If you do not want to use SSL, you can comment out the `nginx` service in the `docker-compose.yml` file.**

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx/ssl/{serviceName}/your-domain.key.pem -out ./nginx/ssl/{serviceName}/your-domain.cert.pem
```

### 5. Update nginx configuration
If using SSL, update the `nginx.conf` file in the `./nginx` directory with the correct domain names and SSL certificates.

### 6. Update the Shinobi database configuration
Update the default user.sql file in ./shinobi/ShinobiDocker/mysql-init with your own credentials to match the .env file's MYSQL_USER and MYSQL_PASSWORD.

### 7. Start the stack

```bash
docker-compose up -d
```

### 8. Access the services
Once the stack is up and running, you can access the services at the following URLs (replace `your-domain` with the domain name you set in the `.env` file or the IP address of the pi if you are not using SSL/NGINX):

- Shinobi: `http(s)://your-domain:8080`
- Scrypted: `http(s)://your-domain:10443`
- Wyze Bridge: `http(s)://your-domain:5000`

# Troubleshooting

## Raspberrypi 5 with Ubuntu 24.04 - ethernet connection not working

Fix: Run the following commands on the file /etc/netplan/50-cloud-init.yaml

```bash
sudo vim /etc/netplan/50-cloud-init.yaml
```
```bash
network:
    ethernets:
        eth0:
            dhcp4: true
            optional: true
```
```bash
sudo netplan generate
sudo netplan apply
```

## Shinobi - ER_NOT_SUPPORTED_AUTH_MODE: Client does not support authentication protocol requested by server; consider upgrading MySQL client
Fix: Use a MySQL image version less than 8.4.

Shinobi still uses ``mysql_native_password`` for authentication with MySQL. As of MySQL 8.4, mysql_native_password is disabled by default and in MySQL 9.0 and later, it is removed in favor of ``caching_sha2_password``. 

#### Raspberry Pi (And other ARMv8 CPUs)
This presents an issue for users with ARMv8 CPUs and a 64-bit OS as the only official Docker images of MySQL that default to ``mysql_native_password`` AND are built for ARMv8 are **MySQL 8.0 to 8.0.32**. 