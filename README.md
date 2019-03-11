# Signature Commons: Docker Compose

This configuration file is designed to make it easy to deploy the entire signature-commons software architecture on any cloud with docker-compose support.

It uses an nginx proxy to proxy connections from the outside world to the docker containers:
- `maayanlab/signature-commons-metadata-api`
- `maayanlab/enrichmentapi`

It can also optionally host the signature commons metadata database.

## .env

The docker-compose.yml file is annotated with the relevant environment variables which are necessary--but here is the skeleton of a `.env` file.

```conf
ADMIN_PASSWORD=signaturestore
ADMIN_USERNAME=signaturestore
POSTGRES_PASSWORD=signaturestore
POSTGRES_USER=signaturestore
POSTGRESQL_URL=postgresql://signaturestore:signaturestore@metadata-db:5432/signaturestore
token=signaturestore
AWS_ACCESS_KEY_ID=12345
AWS_SECRET_ACCESS_KEY=12345/54321/12345
aws_bucket=signaturestore
```
