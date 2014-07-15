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

default:	backup repo core-utils editor-theme editor \
			server-web ruby nodejs mysql postgres apache2  \
			utils audio network security \
			datamining scanner
		# cfdict

utils:
	apt-get -y install tmux tree colordiff git{,k,-gui} visual-regexp jshon verbiste{,-gnome} dolphin

dataviz:
	apt-get -y install gdal-bin

datamining:
	npm install -g topojson xml2json-command underscore-cli #json tools
	apt-get -y install jq awk


scanner:
	grep "${distroUbuntu}-arakhne" ${additionRepos} \
		&& echo "deb http://download.tuxfamily.org/arakhne/ubuntu ${distroUbuntu}-arakhne universe" >> ${additionRepos}
	wget -q http://download.tuxfamily.org/arakhne/public.key -O- | apt-key add -
	apt-get -y install okular djvulibre-bin tesseract-ocr{,-fra} libsane-epson-perfection-1670

audio:
	apt-get -y install {libav,opus,vorbis}-tools

network:
	apt-get -y install whois bmon sshuttle python-software-properties
	add-apt-repository -y ppa:keithw/mosh
	apt-get update
	apt-get install mosh

editor-theme: editor
	if [[ ! -d ${settingsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${settingsDir}/tomorrow-theme; fi
	ln -nfs ${settingsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${settingsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${settingsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${settingsDir}/tomorrow-theme-konsole/*.colorscheme $$HOME/.kde/share/apps/konsole/
	@printf "You need to \n"

security:
	apt-get update
	apt-get -y install gnupg2 gnupg-agent kgpg gnome-encfs-manager ettercap-graphical

cfdict: apache2 nodejs ruby
	apt-get install -y jshon
	cd $HOME/.marks/cfdict-client/

# meta task
server-web: apache2 mysql postgres nodejs ruby

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

postgres:
	apt-get -y install postgres

nodejs:
	add-apt-repository -y chris-lea/node.js/ubuntu # nodejs
	apt-get update
	apt-get install nodejs
	npm update -g npm
	npm install -g yeoman bower grunt-cli gulp
	npm install -g generator-{angular,gulp-webapp,leaftlet}
	# reactJS
	npm install -g jshint-jsx react-tools
	npm cache clean; bower cache clean

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
	add-apt-repository -y ppa:webupd8team/atom # Atom Editor
	add-apt-repository -y ppa:webupd8team/sublime-text-3 # sublime text 3 editor
	apt-get update
	apt-get -q -y install vim vim-youcompleteme zim sublime-text atom tidy

core-utils:
	add-apt-repository -y ppa:mozillateam/firefox-next
	apt-get update
	apt-get install -y git firefox zsh yakuake


repo:
	add-apt-repository -y ppa:conscioususer/polly-daily # polly Twitter client
	add-apt-repository -y ppa:gencfsm/ppa # encfs GUI
	add-apt-repository -y kubuntu-ppa/ppa/ubuntu # KDE backport
	add-apt-repository -y peterlevi/ppa/ubuntu # variety wallpaper
	add-apt-repository -y synapse-core/testing/ubuntu # synapse launcher
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