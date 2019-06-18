# Signature Commons: Docker Compose

This configuration file is designed to make it easy to deploy the entire signature-commons software architecture on any cloud with docker-compose support.

It uses an nginx proxy to proxy connections from the outside world to the docker containers:
- `maayanlab/signature-commons-metadata-api`
- `maayanlab/enrichmentapi`

It can also optionally host the signature commons metadata database.

## Using this repo
This is a mono-repo for all of the signature commons applications. It uses `git submodules` to organize the separate repositories into one and `lerna` for linking together javascript related dependencies. Cloning the repository and all the submodules can be done with:

```bash
git clone --recurse-submodules git@github.com:dcic/signature-commons.git
```

If you already have it cloned, you can get all the submodules with:
```bash
git submodule update --init --recursive
```

## .env

The docker-compose.yml file is annotated with the relevant environment variables which are necessary--but here is the skeleton of a `.env` file.

```conf
ADMIN_PASSWORD=signaturestore
ADMIN_USERNAME=signaturestore
POSTGRES_USER=signaturestore
POSTGRES_PASSWORD=signaturestore
TYPEORM_CONNECTION=postgres
TYPEORM_URL=postgresql://signaturestore:signaturestore@metadata-db:5432/signaturestore
TYPEORM_SYNCHRONIZE=true
TYPEORM_MIGRATIONS_RUN=true
TYPEORM_ENTITIES=dist/src/entities/*.js
TYPEORM_MIGRATIONS=dist/src/migration/*.js
TYPEORM_SUBSCRIBERS=dist/src/subscriber/*.js
token=yourtoken
AWS_ACCESS_KEY_ID=yourawsaccesskey
AWS_SECRET_ACCESS_KEY=yourawssecret
aws_bucket=yourbucket
```

## Refreshing materialized views and indecies
You may need to refresh the db cached views/indecies after adding new data. You can do so with:

```bash
docker-compose exec metadata-api /bin/bash -c "npx typeorm migration:revert && npx typeorm migration:run"
```

## Performing ingestion

```bash
# Setup virtualenv
python3 -m venv venv
source venv/bin/activate

cd ingestion
pip install -r requirements.txt
python ingest.py
```
