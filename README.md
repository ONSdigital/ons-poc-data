#ONS Proof Of Concept Data Scripts

Scripts to generate some data for a proof-of-concept data API based around Mongodb.

The scripts currently work with the Producer Price Index (PPI) dataset, generating a directory of JSON files that can be 
loaded into a MongoDb instance

##Installation

Uses Rake for co-ordinating data conversion. The original XML data is converted to JSON using XSLT stylesheets processed 
with Saxon.

hpricot isn't in rubygems anymore so you'll need to manually gem install it, it won't install by itself just running bundle.


```
gem install hpricot
bundle install
```

Then, on Linux, run 

```
sudo apt-get install libsaxonb-java
```

Or on OSX, run

```
brew install saxon
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

Some use cases to support in a data API wrapping this data:

* Fetch an object based on its URI (`id`), e.g. a dataset, release, observation
* Fetch an observation based on its properties, e.g. "find me the observation with a `cdid` of `MC3Z` recorded in November 2013 (`2013NOV`)"
* Fetch the latest observation for a given `cdid`, e.g "what is the latest recorded price for `JU5C`?`
* Fetch all observations in a given time series, e.g. "find me all of the annual observations of `MC75`", or "find me all of the monthly observations of `MC75` for 2013" 
* Fetch a list of all releases of a given series
* Fetch a list of all datasets associated with a given release, e.g. "find all datasets associated with the 2014-02-18 release of the PPI"
* Lookup the list of dimensions for a dataset, e.g. what is the structure of the PPI dataset?
* Lookup the list of values for a dimension in a dataset, e.g. what values can `cdid` take in the PPI dataset?

## TODO

* Improve handling of notations, parse out SIC codes and add scoping
* Add ISO standard values for date dimension
* Convert indices spreadsheet
