
# Laravel Breeze based on Blade templates

This document describes how to achieve the result presented in source files.
The full list of changes is following:

- Replaced MySQL with MariaDB
- Database initialisation
- Installed [Laravel Breeze](https://laravel.com/docs/10.x/starter-kits#laravel-breeze) based on [Blade](https://laravel.com/docs/10.x/blade) templates
- Set email verification as mandatory

## Initialisation of the project

First point of [Breeze installation](https://laravel.com/docs/10.x/starter-kits#laravel-breeze-installation)
is [creating a new Laravel application](https://laravel.com/docs/10.x/installation).
We will go through this now using **Docker Desktop**. Go to the folder with your projects, for example:

```
cd ~/Projects
```

You can use any name you want for your project. I've chosen name `laravel-breeze-blade`.
Use this name in following command like this to initialise Laravel project:

```
curl -s "https://laravel.build/laravel-breeze-blade" | bash
```

It will take a few minutes. Later you can add this project to your previously created
project in GitHub. Go to the project's directory:

```
cd laravel-breeze-blade
```

Initialise Git repository, stage all files, make first commit and change
default branch from `master` to `main`. All will be done using following commands:

```
git init
git add -A
git commit -m "Fresh installation of Laravel 10."
git branch -M main
```

Associate your local repository with GitHub's repository: 

```
git remote add origin git@github.com:absoftware/laravel-breeze-blade.git
```

You can verify this with command:

```
git remove -v
```

It should give you output similar to:

```
origin	git@github.com:absoftware/laravel-breeze-blade.git (fetch)
origin	git@github.com:absoftware/laravel-breeze-blade.git (push)
```

Send changes to remote repository:

```
git push -u origin main
```

The result should be similar to the commit [88343ca](https://github.com/absoftware/laravel-breeze-blade/commit/88343ca88c7f18ced439a78532264983cb36dd50).

## Replacing MySQL with MariaDB

Default setup of Laravel comes with MySQL container defined in [docker-compose.yml](docker-compose.yml).
What if we need different database driver? The answer partially comes with [Sail customisation](https://laravel.com/docs/10.x/sail#sail-customization).
In short, there is need to do two things:

- Replace MySQL container defined in [docker-compose.yml (commit 88343ca)](https://github.com/absoftware/laravel-breeze-blade/blob/8cc55226f18c5ca06393b587e634a36e483805a9/docker-compose.yml#L31) with MariaDB container using Sail's [MariaDB stub](https://github.com/laravel/sail/blob/1.x/stubs/mariadb.stub) from [laravel/sail](https://github.com/laravel/sail) repository.
- Rebuild image for container `laravel.test` running the app to use MariaDB client instead of MySQL client.

So going after instruction from [Sail customisation](https://laravel.com/docs/10.x/sail#sail-customization) we
will try to rebuild image for `laravel.test` using command:

```
./vendor/bin/sail artisan sail:publish
```

But we get:

```
Sail is not running.

You may Sail using the following commands: './vendor/bin/sail up' or './vendor/bin/sail up -d'
```

So we are forced to run Docker containers to make changes:

```
./vendor/bin/sail up -d
```

Option `-d` is for detached mode that we could use still the same terminal.
It will take a few minutes also. When all containers are running then
we repeat customisation:

```
./vendor/bin/sail artisan sail:publish
```

Two things happened shown in commit [a8a9078](https://github.com/absoftware/laravel-breeze-blade/commit/a8a9078e89061e6c49cd0a4f8323febc868db706):

- It created [docker/](docker) directory
- And changed `context: ./vendor/laravel/sail/runtimes/8.2` into `context: ./docker/8.2` inside of [docker-compose.yml](docker-compose.yml)

We can stop containers now:

```
./vendor/bin/sail down
```

**Please remove also all volumes related to this project.** It's time to modify
image container for the application and set up totally new container for MariaDB.
All changes are shown in commit [3782481](https://github.com/absoftware/laravel-breeze-blade/commit/378248143e2758ee035db849f90a9567bc4849ae) including:

- new image name `image: sail-8.2-mariadb/app` for service `laravel.test` (requirement from [Sail customisation](https://laravel.com/docs/10.x/sail#sail-customization) article)
- removed service `mysql`
- added service `mariadb`

It's important to change host for database in `.env` file which is ignored by Git:

```
DB_HOST=mariadb
```

Later start containers once again:

```
./vendor/bin/sail up -d
```

It will rebuild container for the application based on new [Dockerfile](docker/8.2/Dockerfile),
which installs `mariadb-client` instead of `mysql-client`, and the service with MariaDB. Connect
with MariaDB to verify:

```
docker compose exec -it mariadb mysql -u sail -p"password" laravel_breeze_blade
```

List of tables should be empty:

```
SHOW TABLES;
```

Quit database shell:

```
quit
```

In general, it should work after changes summarized by commit [3782481](https://github.com/absoftware/laravel-breeze-blade/commit/378248143e2758ee035db849f90a9567bc4849ae).
**So as a result we have now running Laravel application with MariaDB database.**

## Database initialisation

First point of [Breeze installation](https://laravel.com/docs/10.x/starter-kits#laravel-breeze-installation)
is [database migration](https://laravel.com/docs/10.x/migrations#running-migrations). **In short,
we must create initial tables in database.** It's preferred to do that
from the terminal for application container in Docker Desktop for example,
or you can launch shell for this container using command:

```
docker compose exec -it laravel.test bash
```

We should land in the `/var/www/html` directory. From this place we can perform migration:

```
php artisan migrate
```

Exit the shell with:

```
exit
```

and verify if you see new tables in the database:

```
docker compose exec -it mariadb mysql -u sail -p"password" laravel_breeze_blade
```

Show tables using command:

```
SHOW TABLES;
```

Valid output will show a few tables like `migrations` or `users`. Quit database shell:

```
quit
```

No changes in source code for this section.

## Breeze installation

We will follow now the last part of [Breeze installation](https://laravel.com/docs/10.x/starter-kits#laravel-breeze-installation) guide.
Go to the application container's shell:

```
docker compose exec -it laravel.test bash
```

Install package:

```
composer require laravel/breeze --dev
```

The result is commit [d07a4ea](https://github.com/absoftware/laravel-breeze-blade/commit/d07a4ead1e74ee4d83bf2140719db1d77510c72d).
Later install [Breeze & Blade](https://laravel.com/docs/10.x/starter-kits#breeze-and-blade)
version for server side rendering, and this repository is about this particular option:

```
php artisan breeze:install blade
```

It will take a few minutes and modify our source code like in commit
[51b3fbb](https://github.com/absoftware/laravel-breeze-blade/commit/51b3fbb94883df6f922d37c12c616902b4013c6e).
And later just in case:

```
php artisan migrate
npm install
npm run dev
```

Hit `Ctrl+C` after last command. These commands change nothing for me,
but the guide mentions them. Please open in browser url
[http://localhost/login](http://localhost/login) to verify if it works.
If there is visible login form then all is fine. We get login and registration
forms almost for free.
