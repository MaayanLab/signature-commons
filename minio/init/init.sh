#!/bin/sh

if [ ! -f initialized ]; then
  echo "Initializing s3..."
  touch initialized
  mc mb minio/${S3_BUCKET}
else
  echo "s3 is already initialized.. quitting."
fi
