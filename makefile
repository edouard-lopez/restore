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

settingsDir:=/data/settings
projectsDir:=/data/projects
backupSrcRoot:=/data
backupDest:=/media/ed8/ed-big5/data-backup
distroUbuntu:=trusty
additionRepos:=/etc/apt/sources.list.d/additional-repositories.list

# for SSL certificates
SSL_KEY_NAME:=web
SSL_KEY_PATH:=/etc/ssl/$$USER/${SSL_KEY_NAME}

default:	\
	atom-editor \
	albert-launcher \
	clipboard-manager \
	docker \
	graphic-editor \
	graphic-viewer \
	nodejs yarnpkg \
	utils network security \
	fonts shell \
	upgrade
	zeal-doc \
	# cfdict

ssl-certificate: ${SSL_KEY_PATH}


upgrade:
	apt-get update && apt-get -y upgrade

video:
	apt-get -y install smplayer vlc

graphic-editor:
	apt-get --yes install {shutter,libgoo-canvas-perl} inkscape pdfshuffler
	
graphic-viewer:
	apt-get --yes install okular djvulibre-bin

virtualization:
	apt-get -y install virtualbox-nonfree virtualbox-guest-utils

utils:
	apt-get update
	apt-get -y install htop tmux tree colordiff git{,k,-gui} dolphin ncdu pdfshuffler
	curl -Ls https://raw.githubusercontent.com/git/git/master/contrib/diff-highlight/diff-highlight > "$$HOME"/apps/diff-highlight


dataviz:
	apt-get -y install gdal-bin

datamining:
	npm install -g topojson xml2json-command underscore-cli #json tools
	apt-get -y install jq awk jshon visual-regexp


scanner:
	[[ ! -f ${additionRepos} ]] && touch ${additionRepos} || true
	grep "${distroUbuntu}-arakhne" ${additionRepos} \
		&& echo "deb http://download.tuxfamily.org/arakhne/ubuntu ${distroUbuntu}-arakhne universe" >> ${additionRepos}
	wget -q http://download.tuxfamily.org/arakhne/public2.key -O- | apt-key add -
	apt-get update
	apt-get -y install libsane-epson-perfection-1670

scanner-extra:
	apt-get -y tesseract-ocr{,-fra}

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

keepass:
	apt-get -y install keepass2 mono-dmcs libmono-system-management4.0-cil
	wget -c https://raw.github.com/pfn/keepasshttp/master/KeePassHttp.plgx \
		&& cp KeePassHttp.plgx /usr/lib/keepass2/plugins/
	cp "$$HOME"/.mozilla/firefox/*.default/extensions/keefox@chris.tomlinson/deps/KeePassRPC.plgx /usr/lib/keepass2/plugins/

security: keepass #ssl-certificate
	apt-get update
	apt-get -y install gnupg2 gnupg-agent kgpg ettercap-graphical

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
	apt-get install -y ipython python3{,-dev}

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

shellcheck:
	@printf "Install Shellcheck linter\n"
	apt-get -q -y install cabal-install ghc
	cabal update
	cabal install cabal-install

editor: shellcheck
	@printf "Install editors\n"
	apt-get update
	apt-get -q -y install vim vim-youcompleteme zim

core-utils:
	add-apt-repository --yes ppa:mozillateam/firefox-next
	apt-get update
	apt-get install -y git firefox zsh yakuake konsole curl

fonts:
	apt-get install fonts-noto{,-cjk} fonts-roboto

bash:
	echo

fish:
	add-apt-repository --yes ppa:fish-shell/release-2
	apt-get update
	apt-get install fish grc
	curl -sL get.fisherman.sh | fish
	fisher install pure barnybug/docker-fish-completion
	curl -L https://raw.githubusercontent.com/justinmayer/tacklebox/master/tools/install.fish | fish

zsh:
	apt-get install zsh
	curl -L http://install.ohmyz.sh | sh

shell: bash fish zsh

repo:
	add-apt-repository --yes ppa:kubuntu-ppa/backports
	apt-get update

update-rsync-exclude:
	cp {.,"$$HOME"}/.exclude.rsync;

backup: update-rsync-exclude
	apt-get -y install {g,}rsync
	update-rc.d rsync defaults
	@backupSrc="/mnt/data"; \
	backupDest="${backupDest}"; \
	backupList=( "paperwork" "projects" "server" "settings" "Sync@Home" ); \
	for backupDir in $${backupList[@]}; do \
		(crontab -u ${user} -l ; \
			echo "@daily rsync -r -t -p -o -g -v --progress --size-only -l -H --numeric-ids -s $${backupSrc}/$${backupDir} $${backupDest} --log-file \"$$HOME/rsync.log\" --exclude-from=\"$$HOME/.exclude.rsync\" "; \
		) | crontab -u ${user} - ; \
	done
	
albert-launcher:
	add-apt-repository --yes ppa:nilarimogard/webupd8
	apt-get update
	apt-get install albert	
	
zeal-doc:
	add-apt-repository --yes ppa:zeal-developers/ppa
	apt-get update
	apt-get install zeal
	
docker:
	apt-get update
	apt-get install --yes apt-transport-https ca-certificates
	apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
	echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | sudo tee /etc/apt/sources.list.d/docker.list
	apt-get update
	apt-get install docker-engine
	service docker start
	groupadd docker
	usermod -aG docker $SUDO_USER
	curl -L https://github.com/docker/compose/releases/download/1.8.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
	chmod +x /usr/local/bin/docker-compose
	
atom-editor:
	curl --location --output ~/Downloads/atom-amd64.deb https://github.com/atom/atom/releases/download/v1.11.2/atom-amd64.deb
	dpkg --install ~/Downloads/atom-amd64.deb
	
clipboard-manager:
	git clone https://github.com/CristianHenzel/ClipIt.git ~/projects/clip-it
	cd clip-it
	./autogen.sh
	./configure
	make
	make install
	
yarnpkg:
	apt-key adv --keyserver pgp.mit.edu --recv D101F7899D41F3C3
	echo "deb http://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
	apt-get update && apt-get install yarn

