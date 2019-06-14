#!/bin/env python3

import json
import ingest_rank_matrix
import swagger_client
import os.path

if __name__ == '__main__':
  # API endpoints
  meta_uri='http://signaturestore:signaturestore@localhost/signature-commons-metadata-api/'
  data_uri='http://_:signaturestore@localhost/enrichmentapi/origin/api/v1'

  # Metadata validators
  library_validator = '/@dcic/signature-commons-schema/core/unknown.json'
  signature_validator = '/@dcic/signature-commons-schema/core/unknown.json'
  entity_validator = '/@dcic/signature-commons-schema/core/unknown.json'

  # directory where everything is (file_descriptions and files)
  data_dir = 'data'

  # A file of the form:
  '''
  \tMy\tArbitrary\tMeta\n
  myfile.csv\tmy\tarbitrary\tentry\n
  ...
  '''
  # Each file will be added as a library with the given metadata (excluding the first col)
  desc_file = 'file_descriptions.tsv'

  # Load desc_file
  desc_fh = open(os.path.join(data_dir, desc_file), 'r')
  # Parse header
  header = next(iter(desc_fh)).split('\t')
  header.pop(0) # ignore first col

  # Setup clients
  meta_client = swagger_client.get_meta_client(meta_uri)
  data_client = swagger_client.get_data_client(data_uri)

  for line in desc_fh:
    line_split = line.split('\t')
    file = line_split.pop(0)
    library_meta = dict(zip(header, line_split))

    repository_id = name
    library = meta_client.actions.Library_find_or_create.call(body=[{
      "dataset": repository_id,
      "dataset_type": "rank_matrix",
      "meta": dict({
          "$validator": library_validator,
        }, **library_meta
      ),
    }])
    library_id = library[0]['id']
    print('processing {}...'.format(name))
    ingest_rank_matrix.ingestion(
      [open(os.path.join(data_dir, file), 'r')],
      transpose=True,
      repository_id=repository_id,
      library_id=library_id,
      meta_client=meta_client,
      data_client=data_client,
      signature_validator=signature_validator,
      entity_validator=entity_validator,
      onerror='resolve',
      verbose=3,
    )
