import json
import os.path
import sys
import re
import urllib.request

def fetch(endpoint, method='GET', data={}, headers={}):
  ''' Helper method for fetching from json APIs with urllib
  '''
  if method == 'GET':
    req = urllib.request.Request(
      endpoint + '?' + urllib.parse.urlencode(data),
      method='GET',
      headers=dict({
        'Content-Type': 'application/json',
      }, **headers),
    )
  elif method == 'POST':
    req = urllib.request.Request(
      endpoint,
      method='POST',
      headers=dict({
        'Content-Type': 'application/json',
      }, **headers),
      data=json.dumps(data).encode(),
    )
  res = urllib.request.urlopen(req)
  return json.load(res)


def data_api_load(bucket=None, file=None, datasetname=None, token=None, data_uri='http://localhost:8080/enrichmentAPI'):
  ''' Normal version data load
  @param bucket: string       The bucket to access
  @param file: string         The file in the bucket
  @param datasetname?: string The datasetname to use on the API (defaults to filename)
  @param token: string        The secret token used for API authorization
  @param data_uri: string     The base uri to access the data api
  '''
  assert type(bucket) == str
  assert type(file) == str
  assert type(datasetname) == str or datasetname is None
  assert type(token) == str
  assert type(data_uri) == str
  return fetch(data_uri + '/api/v1/load',
    method='POST',
    headers={
      'Authorization': 'Token {}'.format(token)
    },
    data={
      'bucket': bucket,
      'file': file,
      'datasetname': datasetname or file,
    }
  )


def data_api_downloadSo(datasetType=None, fileName=None, name=None, token=None, data_uri='http://localhost:8080/enrichmentAPI'):
  ''' ignite version mechanism to load file

  @param datasetType: string  The type (`geneset_library` or `rank_matrix`)
  @param fileName: string     The application-accessible file path to the so object
  @param name?: string        The identifier to used for the file
  @param token: string        The secret token used to authenticate with the api
  @param data_uri: string     The base uri to access the data api
  '''
  assert type(datasetType) == str
  assert type(fileName) == str
  assert type(name) == str or name is None
  assert type(token) == str
  assert type(data_uri) == str
  return fetch(data_uri + '/api/v1/download-so',
    method='POST',
    data={
      'datasetType': datasetType,
      'fileName': fileName,
      'name': name or os.path.basename(fileName),
    }
  )


def data_api_list_data(data_uri='http://localhost:8080/enrichmentAPI'):
  ''' List available data files in data-api
  @param data_uri: string     The base uri to access the data api
  '''
  assert type(data_uri) == str
  return fetch(data_uri + '/api/v1/listdata',
    method='GET',
  )

if __name__ == '__main__':
  import simple_commandify; simple_commandify.inject_unsafe(globals())
