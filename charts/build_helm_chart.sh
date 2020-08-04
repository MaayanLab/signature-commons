#!/usr/bin/env bash

export output=signature-commons
export version=v2

mkdir -p "${output}/${version}"

# Generate base kubernetes deployments with helm-chart-docker-compose
helm template --debug \
  helm-chart-docker-compose ./helm-chart-docker-compose/v1/ \
  -f ../docker-compose.yml \
  -f ../docker-compose.metadata-db.yml \
  -f ../docker-compose.data-db.yml \
  > "${output}/${version}/${output}.yaml.stage0"

# Generate values.yaml with .env.example
sed \
  -e 's/^\([^=]\+\)=\(.*\)$/\1: "\2"/g' \
  < ../.env.example \
  > "${output}/${version}/values.yaml"

# Generate .Values substitution with .env.example
sed \
  -e 's/^\([^=]\+\)=\(.*\)$/export \1="{{ .Values.\1 }}"/g' \
  < ../.env.example \
  > "${output}/${version}/.env"

# Substitute variables with envsubst
. ${output}/${version}/.env
export _DOLLAR='$'
sed -e 's/\$\$/${_DOLLAR}/g' \
  < "${output}/${version}/${output}.yaml.stage0" \
  > "${output}/${version}/${output}.yaml.stage1"
envsubst \
  < "${output}/${version}/${output}.yaml.stage1" \
  > "${output}/${version}/${output}.yaml.stage2"

# Replace helm-chart-docker-compose
sed \
  -e "s/helm-chart-docker-compose/${output}/g" \
  < "${output}/${version}/${output}.yaml.stage2" \
  > "${output}/${version}/${output}.yaml.stage3"

# Split file into separate files
mkdir -p "${output}/${version}/templates"
python3 -c "
import os, re
for content in map(str.strip, open(os.path.join('${output}', '${version}', '${output}.yaml.stage3'), 'r').read().split('---')):
  m = re.search('# Source!: (.+)\n', content)
  if m:
    filename = m.group(1)
    with open(os.path.join('${output}', '${version}', 'templates', os.path.basename(filename)), 'w') as fw:
      for line in content.splitlines():
        if line.startswith('#!'):
          print(line[2:], file=fw)
        else:
          print(line, file=fw)
"

# Add README
cp ../README.md "${output}/${version}/README.md"

# Clean up intermediary files
echo "Cleaning up..."
rm \
  "${output}/${version}/${output}.yaml.stage0" \
  "${output}/${version}/${output}.yaml.stage1" \
  "${output}/${version}/${output}.yaml.stage2" \
  "${output}/${version}/${output}.yaml.stage3" \
  "${output}/${version}/.env"
