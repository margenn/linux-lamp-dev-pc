#!/bin/bash

# Lit of space-separated sites that you want to activate (/etc/../sites-enabled folder)
SERVERNAMES="localhost"

# CONSTANTS
WEBSERVERS='apache2 nginx'
PHPS='php7.4-fpm php8.0-fpm'
DATABASES='mysql5.7 mysql8.0'
XDEBUGS='xdebugon xdebugoff'; xdebugstate='on' #default
SERVICES="$WEBSERVERS $PHPS $DATABASES"
RED='\033[1;31m';GREEN='\033[1;32m';BLUE='\033[1;34m';NOCOLOR='\033[0m'

################################################################################
# FUNCTIONS

stopAllServices() {
	for srvc in $SERVICES;do
		if service --status-all | grep -Fiq "${srvc}"; then
			echo -e "${BLUE}Stopping ${srvc}${NOCOLOR}"
			systemctl stop ${srvc}.service
		fi
	done
}

################################################################################

# is there parameters?
if [ $# -eq 0 ]; then
	echo -e "${RED}ERROR: You must specify some stack. Eg: ...lampconfig.sh \"nginx php7 mysql5 xdebugoff\"${NOCOLOR}"
	exit 1
fi
# parameters to lowercase
parameters=$(echo $1 | tr '[:upper:]' '[:lower:]')

# if parameters contains "turnoffall", just shutdown all services and exit
if [[ $parameters = *"turnoffall"* ]]; then
	echo -e "${GREEN}Turning Off all services and exititing..."
	stopAllServices; exit 0
fi

# find choosen stack
for parameter in $parameters;do
	if [[ $WEBSERVERS == *"$parameter"* ]]; then # $parameter is substring of $WEBSERVERS?
		webserver=$(echo "$WEBSERVERS" | sed -E "s/.*(\S*$parameter\S*).*/\1/") # extract matched webserver from parameters
	elif [[ $PHPS == *"$parameter"* ]]; then
		php=$(echo "$PHPS" | sed -E "s/.*(\S*$parameter\S*)-fpm.*/\1/")
	elif [[ $DATABASES == *"$parameter"* ]]; then
		database=$(echo "$DATABASES" | sed -E "s/.*(\S*$parameter\S*).*/\1/")
	elif [[ $XDEBUGS == *"$parameter"* ]]; then
		if [[ $parameter == 'xdebugoff' ]]; then xdebugstate='off'
		elif [[ $parameter == 'xdebugon' ]]; then xdebugstate='on'
		fi
	else
		echo -e "${RED}ERROR: Parameter [$parameter] is not substring of [$SERVICES]${NOCOLOR}"
		exit 1
	fi
done

# check if mandatory parameters are present
if ! [[ -n "$webserver" ]]; then # webserver has been defined?
	echo -e "${RED}ERROR: WEBSERVER not defined.${NOCOLOR}"; exit 1
elif ! [[ -n "$php" ]]; then
	echo -e "${RED}ERROR: PHP not defined.${NOCOLOR}"; exit 1
elif ! [[ -n "$database" ]]; then
	echo -e "${RED}ERROR: DATABASE not defined.${NOCOLOR}"; exit 1
else
	echo -e "${BLUE}Choosen services: $webserver ${php}-fpm $database"
fi

# START ENVIRONMENT CONFIGURATION

stopAllServices

# apache configuration file has extension = '.conf'
conf=$(if [[ $webserver == *"apache"* ]]; then echo ".conf"; else echo ""; fi)

# configure
find /etc/$webserver/sites-enabled -maxdepth 1 -type l -exec rm {} \; # disable all sites
update-alternatives --quiet --set php /usr/bin/$php # choose php version
for servername in $SERVERNAMES;do
	echo -e "${BLUE}Enabling site [$servername] for [$webserver]/[$php]${NOCOLOR}"
	ln -sf /etc/${webserver}/sites-available/${servername}_${php}${conf} /etc/${webserver}/sites-enabled/${servername}${conf}
done

# enable/disable xdebug by removing/adding '-disabled' sufix in xdebug.ini
for item in $PHPS;do
	phpversion=$(echo $item | sed -E "s/php(.+)-fpm/\1/")
	xdebugini="/etc/php/${phpversion}/mods-available/xdebug.ini"
	if [[ $xdebugstate == "off" ]]; then
		if [[ -f "${xdebugini}-disabled" ]]; then # file exists?
			echo -e "${BLUE}xdebug ${phpversion} already OFF ${NOCOLOR}"
		elif [[ -f "/etc/php/${phpversion}/mods-available/xdebug.ini" ]]; then
			mv "$xdebugini" "$xdebugini-disabled" # disable xdebug
			echo -e "${GREEN}xdebug ${phpversion} OFF ${NOCOLOR}"
		fi
	else #xdebugon
		if [[ -f "${xdebugini}" ]]; then # file exists?
			echo -e "${BLUE}xdebug ${phpversion} already ON ${NOCOLOR}"
		elif [[ -f "/etc/php/${phpversion}/mods-available/xdebug.ini-disabled" ]]; then
			mv "$xdebugini-disabled" "$xdebugini" # enable xdebug
			echo -e "${GREEN}xdebug ${phpversion} ON ${NOCOLOR}"
		fi
	fi
done

# start services
systemctl start ${php}-fpm.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${php}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${php}].${NOCOLOR}" && exit 1; fi
systemctl start ${webserver}.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${webserver}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${webserver}].${NOCOLOR}" && exit 1; fi
systemctl start ${database}.service
if [ $? -eq 0 ]; then echo -e "${GREEN}[${database}] Started${NOCOLOR}"; else echo -e "${RED}ERROR:[${database}].${NOCOLOR}" && exit 1; fi

# change /etc/hosts according to SERVERNAMES
while read line; do
	# comment orphan lines without a servername
	if [[ "$line" =~ "127.0.0.1" ]]; then # only localhost ipv4
		servernameFound=false
		for servername in $SERVERNAMES; do
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
for servername in $SERVERNAMES; do
	if [[ $servername != "localhost" ]]; then
		regexLine="127.0.0.1\s*$servername"
		line=$(cat /etc/hosts | grep $regexLine)
		if ! [[ -n "$line" ]]; then # empty?
			# insert new entry after "127.0.0.1 localhost"
			sed -i -E "/127.0.0.1\\s+localhost/a 127.0.0.1\\t$servername" /etc/hosts
		else
			commentedRegex="^#\s*"
			if [[ "$line" =~ $commentedRegex ]]; then
				# uncomment line
				sed -i -E "s/^#\s*($regexLine)/\1/" /etc/hosts
			fi
		fi
	fi
done

echo
echo -e "${BLUE}############ /etc/hosts: hosts pointing to 127.0.0.1 ############"
while read line; do
	if [[ "$line" =~ "127.0.0.1" ]]; then echo -e "$line"; fi
done </etc/hosts
echo -e "#################################################################${NOCOLOR}"
