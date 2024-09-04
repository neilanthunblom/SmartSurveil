# Install Shinobi with Docker
#### 2024-05-07

# Quick Install

1. Run this in terminal.
```
bash <(curl -s https://gitlab.com/Shinobi-Systems/Shinobi-Installer/raw/master/shinobi-docker.sh)
```

# Advanced Install

1. Download this repository and enter it.
    - If you **do not have Docker** installed run `sh INSTALL/docker.sh`.
2. Review and modify the `docker-compose.yml` file.
    - Leave it as-is for default setup.
3. Run the preparation and starter script.
    ```
    bash setup_and_run.sh
    ```

# Once Installed

You will be asked if you want to use the included database, default is Yes. Once complete open port 8080 of your Docker host in a web browser.

> The following tables offer a breakdown of the configurations that control how the `shinobi` and `shinobi-sql` services are set up and interact within your Docker environment. Adjustments can be made to these values directly in the `docker-compose.yml` file to modify the behavior of the deployment as needed.

### `docker-compose.yml` : `shinobi-sql` Service Environment Variables

| Variable             | Description                                          | Default Value    |
|----------------------|------------------------------------------------------|------------------|
| MYSQL_ROOT_PASSWORD  | The password for the MySQL root user.                | `rootpassword`   |
| MYSQL_DATABASE       | The name of the database to create.                  | `ccio`           |
| MYSQL_USER           | The username for the database.                       | `majesticflame`  |
| MYSQL_PASSWORD       | The password for the database user.                  | `1234`           |

### `docker-compose.yml` : `shinobi` Service Build Arguments and Environment Variables

#### Build Arguments

| Argument          | Description                                               | Default Value |
|-------------------|-----------------------------------------------------------|---------------|
| SHINOBI_BRANCH    | The branch of the Shinobi git repository to clone during the build process. | `dev`         |

#### Environment Variables

| Variable          | Description                                          | Default Value |
|-------------------|------------------------------------------------------|---------------|
| HOME              | The home directory path within the container.        | `/home/Shinobi` |
| DB_HOST           | Hostname of the MySQL database server.               | `shinobi-sql`   |
| DB_USER           | Username to connect to the MySQL database.           | `majesticflame` |
| DB_PASSWORD       | Password to connect to the MySQL database.           | `1234`          |
| DB_DATABASE       | Name of the MySQL database to use.                   | `ccio`          |
| SHINOBI_UPDATE    | Whether to pull updates from git when the container starts. | `false`      |


**Script Failing? Run this.**

```
apt install dos2unix -y && dos2unix entrypoint.sh && chmod +x entrypoint.sh && dos2unix setup_and_run.sh && chmod +x setup_and_run.sh && bash setup_and_run.sh
```
