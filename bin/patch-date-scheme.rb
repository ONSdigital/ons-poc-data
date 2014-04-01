require 'date'
require 'json'

#
# Patch the structure of the date concept scheme. Easier to do this
# in Ruby than in XSLT
#
#  * types for values
#  * previous/next pointers
#  * broader/narrower relationships
#
# Input is a JSON document conforming to concept scheme structure
# Output is document in same structure with extra attributes

scheme = JSON.parse( File.read( ARGV[0] ) )

MONTHS = Date::ABBR_MONTHNAMES.dup.map{|m| m.upcase if m }
  
scheme["values"].each do |key, value|
  #key values are either:
  #year, e.g. 2013
  #year-quarter, 2013Q1
  #year-month, 2013AUG
  case key
  when /^([0-9]{4})$/
    year = $1.to_i
    value["type"] = "year"
    value["previous"] = [{"period" => "year", "value" => year - 1} ]
    value["next"] = [{"period" => "year", "value" => year + 1} ]
    value["narrower"] = []
    (1..4).each do |q| value["narrower"] << { "period" => "quarter", "value" => "#{year}Q#{q}" } end
     
  when /^([0-9]{4})Q([0-9])$/
    year = $1.to_i
    quarter = $2.to_i
    value["type"] = "quarter"

    #previous quarter, which may be previous year
    #previous year, which is same quarter last year
    previous_quarter = quarter == 1 ? "#{year - 1}Q4" : "#{year}Q#{quarter-1}"
    value["previous"] = [ { "period" => "quarter", "value" => previous_quarter }, { "period" => "year", "value" => "#{year-1}Q#{quarter}" } ]
    
    #next quarter, which may be next year
    #next year, which is same quarter next year
    next_quarter = quarter == 4 ? "#{year + 1}Q1" : "#{year}Q#{quarter+1}"
    value["next"] = [ { "period" => "quarter", "value" => next_quarter }, { "period" => "year", "value" => "#{year+1}Q#{quarter}" } ]

    #broader: year
    value["broader"] = [ {"period" => "year", "value" => year.to_s } ]
      
    #months
    value["narrower"] = []
    MONTHS[ (quarter*3-2)..(quarter*3) ].each do |month|
      value["narrower"] << { "period" => "month", "value" => "#{year}#{month}" }
    end
            
  when /^([0-9]{4})([A-Z]{3})$/
    year = $1.to_i
    month = MONTHS.index( $2 )
    value["type"] = "month"

    #previous month, which may be previous year
    #previous year, which is same month last year
    previous_month = month == 1 ? "#{year - 1}DEC" : "#{year}#{MONTHS[month - 1 ]}"
    value["previous"] = [ { "period" => "month", "value" => previous_month }, { "period" => "year", "value" => "#{year-1}#{MONTHS[month]}" } ]
    
    #next month, which may be next year
    #next year, which is same month next year
    next_month = month == 12 ? "#{year + 1}JAN" : "#{year}#{MONTHS[month + 1]}"
    value["next"] = [ { "period" => "month", "value" => next_month }, { "period" => "year", "value" => "#{year+1}#{MONTHS[month]}" } ]

    #broader: year
    value["broader"] = [ {"period" => "year", "value" => year.to_s }, {"period" => "quarter", "value" => "#{year}Q#{month/4+1}" } ]
        
  else
    $stderr.puts "Unexpected item in the data loading area: #{key}"
  end
end

File.open( ARGV[0], "w") do |f|
  f.puts JSON.pretty_generate( scheme )
end