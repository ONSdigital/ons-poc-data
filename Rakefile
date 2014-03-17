require "rubygems"
require "rake"
require "rake/clean"
require "fileutils"

CACHE_DIR="data/cache"
JSON_DIR="data/json"

CLEAN.include ["#{JSON_DIR}/*.json", "#{JSON_DIR}/*.gz"]

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
    "http://www.ons.gov.uk/ons/datasets-and-tables/downloads/data.zip?dataset=ppi" => File.join(CACHE_DIR, "ppi-data.zip")
  }.each do |url,file|
   sh %{curl #{url} >#{file}} unless File.exists?(file)
  end
  sh %{unzip -u #{CACHE_DIR}/*.zip -d #{CACHE_DIR}}
end

task :clean_cache do
  sh %{rm -rf data/cache}
end

task :cache_releases => [:init] do
  sh %{ruby bin/cache-release-pages.rb #{CACHE_DIR}/pages}  
end

task :generate_releases do
  sh %{ruby bin/generate-releases.rb #{CACHE_DIR}/pages #{JSON_DIR}}
end

task :generate_dataset do
  flags = "-ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-dataset.xsl >data/json/dataset-ppi-csdb-ds.json"
  if osx?
    sh %{saxon #{flags}}
  else
    sh %{saxonb-xslt #{flags}}
  end
end

task :generate_observations do
  flags = "-ext:on data/cache/PPI_CSDB_DS.output.xml etc/xslt/generate-observations.xsl"
  if osx?
    sh %{saxon #{flags}}
  else
    sh %{saxonb-xslt #{flags}}
  end
end

task :static do
  sh %{cp etc/static/*.json #{JSON_DIR} }
end

task :generate => [:static, :generate_releases, :generate_dataset, :generate_observations]
  
task :convert => [:download, :generate]
  
task :package => [:convert] do
  sh %{gzip #{JSON_DIR}/*} 
end

task :default => :convert