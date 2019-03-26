#!/usr/bin/env python3

import re
import sys
import uuid
import numpy as np
import json
from swagger_client import get_meta_client, get_data_client

def chunk(iterable, size):
  ''' Chunk an iterable by some size (size)
  e.g. chunk(range(10), 2) == gen(gen(0, 1), gen(1, 2), ...)
  '''
  from itertools import chain, islice
  iterator = iter(iterable)
  for first in iterator:
    yield chain([first], islice(iterator, size - 1))

def count_first_na(L):
  ''' Count the number of na's that this list starts with
  '''
  for n, l in enumerate(L):
    if l not in [float('NaN'), 'NaN', 'nan', '']:
      return n
  return 0

def parse_line(line):
  ''' Single line parser
  '''
  return np.array(re.split('[\t,]', re.sub(r'[\r\n]+$', '', line)))

def transpose_lines(stream):
  ''' Parse and transpose a stream of lines
  '''
  lines = []
  for line in stream:
    lines.append(parse_line(line))
  return np.array(lines).T

def parse_lines(stream, preparsed=False, repository_id=None, library_id=None, meta_client=None, data_client=None, chunks=100, onerror='resolve', verbose=0):
  ''' Streaming parser for the format; sends data to the necessary APIs
  '''
  # We need to parse the top header into memory to construct the entities
  stream = iter(stream)
  cur_na = 0
  header = []
  for line in stream:
    # Ignore empty starting lines
    if not preparsed and line.strip() == '':
      continue
    parsed_line = line if preparsed else parse_line(line)
    header.append(parsed_line)
    n_na = count_first_na(parsed_line)
    if n_na == 0:
      break
    cur_na = n_na
  # 2d header array
  header = np.array(header)
  # Locate the column, row, and file borders
  border_c = cur_na
  border_r = header.shape[0] - 1
  n_cols = header.shape[1]
  # Obtain the header labels
  header_c = header[:border_r, border_c]
  header_r = header[border_r, :border_c]
  # Construct entities with the header
  entity_ids = []
  in_entities = [
    {
      'meta': dict(zip(header_c, header[:border_r, c]), **{
        '$validator': '/@dcic/signature-commons-schema/core/unknown.json'
      })
    }
    for c in range(border_c + 1, n_cols)
  ]
  # until we've processed all entities
  while in_entities != []:
    next_entities = in_entities
    in_entities = []
    # Register entities with the API in chunks
    for entities in map(list, chunk(next_entities, chunks)):
      # perform API registration
      out_entities = meta_client.actions.Entity_find_or_create.call(body=entities)
      if type(out_entities) != list:
        raise Exception(out_entities)
      for in_entity, out_entity in zip(entities, out_entities):
        if verbose > 1:
          print('meta[Entity].find_or_create[i] >', in_entity)
          print('< ', out_entity)
        # Did we get back an entity?
        if out_entity.get('id'):
          entity_ids.append(out_entity['id'])
        # was this a force create or are we interrupting on error?
        elif in_entity.get('id') or onerror == 'interrupt':
          raise Exception(out_entity)
        # Force create? generate an id and re-submit
        elif onerror == 'force':
          in_entities.append(dict(in_entity, id=uuid.uuid4()))
        # Manual resolution
        elif onerror == 'resolve':
          print('Input:', in_entity, '\n',
                'Output:', out_entity, '\n',
                'Resolution? [C]reate | [I]nterrupt | [actual uuid]')
          # Capture user input (ignore empty input)
          inp = input()
          while inp == '':
            inp = input()
          # Process user-submitted resolution
          if inp.lower() == 'c':
            in_entities.append(dict(in_entity, id=uuid.uuid4()))
          elif inp.lower() == 'i':
            raise Exception(out_entity)
          else:
            in_entities.append(dict(in_entity, id=inp))

  # Check for duplicate resolution
  if len(entity_ids) != len(set(entity_ids)):
    if onerror == 'interrupt':
      raise Exception('WARN: Some entities resolved to the same entity!')
    elif onerror == 'resolve':
      print('WARN: Some entities resolved to the same entity, proceed anyway? [Y/n]', file=sys.stderr)
      if input() == 'n':
        raise Exception('WARN: Some entities resolved to the same entity!')
    elif onerror == 'force':
      print('WARN: Some entities resolved to the same entity, continuing anyway.', file=sys.stderr)

  # Create repository in data API
  req = {
    'repository_uuid': repository_id,
    'entities': entity_ids,
    'data_type': 'rank_matrix',
  }
  resp = data_client.actions.create.call(body=req)
  if verbose > 1:
    print('data[Repository].create >', req)
    print('<', resp)

  # Stream through rest of the file creating (signatures, entities) pairs
  def _generate():
    for r, line in enumerate(stream, border_r + 1):
      # Ignore empty lines
      if not preparsed and line.strip() == '':
        continue
      parsed_line = line if preparsed else parse_line(line)
      # Get metadata
      meta = dict(zip(header_r, parsed_line[:border_c + 1]), **{
        '$validator': '/@dcic/signature-commons-schema/core/unknown.json'
      })
      entities = [
        (entity, parsed_line[c],)
        for c, entity in zip(range(border_c + 1, n_cols), entity_ids)
      ]
      # Generate signature id
      signature_id = str(
        # uuid5 is a sha-1 hash namespace of a namespace and a name
        uuid.uuid5(
          uuid.UUID(library_id),
          json.dumps([
            meta,
            entities,
          ])
        )
      )
      # Generate pairs
      yield (
        {
          'id': signature_id,
          'library': library_id,
          'meta': meta,
        },
        (signature_id, entities),
      )
  
  # Go through results in chunks
  for meta_data_chunk in chunk(_generate(), chunks):
    meta_chunk, data_chunk = zip(*meta_data_chunk)
    # send chunk of signatures to metadata API
    out_signatures = meta_client.actions.Signature_find_or_create.call(body=meta_chunk)
    for in_signature, out_signature in zip(meta_chunk, out_signatures):
      if verbose > 1:
        print('meta[Signature].find_or_create[i] >', in_signature)
        print('< ', out_signature)
      if out_signature.get('id'):
        pass
      elif onerror == 'interrupt':
        raise Exception(out_signature)
      # Force create? generate an id and re-submit
      elif onerror == 'force':
        continue
      # Manual resolution
      elif onerror == 'resolve':
        print('Input:', in_signature, '\n',
              'Output:', out_signature, '\n',
              'Resolution? [P]ass | [I]nterrupt')
        # Capture user input (ignore empty input)
        inp = input()
        while inp == '':
          inp = input()
        # Process user-submitted resolution
        if inp.lower() == 'p':
          continue
        elif inp.lower() == 'i':
          raise Exception(out_entity)
        else:
          continue

    # send chunk of signatures to data API
    data_client_req = {
      'repository_uuid': repository_id,
      'signatures': [
        {
          'uuid': signature_id,
          'entity_values': [float(entity[1]) for entity in entity_values],
        }
        for signature_id, entity_values in data_chunk
      ],
    }
    data_client_resp = data_client.actions.append.call(body=data_client_req)
    if verbose > 1:
        print('data[Signature].append >', data_client_req)
        print('< ', data_client_resp)

  # Persist repository in data API
  req = {
    'repository_uuid': repository_id,
  }
  resp = data_client.actions.persist.call(body=req)
  if verbose > 1:
    print('data[Repository].persist >', req)
    print('<', resp)

def pair_to_tsv(pair):
  ''' Convert a (signature, ((entity, weight), (entity, weight), ...)) to tsv
  '''
  id, values = pair
  return '\t'.join([
    id,
    ' '.join(
      ','.join([
        value,
        weight
      ])
      for value, weight in values
    )
  ])

def ingestion(files=[sys.stdin], transpose=False, repository_id=None, library_id=None, meta_client=None, data_client=None, chunks=100, onerror='resolve', verbose=0):
  for n, fh in enumerate(files):
    if args.verbose > 0:
      print('processing file {n}...'.format(n=n), file=sys.stderr)
    parse_lines(
      transpose_lines(fh) if transpose else fh,
      preparsed=transpose,
      repository_id=repository_id,
      library_id=library_id,
      meta_client=meta_client,
      data_client=data_client,
      chunks=chunks,
      onerror=onerror,
      verbose=verbose,
    )

if __name__ == '__main__':
  import argparse
  parser = argparse.ArgumentParser(
    description='''Ingest data into Signature Commons.
Takes data from stdin in the form (comma or tab delimited):
\t\tCol\tC1L1\tC2L1\t...
\t\tLabels\tC1L2\tC2L2\t...
\t\t : \t : \t : \t...
Row\tLabels\t...\t\t
R1L1\tR1L2\t...\t0.5\t1.0\t...
R2L1\tR2L2\t...\t1.0\t0.5\t...
 : \t : \t : \t : \t : \t...

Where Columns are treated as entities (the individual aspects being measured, e.g. genes for gene expression)
and Rows are treated as signatures (the label of that set of measurements, e.g. drug perturbation)

The -t flag lets you transpose this so that entities are on the rows and measurements on the columns--note
however that this format does not support stream processing (so it should fit in memory).
''',
    formatter_class=argparse.RawTextHelpFormatter
  )
  parser.add_argument('repository',
                      help='repository to associate signatures with (uuid)')
  parser.add_argument('library',
                      help='library to associate signatures with (uuid)')
  parser.add_argument('files', nargs='*',
                      default=['-'],
                      help='signature file(s) to process (`-` for stdin)')
  parser.add_argument('-v', '--verbose', action='count', default=0,
                      help='increase output verbosity')
  parser.add_argument('-t', '--transpose', action='store_true', default=False,
                      help='transpose input to have genes on the row labels and signature definitions on the column labels')
  parser.add_argument('--meta', required=True, metavar='URI',
                      help='base meta uri (e.g. https://admin:admin@amp.pharm.mssm.edu/signature-commons-metadata-api/)')
  parser.add_argument('--data', required=True, metavar='URI',
                      help='base data uri (e.g. https://_:01-token-10@amp.pharm.mssm.edu/enrichmentAPI/)')
  parser.add_argument('--chunks', metavar='N', default=100,
                      help='max number of operations to pool together for bulk insertion')
  parser.add_argument('--onerror', default='resolve',
                      choices=['interrupt', 'resolve', 'force'],
                      help='what to do when an error is received from remote')
  args = parser.parse_args()

  ingestion(
    repository_id=args.repository,
    library_id=args.library,
    files=[
      sys.stdin if file == '-' else open(file, 'r')
      for file in args.files
    ],
    transpose=args.transpose,
    meta_client=get_meta_client(args.meta, verbose=args.verbose),
    data_client=get_data_client(args.data, verbose=args.verbose),
    onerror=args.onerror,
    chunks=args.chunks,
    verbose=args.verbose,
  )
