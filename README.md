
# Laravel Breeze based on Blade templates

This project is not a template. It just presents example Laravel project with my customisations:

- Replaced MySQL with MariaDB
- Installed [Laravel Breeze](https://laravel.com/docs/10.x/starter-kits#laravel-breeze) based on [Blade](https://laravel.com/docs/10.x/blade) templates with email verification
- Queues based on Redis and [Horizon](https://laravel.com/docs/10.x/horizon)
- It can be used with `sail up` or `vagrant up` alternatively

This document describes installation only. Initial version of tutorial for this setup
is described in [tutorial/README.md](tutorial/README.md) if you need more explanation
about some tricky details step-by-step.

## Installation based on Docker

Clone repository and go inside:

```
git clone git@github.com:absoftware/laravel-breeze-blade.git
cd laravel-breeze-blade
```

Initialize config file:

```
cp .env.local .env
```

If you have **PHP 8.2** and **Composer** installed locally:

```
composer install
```

Otherwise, please execute:

```
docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "$(pwd):/var/www/html" \
    -w /var/www/html \
    laravelsail/php82-composer:latest \
    composer install --ignore-platform-reqs
```

Start containers:

```
./vendor/bin/sail up -d
```

Install **Node.js** packages and rebuild resources:

```
./vendor/bin/sail npm install
./vendor/bin/sail npm run build
./vendor/bin/sail artisan migrate
```

What we get:

- Website at [http://localhost](http://localhost)
- Breeze's registration form at [http://localhost/register](http://localhost/register)
- Horizon with running queues at [http://localhost/horizon](http://localhost/horizon)
- Mailpit at [http://localhost:8025](http://localhost:8025)
- Configured Xdebug

Entire configuration is based on:

- [docker-compose.yml](docker-compose.yml)
- [docker/8.2](docker/8.2) created by `sail artisan sail:publish`

## Installation based on Vagrant

There is required **Vagrant** with **VirtualBox**. Firstly, edit your `/etc/hosts`:

```
192.168.56.31 breeze.vm
```

Clone repository and go inside:

```
git clone git@github.com:absoftware/laravel-breeze-blade.git
cd laravel-breeze-blade
```

The project uses [.env.vagrant](.env.vagrant) configuration by default.
It also doesn't require `composer install` and `npm install` at the beginning.
Just go to the [vagrant/](vagrant) directory:

```
cd vagrant
```

Run virtual machine:

```
vagrant up
```

If you do it first time then it will:

- install Ubuntu 22.04 LTS
- install all required packages like NGINX, PHP, etc.
- perform `composer install`
- perform `npm install && npm run build`
- create database and perform first migration

If you do it first or next time, then we get:

- Website at [http://breeze.vm](http://breeze.vm)
- Breeze's registration form at [http://breeze.vm/register](http://breeze.vm/register)
- Horizon with running queues at [http://breeze.vm/horizon](http://breeze.vm/horizon)
- Mailpit at [http://breeze.vm:8025](http://breeze.vm:8025)
- Website with `phpinfo()` at [http://192.168.56.31/phpinfo](http://192.168.56.31/phpinfo/)
- Configured Xdebug

Entire configuration is based on:

- [vagrant/Vagrantfile](vagrant/Vagrantfile)
- [provision/provision.sh](provision/provision.sh)

## Xdebug

Debugger is activated by triggers:

- for web requests use [Xdebug helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc) browser extension
- for cli commands use `export XDEBUG_SESSION=1` to activate debugger

We should create server connection for debugger in **PhpStorm** or **VSCode** with mapping:

- **Docker** with `0.0.0.0:80` (not localhost) and `/var/www/html`
- **Vagrant** with `breeze.vm:80` and `/home/vagrant/www/breeze`
