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

default: editor

utils:
	apt-get -y install tree colordiff git{,k,-gui}

audio:
	apt-get -y install {libav,opus,vorbis}-tools

network:
	whois bmon

editor-theme: editor
	if [[ ! -d ${settingsDir}/tomorrow-theme ]]; then git clone --depth 1 https://github.com/chriskempson/tomorrow-theme.git ${settingsDir}/tomorrow-theme; fi
	ln -nfs ${settingsDir}/tomorrow-theme/vim/colors/*.vim $$HOME/.vim/colors/
	if [[ ! -d ${settingsDir}/tomorrow-theme-konsole ]]; then git clone --depth 1 https://github.com/dram/konsole-tomorrow-theme.git ${settingsDir}/tomorrow-theme-konsole; fi
	ln -nfs ${settingsDir}/tomorrow-theme-konsole/*.colorscheme $$HOME/.kde/share/apps/konsole/
	@printf "You need to \n"

security:
	apt-get -y install gnupg2 kgpg ettercap-graphical

server-web: apache2 mysql postgres

mysql:
	apt-get -y install mysql-{{server,client}-5.6,workbench}

postgres:
	apt-get -y install postgres

apache2:
		apt-get -y install apache2 apache2-utils
		rm /etc/apache2/{sites-available,sites-enabled} -rf
		ln -nfs /mnt/data/settings/apache2/* /etc/apache2/
		mkdir /etc/apache2/sites-enabled
		ln -nfs /etc/apache2/sites-available/* /etc/apache2/sites-enabled/
		a2enmod alias autoindex deflate expires headers include php5 rewrite vhost_alias
		service apache2 restart

cfdict: apache2 nodejs ruby
	cd $HOME/.marks/cfdict-client/

nodejs:
	add-apt-repository chris-lea/node.js/ubuntu # nodejs
	apt-get install nodejs
	npm update -g npm
	npm install -g yeoman bower grunt-cli gulp topojson
	npm cache clean; bower cache clean

ruby:
	printf "Install RVM+Ruby\n"
	curl -sSL https://get.rvm.io | bash -s stable --ruby
	printf "Load RVM to SHELL\n"
	source $HOME/.rvm/scripts/rvm
	printf "Update ruby system"
	gem update --system
	gem install compass sass scss-lint bootstrap-sass

editor:
	@printf "Install editors\n"
	add-apt-repository webupd8team/atom/ubuntu # Atom Editor
	add-apt-repository webupd8team/sublime-text-3/ubuntu # sublime text 3 editor
	apt-get -q -y install vim vim-youcompleteme sublime-text atom

repo:
	add-apt-repository ppa:conscioususer/polly-daily # polly Twitter client
	add-apt-repository ppa:gencfsm/ppa # encfs GUI
	add-apt-repository kubuntu-ppa/ppa/ubuntu # KDE backport
	add-apt-repository peterlevi/ppa/ubuntu # variety wallpaper
	add-apt-repository synapse-core/testing/ubuntu # synapse launcher

backup:
	apt-get -y install backintime-gnome {g,}rsync
	update-rc.d rsync defaults
	backupSrc="/mnt/data"; \
	backupDest="${backupDest}"; \
	backupList=( "paperwork" "projects" "server" "settings" ); \
	for backupDir in $${backupList[@]}; do \
		(crontab -u ${user} -l ; \
			echo "@daily rsync -r -t -p -o -g -v --progress --size-only -l -H --numeric-ids -s $${backupSrc}/$${backupDir} $${backupDest} --log-file \"$HOME/rsync.log\" "; \
		) | crontab -u ${user} - ; \
	done