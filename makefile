#!/usr/bin/env make
# DESCRIPTION
# Restore user config
#
# USAGE
# make -f makefile
#
# @author: Édouard Lopez <dev+restore@edouard-lopez.com>

ifneq (,)
This makefile requires GNU Make.
endif

# force use of Bash
SHELL := /bin/bash
user := ed8

settingsDir:=/mnt/data/settings
projectsDir:=/mnt/data/projects
backupDest:=/media/ed8/51ee8de5-b1a9-4d57-9a94-24b9b1d0d10b/data-backup
distroUbuntu:=trusty
additionRepos:=/etc/apt/sources.list.d/additional-repositories.list

# for SSL certificates
SSL_KEY_NAME:=web
SSL_KEY_PATH:=/etc/ssl/$$USER/${SSL_KEY_NAME}

default:	backup repo core-utils editor-theme editor \
	python nodejs \
	utils network security \
	upgrade
	# cfdict

ssl-certificate: ${SSL_KEY_PATH}


upgrade:
	apt-get update && apt-get -y upgrade

graphic:
	apt-get -y install {shutter,libgoo-canvas-perl} kipi-plugins{,-common} agave

utils:
	apt-get update
	apt-get -y install htop tmux tree colordiff git{,k,-gui} dolphin

dataviz:
	apt-get -y install gdal-bin

datamining:
	npm install -g topojson xml2json-command underscore-cli #json tools
	apt-get -y install jq awk jshon visual-regexp


scanner:
	grep "${distroUbuntu}-arakhne" ${additionRepos} \
		&& echo "deb http://download.tuxfamily.org/arakhne/ubuntu ${distroUbuntu}-arakhne universe" >> ${additionRepos}
	wget -q http://download.tuxfamily.org/arakhne/public.key -O- | apt-key add -
	apt-get -y install okular djvulibre-bin tesseract-ocr{,-fra} libsane-epson-perfection-1670

audio:
	apt-get -y install {libav,opus,vorbis}-tools

network:
	apt-get -y install whois bmon nethogs python-software-properties mosh nmap

editor-theme: editor
	if [[ ! -d ${settingsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${settingsDir}/tomorrow-theme; fi
	ln -nfs ${settingsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${settingsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${settingsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${settingsDir}/tomorrow-theme-konsole/*.colorscheme $$HOME/.kde/share/apps/konsole/
	ln  -nfs $$HOME/dotfiles/.oh-my-zsh/themes/* $$HOME/.oh-my-zsh/themes/
	@printf "You need to \n"

#@alias: ssl-certificate
# ${SSL_KEY_PATH}.%:
${SSL_KEY_PATH}.%:
	[[ ! -d /etc/ssl/$$USER ]] && mkdir -p "/etc/ssl/$$USER" || true
	openssl req -new -sha256 -x509 -nodes -days 365 -newkey rsa:4096 \
		-keyout $@.key \
		-out 	$@.crt

security: ssl-certificate
	apt-get update
	apt-get -y install gnupg2 gnupg-agent kgpg
	apt-get -y install keepass2 mono-complete

cfdict: apache2 nodejs ruby
	apt-get install -y jshon
	cd $HOME/.marks/cfdict-client/

# meta task
server-web: php mysql postgres apache2 python nodejs ruby

apache2:
		apt-get -y install apache2 apache2-utils
		rm /etc/apache2/{sites-available,sites-enabled} -rf
		ln -nfs /mnt/data/settings/apache2/* /etc/apache2/
		mkdir /etc/apache2/sites-enabled
		ln -nfs /etc/apache2/sites-available/* /etc/apache2/sites-enabled/
		a2enmod alias autoindex deflate expires headers include php5 rewrite vhost_alias
		service apache2 restart

mysql:
	apt-get -y install mysql-{{server,client},workbench}

# As normal user
pgmodelerVersion:=0.8.0-alpha1
pgmodeler:
	echo "out-of  date version → update!"
	cd ~/apps; \
		[[ ! -f ${pgmodelerVersion}.tar.gz ]] && wget -O "${pgmodelerVersion}.tar.gz" https://github.com/pgmodeler/pgmodeler/archive/v${pgmodelerVersion}.tar.gz || true; \
		tar xvzf ${pgmodelerVersion}.tar.gz -C ./ ; \
		cd pgmodeler-${pgmodelerVersion} \
		&& qmake -qt=5 QT+=designer pgmodeler.pro &&  make && make install

postgres:
	apt-get -y install postgresql pgadmin3
	echo "pgmodeler requirements"
	apt-get -y install libxml2{,-dev} libpq{5,-dev} qt{4,5}-qmake g++ libqt4-dev qt4-dev-tools libqt5serviceframework5 qtcreator{,-dev}  qtbase5-dev{,-tools} qttools5-dev

php:
	apt-get install -y php5{,-{mysql,pgsql}}

python:
	apt-get install -y ipython

nodejs:
	curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
	apt-get install -y nodejs
	npm update -g npm
	npm install -g yeoman gulp
	npm install -g generator-{angular,gulp-webapp,leaflet}
	npm cache clean

ruby:
	printf "Install RVM+Ruby\n"
	curl -sSL https://get.rvm.io | bash -s stable --ruby
	printf "Load RVM to SHELL\n"
	source "$HOME"/.rvm/scripts/rvm
	printf "Update ruby system"
	gem update --system
	gem install compass sass scss-lint bootstrap-sass

editor:
	@printf "Install editors\n"
	apt-get update
	apt-get -q -y install vim vim-youcompleteme zim

core-utils:
	add-apt-repository -y ppa:mozillateam/firefox-next
	apt-get update
	apt-get install -y git firefox zsh yakuake konsole curl
shell: 
	add-apt-repository ppa:fish-shell/release-2
	apt-get update
	apt-get install fish zsh
	curl -L http://install.ohmyz.sh | sh

repo:
	add-apt-repository -y ppa:kubuntu-ppa/backports
	apt-get update

backup:
	apt-get -y install {g,}rsync
	update-rc.d rsync defaults
	backupSrc="/mnt/data"; \
	backupDest="${backupDest}"; \
	backupList=( "paperwork" "projects" "server" "settings" ); \
	for backupDir in $${backupList[@]}; do \
		(crontab -u ${user} -l ; \
			echo "@daily rsync -r -t -p -o -g -v --progress --size-only -l -H --numeric-ids -s $${backupSrc}/$${backupDir} $${backupDest} --log-file \"$HOME/rsync.log\" "; \
		) | crontab -u ${user} - ; \
	done
