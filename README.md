#ONS Proof Of Concept Data Scripts

Scripts to generate some data for a proof-of-concept data API based around Mongodb.

The scripts currently work with the Producer Price Index (PPI) dataset, generating a directory of JSON files that can be 
loaded into a MongoDb instance

##Installation

Uses Rake for co-ordinating data conversion. The original XML data is converted to JSON using XSLT stylesheets processed 
with Saxon.

```
bundle install
sudo apt-get install libsaxonb-java
```

##Running the Conversion

The provided Rakefile will run the complete conversion putting all output in `data/json`. So just run:

```
rake
```

There are individual rake tasks for the key steps: `init`, `download`, and `convert` 

There are a couple of static files in `etc/static` which are copied into the `data/json` directory.

##The Output

The conversion generates several kinds of files:

* Series (`series-*.json`) -- in this case, just a single series, the PPI
* Release (`release-*.json`) -- one for each of the monthly releases of the PPI
* Dataset (`dataset-*.json`) -- a single dataset, covering the latest (Feb 2014) release of the PPI.
* Observations( `obs-*.json`) -- one document for each observation in the dataset

The Dataset contains the definitions of all of the dataset dimensions and attributes used in the observations, within the 
`structure` hash. The values for each dimension are included in the `values` key for that dimension.

E.g. `cdid` is defined as:

```
{
   "id" : "/statistics/producer-price-index/2014-02-18/ppi-csdb-ds",
   "structure" : {
      ...
      "cdid" : {
         "id" : "/def/producer-price-index/cdid",
         "title" : "CDID",
         "type" : "dimension",
         "values" : {
            "JU5C" : {
               "id" : "/def/producer-price-index/cdid/ju5c",
               "notation" : "JU5C",
               "title" : "1107000000:Soft drinks; mineral waters and other bottled waters"
            },
      	...
	}
      }
   }
}
```

##Use Cases

Some notes on use cases to support in the API

* Lookup an individual observation, e.g. January 2014 value for JU5C (soft drinks). May have qualifiers and notes
* Lookup a time series (a slice) for a given price index, e.g. all annual values for JU5C; all december 2013 figures across all prices
* Lookup a series, with all releases
* Lookup a release, with list of datasets and notes

## TODO

* Improve handling of notations, parse out SIC codes and add scoping
* Add ISO standard values for date dimension
* Convert indices spreadsheet
