#!/bin/sh

echo "Connecting to s3..."
mc config host add minio ${S3_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}

$@
