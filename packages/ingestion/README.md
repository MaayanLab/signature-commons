# Ingestion
This directory is intended to demonstrate how one goes about ingesting data into the API.

`ingest_rank_matrix.py`: parses a rank matrix described as a tsv, find/create entities and signatures in the database and send data to data API.

`swagger_client.py`: pyswaggerclient(-like) access to metadata and data API (in the data API case it's not actually swagger driven yet).

`ingest.py`: A demonstration of the commands which need to be run to ingest a set of libraries.
`ingest-legacy.sh`: A demonstration of the commands which need to be run to ingest a given dataset.

`data/test.tsv`: A demo data file in the proper format to be ingested.

`data/file_descriptions.tsv`: Library level metadata

## Library metadata description
`data/file_descriptions.tsv` should be of the form:
```
[ ]      \t Key1   \t Key2   \t ...
filename \t value1 \t value2 \t ...
```

The format will ultimately be converted into the following:
```
Library: { "id": resolved_uuid1(), "meta": { "Key1": value1, "Key2": value2 } }
# signatures in the file will have
Signature: { "id": resolved_uuid2(), "library": resolved_uuid1, "meta": { ... } }
```

## Ingestion Data Format Description
`data/*.tsv` should be of the form:
```
[ ]    \t [ ]    \t .. \t Key1 \t Value1 \t Value3 \t ...
[ ]    \t [ ]    \t .. \t Key2 \t Value2 \t Value4 \t ...
 :     \t  :     \t .. \t  :   \t  :     \t  :     \t ...
Key5   \t Key6   \t .. \t [ ]  \t [ ]    \t [ ]    \t ...
Value5 \t Value6 \t .. \t [ ]  \t 1.0    \t 2.0    \t ...
Value7 \t Value8 \t .. \t [ ]  \t 3.0    \t 4.0    \t ...
 :     \t  :     \t  : \t  :   \t  :     \t  :     \t ...
```

Where `[ ]` is an empty cell, `\t` is a tab character, and `... / :` representing continuation. It is emperative that the blank elements are there and all lines are the same length; the columns/rows however need not be semetric--it could look like so:

```
[ ] [ ] [ ] [ ] K1  V1  ...
[ ] [ ] [ ] [ ] K2  V2  ...
K3  K4  K5  K6  [ ] [ ] [ ]
V3  V4  V5  V6  [ ] ... ...
..  ..  ..  ..  [ ] ... ...
```

The format will ultimately be converted into the following:

```
Entity: { "id": resolved_uuid1(), "meta": { "Key1": Value1, "Key2": Value2 } }
Entity: { "id": resolved_uuid2(), "meta": { "Key1": Value3, "Key2": Value4 } }
Signature: { "id": resolved_uuid3(), "meta": { "Key5": Value5, "Key6": Value6 } }
  Signature Data: entities: [ (resolved_uuid1, 1.0), (resolved_uuid2, 3.0) ]
Signature: { "id": resolved_uuid4(), "meta": { "Key5": Value7, "Key6": Value8 } }
  Signature Data: entities: [ (resolved_uuid1, 2.0), (resolved_uuid2, 4.0) ]
```

That-is a signature is created for every row. In some cases the data matrix is transposed--each row is actually an entity and the signature is on the columns (as is the case in `test.tsv`--to handle this you just pass `--transpose` to the script. Note however that we cannot stream-process transposed data and instead need to load it all into memory to transpose it.
