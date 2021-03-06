require "rubygems"
require "rake"
require "rake/clean"
require "fileutils"

CACHE_DIR="data/cache"
JSON_DIR="data/json"

CLEAN.include ["#{JSON_DIR}/*.json", "#{JSON_DIR}/*.gz"]

MONGO_DB = ENV["ONS_POC_DB"] || "ons_poc_data_development"  
  
def osx?
  RUBY_PLATFORM.downcase =~ /darwin/
end
  
task :init do
  FileUtils.mkdir_p(CACHE_DIR)
  FileUtils.mkdir_p("#{CACHE_DIR}/pages")
  FileUtils.mkdir_p(JSON_DIR)
end

task :download => [:init, :cache_releases] do
  {
    "http://www.ons.gov.uk/ons/datasets-and-tables/downloads/data.zip?dataset=ppi" => File.join(CACHE_DIR, "ppi-data.zip"),
    "http://www.ons.gov.uk/ons/rel/ppi2/producer-price-index/january-2014/ppi-records-january-2014.xls" => File.join(CACHE_DIR, "reftables-2014-02-18.xls")
  }.each do |url,file|
   sh %{curl #{url} >#{file}} unless File.exists?(file)
  end
  sh %{unzip -u #{CACHE_DIR}/*.zip -d #{CACHE_DIR}}
end

task :clean_cache do
  sh %{rm -rf data/cache}
end

desc "Cache the release pages in case we want to scrape them multiple times"
task :cache_releases => [:init] do
  sh %{ruby bin/cache-release-pages.rb #{CACHE_DIR}/pages}  
end

desc "Generate release-*.json files by scraping locally cached HTML pages"
task :generate_releases do
  sh %{ruby bin/generate-releases.rb #{CACHE_DIR}/pages #{JSON_DIR}}
end

desc "Generate the dataset-ppi-csdb-ds.json file using XSLT"
task :generate_dataset do
  flags = "-ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-dataset.xsl >data/json/dataset-ppi-csdb-ds.json"
  if osx?
    sh %{saxon #{flags}}
  else
    sh %{saxonb-xslt #{flags}}
  end
  sh %{ruby bin/patch-date-scheme.rb #{JSON_DIR}/cs-date.json }
end

desc "Generate the observations (obs-*.json) for the main dataset using XSLT"
task :generate_observations do
  flags = "-ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-observations.xsl"
  if osx?
    sh %{saxon #{flags}}
  else
    sh %{saxonb-xslt #{flags}}
  end
end

desc "Generate the 4 additional datasets of current rate indices from reftables-2014-02-18.xls"
task :generate_reftables do
  sh %{ruby bin/generate-reftables.rb #{CACHE_DIR}/reftables-2014-02-18.xls "/statistics/producer-price-index/2014-02-18" #{JSON_DIR}}  
end

desc "Copy all JSON files from etc/static to data directory"
task :static do
  sh %{cp etc/static/*.json #{JSON_DIR} }
end

desc "Generate data using local files"
task :generate => [:static, :generate_releases, :generate_dataset, :generate_observations, :generate_reftables]
 
desc "Download and then generate data"  
task :convert => [:download, :generate]
  
task :package => [:convert] do
  sh %{gzip #{JSON_DIR}/*} 
end

desc "Clean mongo database"
task :clean_db do
  sh %{mongo #{MONGO_DB} --eval "db.dropDatabase()"}
end

desc "Load mongo database"
task :load do
  sh %{ruby bin/load-db.rb #{JSON_DIR} }
end

task :default => :convert