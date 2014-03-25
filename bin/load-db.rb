require 'ons_data_models'
require "bundler"

Bundler.require(:default, ENV['RACK_ENV'])
require 'ons_data_models/require_all'

Mongoid.load!( File.expand_path("../config/mongoid.yml", File.dirname(__FILE__) ), ENV['RACK_ENV'] )

def save_or_exit(model, json)
  if !model.save
    puts json
    puts model.errors.inspect
    exit
  end
end

def process(glob)
  $stderr.puts("Processing: #{glob}")
  Dir.glob("#{ARGV[0]}/#{glob}") do |file|
    json = JSON.parse( File.read( file ) )
    model = yield( json )
    save_or_exit( model, json )
  end
end

process( "cs-*.json" ) do |json|
  cs = ConceptScheme.new( 
      title: json["title"], 
      slug: json["slug"], 
      description: json["description"], 
      values: json["values"] 
  )  
end

#Attributes
process("attribute-*.json") do |json|
  attribute = DataAttribute.new( 
      title: json["title"],
      name: json["slug"],
      slug: json["slug"] 
   )  
end

#Dimensions
process("dimension-*.json") do |json|
  dimension = Dimension.new( 
      title: json["title"],
      name: json["slug"],
      slug: json["slug"], 
      description: json["description"],
      dimension_type: json["type"] 
  )  
end

#Measures
process("measure-*.json") do |json|
  measure = Measure.new( slug: json["slug"], name: json["slug"], title: json["title"], description: json["description"])
end

#Series
#FIXME coverage, geo breakdown?
process("series-*.json") do |json|
  series = Series.new( title: json["title"], 
                       slug: json["slug"], 
                       description: json["description"],
                       contact: Contact.new( json["contact"] ),
                       language: json["language"], 
                       frequency: json["frequency"] )
end

#Release
process("release-*.json") do |json|
  series = Series.where( slug: json["series_slug"] ).first
  release = Release.new( title: json["title"], 
                       slug: json["slug"], 
                       description: json["description"],
                       published: json["published"],
                       comments: json["comments"],
                       contact: json["contact"],
                       state: json["state"],
                       #FIXME superseded
                       notes: json["notes"],
                       series: series)
end

#Dataset
process("dataset-*.json") do |json|
  release = Release.where( slug: json["release_slug"] ).first
  dimensions = {}
  data_attributes = {}
  measures = []
  json["structure"].each do |key, value|
    case value["type"]
    when "attribute"
      attr = DataAttribute.where( slug: key ).first
      cs = ConceptScheme.where( :slug => value["values_slug"] ).first if value["values_slug"]
      data_attributes[attr.id] = cs.id 
    when "dimension"
      dim = Dimension.where( slug: key ).first
      cs = ConceptScheme.where( :slug => value["values_slug"] ).first if value["values_slug"]
      dimensions[dim.id] = cs.id
    when "timedimension"
      dim = Dimension.where( slug: key ).first
      cs = ConceptScheme.where( :slug => value["values_slug"] ).first if value["values_slug"]      
      dimensions[dim.id] = cs.id
    when "measure"
      measure = Measure.where( slug: key ).first
      measures << measure
    when "primarymeasure"
      measure = Measure.where( slug: key ).first
      measures << measure
    else
      puts value
      puts "Unexpected data in the loading area?!"
      exit
    end
  end
  dataset = Dataset.new( title: json["title"], 
                       slug: json["slug"], 
                       description: json["description"],
                       release: release,
                       dimensions: dimensions, 
                       data_attributes: data_attributes,
                       measures: measures)
  #TEMPORARY: measures need to be linked to dataset
  measures.each do |m|
    m.dataset = dataset
    m.save
  end
  dataset
end
  
#Observation
process("obs-*.json") do |json|
  dataset = Dataset.where( slug: json["dataset_slug"] ).first
  json = json.delete_if { |k,v| ["id", "release_slug", "dataset_slug", "series_slug", "type", "release", "series", "dataset"].include? k }
  json[:dataset] = dataset
  obs = Observation.new( json )
end
