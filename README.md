#ONS Proof Of Concept Data Scripts

Scripts to generate some data for a proof-of-concept data API based around Mongodb.

The scripts currently work with the Producer Price Index dataset, generating a directory of JSON files that can be 
loaded into a MongoDb instance

##Installation

Uses Rake for co-ordinating data conversion. The original XML data is converted to JSON using XSLT stylesheets processed 
with Saxon.

To install Saxon on Ubuntu:

```
sudo apt-get install libsaxonb-java
```

##Running the Conversion

The provided Rakefile will run the complete conversion putting all output in `data/json`. So just run:

```
rake
```

There are individual rake tasks for the key steps: `init`, `download`, and `convert` 

There are a couple of static files in `etc/static` which are copied into the `data/json` directory.

##The Model

Currently loosely based on the RDF Data Cube. The output generates data for individual observations and the 
containing dataset.

##Use Cases

Some notes on use cases to support in the API

* Lookup an individual observation, e.g. January 2014 value for JU5C (soft drinks). May have qualifiers and notes
* Lookup a time series (a slice) for a given price index, e.g. all annual values for JU5C; all december 2013 figures across all prices
* Lookup a series, with all releases
* Lookup a release, with list of datasets and notes