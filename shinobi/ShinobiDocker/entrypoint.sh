#!/bin/bash

##############
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1"; do
  >&2 echo "MySQL is currently unavailable - retrying..."
  sleep 1
done

>&2 echo ""
##############

mkdir -p /home/Shinobi && cp -a -R /opt/shinobi/. /home/Shinobi

if [ ! -e "/home/Shinobi/conf.json" ]; then
    cp /home/Shinobi/conf.sample.json /home/Shinobi/conf.json
fi

if [ ! -e "/home/Shinobi/super.json" ]; then
    cp /home/Shinobi/super.sample.json /home/Shinobi/super.json
    echo "Default Superuser : admin@shinobi.video"
    echo "Default Password : admin"
    echo "* You can edit these settings in \"super.json\" located in the Shinobi directory."
fi

DB_CONFIG=$(cat <<EOF
{
    "host": "${DB_HOST}",
    "user": "${DB_USER}",
    "password": "${DB_PASSWORD}",
    "database": "${DB_DATABASE}",
    "port": 3306
}
EOF
)
echo "Setting Database"
echo $DB_CONFIG

if [ "$SHINOBI_UPDATE" = "true" ]; then
    echo "Updating Shinobi..."
    git reset --hard
    git pull --rebase
fi

node tools/modifyConfiguration.js addToConfig="{\"db\": $DB_CONFIG}"

pm2 flush
pm2 start camera.js
pm2 logs --lines 200
