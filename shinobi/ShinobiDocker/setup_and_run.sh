#!/bin/bash

echo "Creating and setting permissions for the MySQL data directory..."
mkdir -p $HOME/ShinobiSQL
sudo chown -R 999:999 $HOME/ShinobiSQL
mkdir -p $HOME/Shinobi
sudo chown -R 999:999 $HOME/Shinobi

echo "Building the Docker image for Shinobi CCTV..."
# docker compose build -f docker-compose-main.yml up

# Prompt the user to decide whether to start the SQL container
echo "Do you want to start the Shinobi SQL service? [Y/n]"
read -p "Default is 'Yes': " yn
yn=${yn:-Y}  # Default response is 'Yes' if the input is empty

case $yn in
    [Yy]* ) echo "Starting the Shinobi SQL service...";
            # docker compose build -f docker-compose-sql.yml up
            docker compose -f docker-compose-sql.yml up -d && sleep 5;;
    [Nn]* ) echo "Skipping the Shinobi SQL service.";;
    * )     echo "Starting the Shinobi SQL service by default.";
            docker compose -f docker-compose-sql.yml up -d && sleep 5;;
esac

echo "Running the main Shinobi CCTV system..."
docker compose -f docker-compose-main.yml up -d

echo "Shinobi CCTV should now be accessible on port 8080."
