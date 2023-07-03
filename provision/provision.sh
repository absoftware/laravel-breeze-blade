#!/bin/bash

export DOLLAR='$'
export DEBIAN_FRONTEND=noninteractive

export DBHOST="%"
export DBNAME="breeze"
export DBUSER="breeze"
export DBPASS="password"

export FILES="/home/vagrant/www/breeze/provision/files"

function copy_file {
    echo "copy_file \"${1}\" \"${2}\" \"${3}\" \"${4}\""
    cp "${1}" "${2}"
    chmod "${3}" "${2}"
    chown "${4}" "${2}"
}

function install_file {
    echo "install_file \"${1}\" \"${2}\" \"${3}\""
    cp "${FILES}/${1}" "${1}"
    chmod "${2}" "${1}"
    chown "${3}" "${1}"
}

update_apt_get() {
    echo "Updating apt-get"
    apt-get -y update
    apt-get -y upgrade
    apt-get install -y build-essential
    apt-get install -y net-tools
}

install_emacs() {
    echo "Installing Emacs"
    apt-get -y install emacs
    install_file /home/vagrant/.emacs 644 vagrant:vagrant
    install_file /root/.emacs 644 root:root
}

install_time_sync() {
    apt-get -y install ntp
    timedatectl set-ntp on
}

set_hostname() {
    echo "Copying hostname configuration"
    install_file /etc/hostname 644 root:root
}

install_git() {
    echo "Installing Git"
    apt-get -y install git gitk ruby
    install_file /home/vagrant/.bash_profile 644 vagrant:vagrant
    install_file /root/.bash_profile 644 root:root
}

install_mysql() {
    echo "Installing MySQL"
    apt-get install -q -y mariadb-server mariadb-client
    service mysql restart

    echo "Loading timezones into MySQL"
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

    echo "Open external connections"
    sed -i 's/= 127.0.0.1/= 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

    echo "Restarting MySQL service"
    service mysql restart
}

install_nginx() {
    echo "Installing NGINX"
    apt-get install -y nginx
    sed -i 's/sendfile on/sendfile off/g' /etc/nginx/nginx.conf

    echo "Associating sudo-user to www-data"
    gpasswd -a vagrant www-data
    gpasswd -a www-data vagrant
    service nginx restart
}

install_php() {
    echo "Installing PHP"
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt-get update -y
    apt-get install -y php8.2-fpm php8.2-cli php8.2-dev \
           php8.2-pgsql php8.2-sqlite3 php8.2-gd php8.2-imagick php8.2-curl \
           php8.2-imap php8.2-mysql php8.2-mbstring \
           php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap \
           php8.2-intl php8.2-readline php8.2-ldap \
           php8.2-msgpack php8.2-igbinary php8.2-redis php8.2-swoole \
           php8.2-memcached php8.2-pcov php8.2-xdebug

    echo "Installing mcrypt"
    pecl install mcrypt

    echo "Install PHP config"
    install_file /etc/php/8.2/mods-available/mcrypt.ini 644 root:root
    install_file /etc/php/8.2/mods-available/xdebug.ini 644 root:root
    service php8.2-fpm restart
}

default_website_configuration() {
    echo "Copying PHPINFO website"
    cp -r "${FILES}/var/www/html/phpinfo" /var/www/html
    chmod 755 /var/www/html/phpinfo
    chmod 644 /var/www/html/phpinfo/index.php
    chown -R root:root /var/www/html/phpinfo
    install_file /etc/nginx/sites-available/default 644 root:root
    service nginx restart
    service php8.2-fpm restart
}

install_composer() {
    echo "Installing composer"
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
}

install_supervisor() {
    echo "Installing Supervisor"
    apt-get -y install supervisor
}

install_dependencies() {
    apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils librsvg2-bin
}

install_node() {
    echo "Installing Node.js and NPM"
    curl -sLS https://deb.nodesource.com/setup_18.x | bash - \
        && apt-get install -y nodejs \
        && npm install -g npm \
        && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
        && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
        && apt-get update \
        && apt-get install -y yarn
}

install_redis() {
    echo "Installing Redis"
    apt-get install -y redis-server
    sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
    systemctl restart redis.service
}

install_mailpit() {
    echo "Installing Mailpit"
    bash < <(curl -sL https://raw.githubusercontent.com/axllent/mailpit/develop/install.sh)
}

breeze_environment() {
    # Setting up environment variable
    echo 'APP_ENV="vagrant"' >> /etc/environment
}

breeze_nginx_configuration() {
    echo "Web server configuration"
    install_file /etc/nginx/sites-available/breeze.conf 644 root:root
    ln -s /etc/nginx/sites-available/breeze.conf /etc/nginx/sites-enabled/
    service nginx restart
    service php8.2-fpm restart
}

breeze_database_create() {
    echo "Creating database"
    mysql -u root -e "CREATE DATABASE ${DBNAME}"
    mysql -u root -e "GRANT ALL ON ${DBNAME}.* TO '${DBUSER}'@'${DBHOST}' IDENTIFIED BY '${DBPASS}'"

    echo "Migrating database"
    cd /home/vagrant/www/breeze || return
    su - vagrant -s /bin/bash -c 'php artisan migrate'
    cd || return
}

echo "Provisioning virtual machine..."
update_apt_get
install_emacs
install_time_sync
set_hostname
install_git
install_mysql
install_nginx
install_php
default_website_configuration
install_composer
install_supervisor
install_dependencies
install_node
install_redis
install_mailpit

echo "Configuring Breeze website"
breeze_environment
breeze_nginx_configuration
breeze_database_create
