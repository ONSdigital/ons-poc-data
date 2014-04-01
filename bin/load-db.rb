require 'ons_data_models'
require "bundler"

Bundler.require(:default, ENV['RACK_ENV'])
require 'ons_data_models/require_all'

Mongoid.load!( File.expand_path("../config/mongoid.yml", File.dirname(__FILE__) ), ENV['RACK_ENV'] )

def save_or_exit(model, json)
  if !model.save
    puts json
    puts model.errors.inspect
    #exit
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
  cs = ConceptScheme.find_or_create_by( slug: json["slug"] )
  cs.title = json["title"]
  cs.description = json["description"]
  cs.values = json["values"]
  cs
end

#Attributes
process("attribute-*.json") do |json|
  attribute = DataAttribute.find_or_create_by( slug: json["slug"] )
  attribute.title = json["title"]
  attribute.name = json["slug"]
  attribute.description = json["description"]
  attribute
end

#Dimensions
process("dimension-*.json") do |json|
  dimension = Dimension.find_or_create_by( slug: json["slug"] )
  dimension.title = json["title"]
  dimension.name = json["slug"]
  dimension.description = json["description"]
  dimension.dimension_type = json["type"]
  dimension
end

#Measures
process("measure-*.json") do |json|
  measure = Measure.find_or_create_by( slug: json["slug"] )
  measure.title = json["title"]
  measure.name = json["slug"]
  measure.description = json["description"]
  measure
end

#Series
#FIXME coverage, geo breakdown?
process("series-*.json") do |json|
  series = Series.find_or_create_by( slug: json["slug"])
  series.title = json["title"]
  series.description = json["description"]
  series.contact = Contact.new( json["contact"] )
  series.language = json["language"]
  series.frequency = json["frequency"]
  series
end

#Release
process("release-*.json") do |json|
  series = Series.where( slug: json["series_slug"] ).first
  release = Release.find_or_create_by( slug: json["slug"] )
  release.title = json["title"]
  release.description = json["description"]
  release.published = json["published"]
  release.comments = json["comments"]
  release.contact = Contact.new( json["contact"] )
  release.state = json["state"]
  release.notes = json["notes"]
  release.series = series
  #FIXME superseded
  release
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
      measures << measure.id
    when "primarymeasure"
      measure = Measure.where( slug: key ).first
      measures << measure.id
    else
      puts value
      puts "Unexpected data in the loading area?!"
      exit
    end
  end
  dataset = Dataset.find_or_create_by( slug: json["slug"] )
  dataset.title = json["title"]
  dataset.description = json["description"]
  dataset.release = release
  dataset.dimensions = dimensions
  dataset.data_attributes = data_attributes
  dataset.measures = measures
  dataset
end
  
#Observation
process("obs-*.json") do |json|
  dataset = Dataset.where( slug: json["dataset_slug"] ).first
  json = json.delete_if { |k,v| ["id", "release_slug", "dataset_slug", "series_slug", "type", "release", "series", "dataset"].include? k }
  json[:dataset] = dataset
  obs = Observation.find_or_create_by( slug: json["slug"], dataset: dataset )  
  obs.update_attributes( json )
  obs
end
