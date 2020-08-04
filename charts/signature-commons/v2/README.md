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
Many aspects of the application can be configured via environment variables--copy `.env.example` to `.env` and modify as needed.


## Refreshing APIs
Metadata DB: Trigger the API to refresh the cached views/indecies
```bash
docker-compose exec metadata-api /bin/bash -c "npx typeorm migration:revert && npx typeorm migration:run"
```

Data DB: Trigger the API to load the desired data.
```bash
# The variables here should be replaced with .env settings, `file` should be set with the file used during ingestion.
curl -H 'Content-Type: application/json' -H "Authorization: Token ${TOKEN}" -X POST 'http://localhost/enrichmentapi/api/v1/load' -d "{\"bucket\": \"${AWS_BUCKET}\", \"file\": \"${file}.so\", \"datasetname\": \"${file}\"}'
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
