require 'ons_data_models'
require "bundler"

Bundler.require(:default, ENV['RACK_ENV'])
require 'ons_data_models/require_all'

Mongoid.load!( File.expand_path("../config/mongoid.yml", File.dirname(__FILE__) ), ENV['RACK_ENV'] )
  
#Concept Schemes

Dir.glob("#{ARGV[0]}/cs-*.json") do |file|
  json = JSON.parse( File.read( file ) )
  cs = ConceptScheme.new( title: json["title"], slug: json["slug"], values: json["values"] )  
  cs.save  
end

#Dimensions
#Attributes
#Measures

#Series
  
#Release
  
#Dataset
  
#Observation