# TheDeadPoetSociety.github.io

This is the website and blog for the organisation.

## Local changes

This project has been wrapped in a Dockerfile so that we dont have to install Ruby locally.

The following commands will build the utility container and then mount the current working directory
into the continers `/srv/jekyll` folder so that code changes are reflected instantly.

```bash
docker-compose build
docker-compose up
```