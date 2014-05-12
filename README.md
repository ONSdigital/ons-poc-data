#Open Statistics Prototype Data Conversion

This project contains a collection of scripts that are used to generate some sample data for the Open Statistics Prototype. 

The [prototype-frontend](https://github.com/ONSdigital/prototype-frontend) projects contains pointers and background on the project.

The scripts work with the Producer Price Index (PPI) statistical series published by the ONS. The data is collected by downloading and processing raw data files and scraping data from the ONS website. Some static data is also included in the project.
More detail on each of these steps is given below.

The project also contains a script to load the generated data into a MongoDB instance using the [content models](https://github.com/ONSdigital/ons_data_models) created for the API. 

##Installation and Running the Conversion

Rake is used as the means for co-ordinating and running the data conversion process. There are separate scripts for running each of the conversion processes to assemble the complete dataset (see below).

There are a couple of dependencies that need special installation.

The scripts use some XSLT stylesheets to convert some XML data to JSON. This is handled using Saxon.

On Linux, run 

```
sudo apt-get install libsaxonb-java
```

Or on OSX, run

```
brew install saxon
```

This should install the required Saxon executable.

Some data is scraped from HTML pages and this uses the [hpricot](https://github.com/hpricot/hpricot) gem. hpricot isn't in rubygems anymore so you'll need to manually gem install it, it won't install by itself just running bundle.

```
gem install hpricot
```

To install the final dependencies run:

```
bundle install
```

##Running the Conversion

By default, the provided Rakefile will run the complete conversion storing all output in `data/json`. So just run:

```
rake
```

There are individual rake tasks for the key steps: `init`, `download`, and `convert` 

To load the data into mongo run

```
rake load
```

For a complete list of all supported Rake tasks run: `rake -T`.

##Data Sources

### PPI Dataset (XML)

The main data source is the [PPI dataset zipped XML file](http://www.ons.gov.uk/ons/datasets-and-tables/downloads/data.zip?dataset=ppi). See [context](http://www.ons.gov.uk/ons/rel/ppi2/producer-price-index/january-2014/tsd-producer-price-index--january-2014.html).

The zip file is download, unpacked and then two XSLT stylesheets are run over the data:

* `etc/static/generate-dataset.xsl` -- generate the core dataset metadata
* `etc/static/generate-observations.xls` -- generate one JSON file for each observation in the dataset

###  PPI Reference Table (Excel)

Each ONS statistical release consists of a core dataset and some [reference tables](http://www.ons.gov.uk/ons/publications/re-reference-tables.html?edition=tcm%3A77-325532). 

To illustrate conversion of a reference table, which are often cited from the statistical analysis, the [PPI records January 2014](http://www.ons.gov.uk/ons/rel/ppi2/producer-price-index/january-2014/ppi-records-january-2014.xls) is downloaded.

The Excel spreadsheet is processed using the [roo](https://github.com/Empact/roo) library which provides a simple way to read Excel spreadsheets.

### PPI Release Pages (HTML)

To provide data on each of the releases associated with the PPI series, the set of HTML pages linked from the [PPI index](http://www.ons.gov.uk/ons/rel/ppi2/producer-price-index/index.html) is crawled and scraped. 

To avoid hitting the ONS website too frequently the pages are downloaded and cached, making it easier to re-run the conversion.

This conversion step generates the release metadata.

### Static Data (JSON)

There are a couple of static files in `etc/static` which are automatically copied into the `data/json` directory when the `convert` task is run.

These static files were hand-written. They provide documentation (e.g. titles and descriptions) for dimensions, measures and attributes that were not available from the ONS site.

## Conversion Output

The conversion generates some intermediary files which are later used to populate Mongodb.

The conversion generates several kinds of files.:

* Series (`series-*.json`) -- in this case, just a single series, the PPI
* Release (`release-*.json`) -- one for each of the monthly releases of the PPI
* Dataset (`dataset-*.json`) -- datasets, there are 5 currently: one for the main set of observations and four others containing indices.
* Observations( `obs-*.json`) -- one document for each observation in a dataset

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

Broadly speaking these files are loaded directly into Mongo. However, rather than adding the documents directly they are parsed and serialised via the appropriate [content model objects](https://github.com/ONSdigital/ons_data_models) to ensure that the data is correctly validated.

##Use Cases

Some notes on test queries / use cases to support in the data API that will expose this data.

* Fetch an object based on its URI (`id`), e.g. a dataset, release, observation
* Fetch an observation based on its properties, e.g. "find me the observation with a `cdid` of `MC3Z` recorded in November 2013 (`2013NOV`)"
* Fetch the latest observation for a given `cdid`, e.g "what is the latest recorded price for `JU5C`?`
* Fetch all observations in a given time series, e.g. "find me all of the annual observations of `MC75`", or "find me all of the monthly observations of `MC75` for 2013" 
* Fetch a list of all releases of a given series
* Fetch a list of all datasets associated with a given release, e.g. "find all datasets associated with the 2014-02-18 release of the PPI"
* Lookup the list of dimensions for a dataset, e.g. what is the structure of the PPI dataset?
* Lookup the list of values for a dimension in a dataset, e.g. what values can `cdid` take in the PPI dataset?
