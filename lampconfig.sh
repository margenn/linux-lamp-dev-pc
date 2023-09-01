#!/bin/bash

# is there parameters?
if [ $# -eq 0 ]; then
	echo -e "${RED}ERROR: Please specify the desired stack:(APACHE,NGINX) (PHP7.4,PHP8.0) (MYSQL5.7,MYSQL8.0)${NOCOLOR}"
	exit 1
fi

#color of msgs
RED='\033[1;31m';GREEN='\033[1;32m';BLUE='\033[1;34m';NOCOLOR='\033[0m'

#transform parameters in uppercase
parameters=$(echo $1 | tr '[:lower:]' '[:upper:]')

#parsing parameters
webserverRegex='(APACHE|NGINX)'
if ! [[ $parameters =~ $webserverRegex ]]; then
	echo -e "${RED}ERROR: parameter must have 'APACHE' or 'NGINX'${NOCOLOR}"
	exit 1
fi
phpRegex='(PHP7.4|PHP8.0)'
if ! [[ $parameters =~ $phpRegex ]]; then
	echo -e "${RED}ERROR: parameter must have 'PHP7.4' or 'PHP8.0'${NOCOLOR}"
	exit 1
fi
mysqlRegex='(MYSQL5.7|MYSQL8.0)'
if ! [[ $parameters =~ $mysqlRegex ]]; then
	echo -e "${RED}ERROR: parameter must have 'MYSQL5.7' or 'MYSQL8.0'${NOCOLOR}"
	exit 1
fi

# stop everything
if service --status-all | grep -Fiq 'apache2'; then
	echo -e "${BLUE}Stopping APACHE${NOCOLOR}"
	systemctl stop apache2.service
fi
if service --status-all | grep -Fiq 'nginx'; then
	echo -e "${BLUE}Stopping NGINX${NOCOLOR}"
	systemctl stop nginx.service
fi
if service --status-all | grep -Fiq 'php7.4'; then
	echo -e "${BLUE}Stopping PHP7.4${NOCOLOR}"
	systemctl stop php7.4-fpm.service
fi
if service --status-all | grep -Fiq 'php8.0'; then
	echo -e "${BLUE}Stopping PHP8.0${NOCOLOR}"
	systemctl stop php8.0-fpm.service
fi
if service --status-all | grep -Fiq 'mysql5.7'; then
	echo -e "${BLUE}Stopping MYSQL5.7${NOCOLOR}"
	systemctl stop mysql5.7.service
fi
if service --status-all | grep -Fiq 'mysql8.0'; then
	echo -e "${BLUE}Stopping MYSQL8.0${NOCOLOR}"
	systemctl stop mysql8.0.service
fi


#start webserver + php
if [[ $parameters =~ ^.*APACHE.*$ ]]; then
		if [[ $parameters =~ ^.*PHP7.4.*$ ]]; then
			echo -e "${BLUE}Starting APACHE with PHP7.4${NOCOLOR}"
		update-alternatives --quiet --set php /usr/bin/php7.4
		ln -sf /etc/apache2/sites-available/localhost_php7.4.conf /etc/apache2/sites-enabled/localhost.conf
		#ln -sf /etc/apache2/sites-available/teste.dev.br_php7.4.conf /etc/apache2/sites-enabled/teste.dev.br.conf
		systemctl start apache2.service && systemctl start php7.4-fpm.service
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}SUCCESS: APACHE + PHP7 up and running!${NOCOLOR}"
		else
			echo -e "${RED}ERROR: APACHE + PHP7. Something went wrong...${NOCOLOR}"
		fi
	else
		echo -e "${BLUE}Starting APACHE with PHP8.0${NOCOLOR}"
		update-alternatives --quiet --set php /usr/bin/php8.0
		ln -sf /etc/apache2/sites-available/localhost_php8.0.conf /etc/apache2/sites-enabled/localhost.conf
		#ln -sf /etc/apache2/sites-available/teste.dev.br_php8.0.conf /etc/apache2/sites-enabled/teste.dev.br.conf
		systemctl start apache2.service && systemctl start php8.0-fpm.service
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}SUCCESS: APACHE + PHP8.0 up and running!${NOCOLOR}"
		else
			echo -e "${RED}ERROR: APACHE + PHP8.0 Something went wrong...${NOCOLOR}"
		fi
	fi
else
	if [[ $parameters =~ ^.*PHP7.4.*$ ]]; then
		echo -e "${BLUE}Starting NGINX with PHP7.4${NOCOLOR}"
		update-alternatives --quiet --set php /usr/bin/php7.4
		ln -sf /etc/nginx/sites-available/localhost_php7.4 /etc/nginx/sites-enabled/localhost
		#ln -sf /etc/nginx/sites-available/teste.dev.br_php7.4 /etc/nginx/sites-enabled/teste.dev.br
		systemctl start php7.4-fpm.service && systemctl start nginx.service
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}SUCCESS: NGINX + PHP7.4 up and running!${NOCOLOR}"
		else
			echo -e "${RED}ERROR: NGINX + PHP7.4 Something went wrong...${NOCOLOR}"
		fi
	else
		echo -e "${BLUE}Starting NGINX with PHP8.0${NOCOLOR}"
		update-alternatives --quiet --set php /usr/bin/php8.0
		ln -sf /etc/nginx/sites-available/localhost_php8.0 /etc/nginx/sites-enabled/localhost
		#ln -sf /etc/nginx/sites-available/teste.dev.br_php8.0 /etc/nginx/sites-enabled/teste.dev.br
		systemctl start nginx.service && systemctl start php8.0-fpm.service
		if [ $? -eq 0 ]; then
			echo -e "${GREEN}SUCCESS: NGINX + PHP8.0 up and running!${NOCOLOR}"
		else
			echo -e "${RED}ERROR: NGINX + PHP8.0 Something went wrong...${NOCOLOR}"
		fi
	fi
fi

#start mysql
if [[ $parameters =~ ^.*MYSQL5.7*$ ]]; then
	echo -e "${BLUE}Starting MYSQL5.7${NOCOLOR}"
	systemctl start mysql5.7.service
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}SUCCESS: MYSQL5.7 up and running!${NOCOLOR}"
	else
		echo -e "${RED}ERROR: MYSQL5.7 Something went wrong...${NOCOLOR}"
	fi
else
	echo -e "${BLUE}Starting MYSQL8.0${NOCOLOR}"
	systemctl start mysql8.0.service
	if [ $? -eq 0 ]; then
		echo -e "${GREEN}SUCCESS: MYSQL8.0 up and running!${NOCOLOR}"
	else
		echo -e "${RED}ERROR: MYSQL8.0 Something went wrong...${NOCOLOR}"
	fi
fi
