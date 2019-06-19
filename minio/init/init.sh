#!/bin/sh

if [ ! -f initialized ]; then
  echo "Initializing s3..."
  touch initialized
  mc mb minio/${S3_BUCKET}
else
  echo "s3 is already initialized.. triggering data load(s)"
  for f in $(mc ls minio/${S3_BUCKET} | awk '{ print $5 }'); do
    if 
    curl \
      -H 'Content-Type: application/json' \
      -H "Authorization: Token ${TOKEN}" \
      -X POST 'http://data-api/enrichmentapi/api/v1/load' \
      -d "{\"bucket\": \"${BUCKET}\", \"file\": \"${f}\", \"datasetname\": \"$(basename ${f} .so)}\"}"
  done
fi
