import sys
import json

def get_meta_client(uri, verbose=0):
  ''' Obtain an authenticated swagger client with some base uri with basic credentials.
  e.g client = get_meta_client('https://your_user:your_pass@your_host/base_url/')
      client.actions.[ pyswagger actions ]
  '''
  import base64
  from urllib.parse import urlparse
  from pyswaggerclient import SwaggerClient

  parsed = urlparse(uri)
  credential = base64.b64encode('{username}:{password}'.format(
    username=parsed.username, password=parsed.password
  ).encode()).decode()
  base_url = '{scheme}://{host}{port}/{path}'.format(
    scheme=parsed.scheme,
    host=parsed.hostname,
    path=parsed.path.strip('/'),
    port=':{port}'.format(port=parsed.port) if parsed.port else ''
  )
  if verbose > 1:
    print('connecting to {base_url}/openapi.json'.format(base_url=base_url), file=sys.stderr)
  client = SwaggerClient(
    '{base_url}/openapi.json'.format(base_url=base_url),
    headers={
      'Authorization': 'Basic {credential}'.format(credential=credential)
    }
  )
  return client

def get_data_client(uri, verbose=0):
  ''' Obtain an authenticated swagger client with some base uri with token where the password would normally be.
  e.g client = get_data_client('https://_:your_token@your_host/base_url/')
      client.actions.[ pyswagger actions ]
  
  Note: Currently we build a client which behaves like the pyswagger client will behave.
  '''
  import urllib.request
  import json
  from urllib.parse import urlparse

  class DataClient:
    def __init__(self, base_url=None, token=None):
      self.base_url = base_url
      self.token = token

      class actions:
        pass
      actions.append = self._request('append')
      actions.create = self._request('create')
      actions.listrepositories = self._request('listrepositories')
      actions.persist = self._request('persist')
      actions.removerepository = self._request('removerepository')
      actions.removesamples = self._request('removesamples')
      self.actions = actions

    def _request(self, endpoint):
      class _wrap:
        pass
      def _wrap_call(body={}):
        params = json.dumps(body).encode('utf8')
        if verbose >= 1:
          print('> {base_url}/{endpoint}'.format(
            base_url=self.base_url,
            endpoint=endpoint,
          ), file=sys.stderr)
        req = urllib.request.Request(
          '{base_url}/{endpoint}'.format(
            base_url=self.base_url,
            endpoint=endpoint,
          ),
          data=params,
          headers={
            'Content-Type': 'application/json',
            'Authorization': 'Token {token}'.format(token=self.token),
          },
        )
        resp = urllib.request.urlopen(req)
        return resp.read().decode('utf8')
      _wrap.call = _wrap_call
      return _wrap

  parsed = urlparse(uri)
  base_url = '{scheme}://{host}/{path}'.format(
    scheme=parsed.scheme,
    host=parsed.hostname,
    path=parsed.path.strip('/'),
  )
  if verbose > 1:
    print('connecting to {base_url}...'.format(base_url=base_url),
          file=sys.stderr)

  return DataClient(
    base_url=base_url,
    token=parsed.password,
  )

if __name__ == '__main__':
  if len(sys.argv) <= 2:
    print('Usage: pyswaggerclient <meta | data> <URI> [ACTION] -- named=params')
    exit()

  if sys.argv[1] == 'meta':
    client = get_meta_client(sys.argv[2])
  elif sys.argv[1] == 'data':
    client = get_data_client(sys.argv[2])
  else:
    raise Exception('Unrecognized client type `{type}`'.format(type=sys.argv[1]))

  if len(sys.argv) <= 3:
    print(
      'Available actions:',
      *(
        '- ' + k
        for k in client.actions.__dict__.keys()
        if not k.startswith('_')
      ),
      sep='\n'
    )
    exit()
  
  if len(sys.argv) <= 4:
    print('Action:', sys.argv[3])
    action = getattr(client.actions, sys.argv[3])
    print('Docstring:', action.__doc__)
    exit()
  
  if len(sys.argv) >= 5 and sys.argv[4] == '--':
    args = dict([arg.split('=', maxsplit=1) for arg in sys.argv[5:]])
    for arg, v in args.items():
      if v == '-':
        args[arg] = json.load(sys.stdin)
      else:
        args[arg] = json.loads(v)
    action = getattr(client.actions, sys.argv[3])
    result = action.call(**args)

    print(json.dumps(result))
