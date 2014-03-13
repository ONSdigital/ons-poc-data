require "rubygems"
require "rake"
require "rake/clean"
require "fileutils"

CACHE_DIR="data/cache"
JSON_DIR="data/json"

CLEAN.include ["#{JSON_DIR}/*.json", "#{JSON_DIR}/*.gz"]
  
task :init do
  FileUtils.mkdir_p(CACHE_DIR) unless File.exists?(CACHE_DIR)
  FileUtils.mkdir_p(JSON_DIR) unless File.exists?(JSON_DIR)
end

task :download => [:init] do
  {
    "http://www.ons.gov.uk/ons/datasets-and-tables/downloads/data.zip?dataset=ppi" => File.join(CACHE_DIR, "ppi-data.zip")
  }.each do |url,file|
   sh %{curl #{url} >#{file}} unless File.exists?(file)
  end
  sh %{unzip -u #{CACHE_DIR}/*.zip -d #{CACHE_DIR}}
end

task :generate_dataset do
  sh %{saxonb-xslt -ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-dataset.xsl >data/json/ppi-csdb-ds.json }
end

task :generate_observations do
  sh %{saxonb-xslt -ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-observations.xsl }
end

task :static do
  sh %{cp etc/static/*.json #{JSON_DIR} }
end

task :convert => [:download, :static, :generate_dataset, :generate_observations]
  
task :package => [:convert] do
  sh %{gzip #{JSON_DIR}/*} 
end

task :default => :convert