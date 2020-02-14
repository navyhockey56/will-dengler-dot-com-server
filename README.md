# Will Dengler Server
The Server is reponsible for hosting the RESTful API for the project.

## Environment Setup
The Server needs to connect with Postgresql, as such, the following variables are required:
- `POSTGRESQL_DB_NAME` The name of the database to connect to
- `POSTGRESQL_USERNAME` The user to connect to the database with
- `POSTGRESQL_USER_PASSWORD` The user's password

The Server also supports the following optional environment variables:
- `LOG_TO` The name file to log to

All variables can be loaded via a `.env` file located in the root directory of this project.

## Running the Server
### Local running
To run the server, execute the server script in the `bin/` directory:
```bash
bundle exec bin/server
```

### Running on a Droplet
#### Will Dengler Server as a Service
There is a service script `willdengler_server` in the `init.d\` directory. This file should be copied over to the `/etc/init.d/` directory and loaded with default settings:
```bash
cp init.d/willdengler_server /etc/init.d/
update-rc.d willdengler_server defaults
```
You should then be able to start/stop/restart/etc this project as a service:
```bash
service willdengler_server start
service willdengler_server stop
service willdengler_server restart
service willdengler_server status
```

If you update the service script, then you will need to perform the following to get a proper reload:
```bash
service willdengler_server stop
systemctl daemon-reload
service willdengler_server start
```

#### Exposure through NGINX
If you want to expose this project through NGINX, the proper configuration file can be found with the `nginx/` directory. If you do not already have nginx installed, you can install it with:
```bash
apt-get install nginx
```

Once you have nginx on your droplet, copy the `willdengler_server` config file to the ngnix sites-available directory, then make a symbolic link to it in the sites-enabled folder, then restart nginx:
```bash
cp nginx/willdengler_server /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/willdengler_server /etc/nginx/sites-enabled/willdengler_server
service nginx restart
```
The server should now be accessible over port `4567` via your droplet's IP.
