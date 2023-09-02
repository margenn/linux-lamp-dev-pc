#!/bin/bash

# Lit of space-separated sites that you want to activate (/etc/../sites-enabled folder)
servernames="localhost"

# all installed services (the name must be exactly the same of systemctl)
webservers='apache2 nginx'
phps='php7.4-fpm php8.0-fpm'
databases='mysql5.7 mysql8.0'

################################################################################

# is there parameters?
if [ $# -eq 0 ]; then
	echo -e "${RED}ERROR: You must specify some stack. Eg: ...lampconfig.sh \"nginx php7.4 mysql5.7\"${NOCOLOR}"
	exit 1
fi

# all services
services="$webservers $phps $databases"

# msg colors
RED='\033[1;31m';GREEN='\033[1;32m';BLUE='\033[1;34m';NOCOLOR='\033[0m'

# parameters to lowercase
parameters=$(echo $1 | tr '[:upper:]' '[:lower:]')

# find choosen stack
for parameter in $parameters;do
	if [[ $webservers == *"$parameter"* ]]; then # $parameter is substring of $webservers?
		webserver=$(echo "$webservers" | sed -E "s/.*(\S*$parameter\S*).*/\1/") # extract matched webserver
	elif [[ $phps == *"$parameter"* ]]; then
		php=$(echo "$phps" | sed -E "s/.*(\S*$parameter\S*)-fpm.*/\1/")
	elif [[ $databases == *"$parameter"* ]]; then
		database=$(echo "$databases" | sed -E "s/.*(\S*$parameter\S*).*/\1/")
	else
		echo -e "${RED}ERROR: Parameter [$parameter] is not substring of [$services]${NOCOLOR}"
		exit 1
	fi
done

# check if services are present
if ! [[ -n "$webserver" ]]; then
	echo -e "${RED}ERROR: WEBSERVER not defined.${NOCOLOR}"; exit 1
elif ! [[ -n "$php" ]]; then
	echo -e "${RED}ERROR: PHP not defined.${NOCOLOR}"; exit 1
elif ! [[ -n "$database" ]]; then
	echo -e "${RED}ERROR: DATABASE not defined.${NOCOLOR}"; exit 1
else
	echo -e "${BLUE}Choosen services: $webserver ${php}-fpm $database"
fi

# START ENVIRONMENT CONFIGURATION

# stop all services
for srvc in $services;do
	if service --status-all | grep -Fiq "${srvc}"; then
		echo -e "${BLUE}Stopping ${srvc}${NOCOLOR}"
		systemctl stop ${srvc}.service
	fi
done

# apache configuration file has extension = '.conf'
conf=$(if [[ $webserver == *"apache"* ]]; then echo ".conf"; else echo ""; fi)

# configure
find /etc/$webserver/sites-enabled -maxdepth 1 -type l -exec rm {} \; # disable all sites
update-alternatives --quiet --set php /usr/bin/$php # choose php version
for servername in $servernames;do
	echo -e "${BLUE}Enabling site [$servername] for [$webserver]/[$php].${NOCOLOR}"
	ln -sf /etc/${webserver}/sites-available/${servername}_${php}${conf} /etc/${webserver}/sites-enabled/${servername}${conf}
done

# start services
systemctl start ${php}-fpm.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${php}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${php}].${NOCOLOR}" && exit 1; fi
systemctl start ${webserver}.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${webserver}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${webserver}].${NOCOLOR}" && exit 1; fi
systemctl start ${database}.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${database}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${database}].${NOCOLOR}" && exit 1; fi

# remove/add entries in /etc/hosts according to servernames
while read line; do
	# comment orphan lines without a servername
	if [[ "$line" =~ "127.0.0.1" ]]; then # only localhost ipv4
		servernameFound=false
		for servername in $servernames; do
			if [[ $servername != "localhost" ]]; then
				if [[ "$line" =~ $servername ]]; then
					servernameFound=true
					break
				fi
			fi
		done
		if [[ "$servernameFound" = false ]]; then
			# this line does not have a servername, comment it
			if ! [[ $line =~ localhost ]]; then
				commentedRegex='^#.+'
				if ! [[ "$line" =~ $commentedRegex ]]; then
					orphanHostname=$(echo "$line" | sed -E "s/.+\s+(\S+)/\1/") # extract last word (webserver)
					# comment unused local dns
					sed -i "/$orphanHostname/ s/./# &/" /etc/hosts # comment line
				fi
			fi
		fi
	fi
done </etc/hosts
# insert/uncoment lines with servername
for servername in $servernames; do
	if [[ $servername != "localhost" ]]; then
		regexLine="127.0.0.1\s*$servername"
		line=$(cat /etc/hosts | grep $regexLine)
		# echo $line
		if ! [[ -n "$line" ]]; then # empty?
			# insert new entry after "127.0.0.1 localhost"
			sed -i -E "/127.0.0.1\\s+localhost/a 127.0.0.1\\t$servername" /etc/hosts
		else
			commentedRegex="^#\s*"
			if [[ "$line" =~ $commentedRegex ]]; then
				echo $line
				# uncomment line
				sed -i -E "s/^#\s*($regexLine)/\1/" /etc/hosts
			fi
		fi
	fi
done

echo "################### /etc/hosts: relevant lines ##################"
while read line; do
	if [[ "$line" =~ "127.0.0.1" ]]; then echo "$line"; fi
done </etc/hosts
echo "#################################################################"
