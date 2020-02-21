#!/usr/bin/env bash

export output=signature-commons

mkdir -p "${output}"

# Generate base kubernetes deployment with helm-chart-docker-compose
helm template --debug \
  helm-chart-docker-compose ./helm-chart-docker-compose/ \
  -f ../docker-compose.yml \
  -f ../docker-compose.metadata-db.yml \
  -f ../docker-compose.data-db.yml \
  > "${output}/${output}.yaml.stage0"

# Generate values.yaml with .env.example
sed \
  -e 's/^\([^=]\+\)=\(.*\)$/\1: \2/g' \
  < ../.env.example \
  > "${output}/Values.yaml"

# Generate .Values substitution with .env.example
sed \
  -e 's/^\([^=]\+\)=\(.*\)$/export \1="{{ .Values.\1 }}"/g' \
  < ../.env.example \
  > "${output}/.env"

# Substitute variables with envsubst
. ${output}/.env
export _DOLLAR='$'
sed -e 's/\$\$/${_DOLLAR}/g' \
  < "${output}/${output}.yaml.stage0" \
  > "${output}/${output}.yaml.stage1"
envsubst \
  < "${output}/${output}.yaml.stage1" \
  > "${output}/${output}.yaml.stage2"

# Replace helm-chart-docker-compose
sed \
  -e "s/helm-chart-docker-compose/${output}/g" \
  < "${output}/${output}.yaml.stage2" \
  > "${output}/${output}.yaml.stage3"

# Split file into separate files
mkdir -p "${output}/templates"
python3 -c "
import os, re
for content in map(str.strip, open(os.path.join('${output}', '${output}.yaml.stage3'), 'r').read().split('---')):
  m = re.search('# Source: (.+)\n', content)
  if m:
    filename = m.group(1)
    print(content, file=open(os.path.join('${output}', 'templates', os.path.basename(filename)), 'w'))
"

# Clean up intermediary files
echo "Cleaning up..."
rm \
  "${output}/${output}.yaml.stage0" \
  "${output}/${output}.yaml.stage1" \
  "${output}/${output}.yaml.stage2" \
  "${output}/${output}.yaml.stage3" \
  "${output}/.env"
