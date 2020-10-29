#!/bin/sh
read -p 'Site (<site>.local.designbysweet.com): ' sitevar
read -p 'Username: ' uservar
read -p 'Email: ' emailvar

# Generate docker-compose file
DATE=$(date '+%s')
sed "s/<site>/$sitevar/g" docker-compose.yml > docker-compose.${DATE}.yml
mv docker-compose.${DATE}.yml docker-compose.yml

# Start install container
docker rm -f tmp_install || true
docker-compose run -d --rm --name tmp_install install bash

# Create new database
docker exec proxy_local-mysql_1 mysql -u root -p"root" -e "create database if not exists \`${sitevar}\`"

# Run wp install commands
docker exec tmp_install wp core download
docker exec tmp_install wp config create --dbname=${sitevar} --dbhost=local-mysql --dbuser=root --dbpass=root
docker exec tmp_install wp core install --url=${sitevar}.local.designbysweet.com --title=${sitevar} --admin_user=$uservar --admin_email=$emailvar

# Copy installed files to host file system
docker cp tmp_install:/var/www/html ./src/

# Tidy up
docker rm -f tmp_install

# Start the project containers
docker-compose stop && docker-compose up -d --force-recreate

echo "Local Access:    http://${sitevar}.local.designbysweet.com"
echo "External Access: http://${sitevar}.tunnel.designbysweet.com"

