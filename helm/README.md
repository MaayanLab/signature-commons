# Helm package

We construct a helm deployment from `docker-compose.*.yml`/`.env.example`.

## Installation

```bash
helm plugin install --version master https://github.com/sagansystems/helm-github.git
helm github install \
  --repo https://github.com/MaayanLab/signature-commons.git \
  --ref env-refactor --path helm/signature-commons \
  --namespace signature-commons --generate-name \
  -f signature-commons/Values.yaml
```
