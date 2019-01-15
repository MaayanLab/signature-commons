# Signature Commons: Docker Compoes

This configuration file is designed to make it easy to deploy the entire signature-commons software architecture on any cloud with docker-compose support.

It uses an nginx proxy to proxy connections from the outside world to the docker containers:
- `maayanlab/signature-commons-metadata-api`
- `maayanlab/enrichmentapi`

It can also optionally host the signature commons metadata database.

