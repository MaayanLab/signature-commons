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

# Replace variables with .Values
sed \
  -e 's/\${\([^}]\+\)}/{{ .Values.\1 }}/g' \
  -e "s/helm-chart-docker-compose/${output}/g" \
  > "${output}/${output}.yaml.stage1" \
  < "${output}/${output}.yaml.stage0"

# Generate values.yaml with .env.example
sed \
  -e 's/^\([^=]\+\)=\(.*\)$/\1: \2/g' \
  > "${output}/Values.yaml" \
  < ../.env.example

# Split file into separate files
mkdir -p "${output}/templates"
python3 -c "
import os, re
for content in map(str.strip, open(os.path.join('${output}', '${output}.yaml.stage1'), 'r').read().split('---')):
  m = re.search('# Source: (.+)\n', content)
  if m:
    filename = m.group(1)
    print(content, file=open(os.path.join('${output}', 'templates', os.path.basename(filename)), 'w'))
"

# Clean up intermediary files
echo "Cleaning up..."
rm \
  "${output}/${output}.yaml.stage0" \
  "${output}/${output}.yaml.stage1"
