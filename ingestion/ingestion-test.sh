#!/bin/sh

META_URI=http://signaturestore:signaturestore@localhost/signature-commons-metadata-api/
DATA_URI=http://_:SECRET@localhost/enrichmentapi/origin/api/v1
REPOSITORY_ID=12345

# Create library in metadata API
LIBRARY=$(
  python swagger_client.py meta ${META_URI} Library_find_or_create -- body=- << EOF
[{
  "dataset": "${REPOSITORY_ID}",
  "meta": {
    "\$validator": "/@dcic/signature-commons-schema/core/unknown.json",
    "name": "My first library"
  }
}]
EOF
)
echo "${LIBRARY}"

LIBRARY_ID=$(echo "${LIBRARY}" | python -c 'import sys, json; print(json.load(sys.stdin)[0]["id"])')

# Ingest data into metadata API
python ingest_rank_matrix.py \
  -vvv \
  --meta "${META_URI}" \
  --data "${DATA_URI}" \
  --onerror resolve \
  ${REPOSITORY_ID} \
  ${LIBRARY_ID} \
  test.csv