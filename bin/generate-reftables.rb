require "roo"
require "json"

filename = ARGV[0]
release = ARGV[1]
output_dir = ARGV[2]

spreadsheet = Roo::Excel.new(ARGV[0])   

worksheets = ["Ouput12mthchange", "Output1mthchange", "Input12mthchange", "Input1mthchange"]
#worksheets = ["Output1mthchange"]
  
date = spreadsheet.sheet("Cover sheet").cell(16, "B")
  
worksheets.each do |worksheet|
  dataset_slug = worksheet.downcase
  date_month = spreadsheet.sheet(worksheet).cell(1, "F").strftime("%Y%^b")
  published = Date.parse( date ).strftime("%Y-%m-%d")
  dataset = {
    type: "Dataset",
    release: release,
    id: "#{release}/#{dataset_slug}",
    slug: dataset_slug,
    release_slug: published,
    source: "#{release}/ppi-csdb-ds",
    coverage: "http://statistics.data.gov.uk/doc/statistical-geography/K02000001",
    title: "Producer Price Indices #{date}. #{spreadsheet.sheet(worksheet).cell(1, "B")}",
    description: "#{ worksheet.start_with?("Ou") ? "Output" : "Input" } price indices showing higher, lower and equal to.",
    published: published,
    structure: {
      product: {
        id: "/def/dimensions/product",
        slug: "product",
        type: "dimension",
        values: "/def/cdid",
        values_slug: "cdid"
      },
      date: {
         id: "/def/dimensions/date",
         slug: "date",
         type: "timedimension",
         values: "/def/date",
         values_slug: "date"
      },
      "unit-measure" => {
        id: "/def/attributes/unit-measure",
        slug: "unit-measure",
        type: "attribute",
        values: "/def/units",
        values_slug: "units"
      },
      "percentage-change" => {
         id: "/def/measures/percentage-change",
         slug: "percentage-change",
         type: "measure"
      }    
    }
  }
  observations = []
    
  #fill in cdids
  (4..16).each do |row|
    #puts row
    code = spreadsheet.sheet(worksheet).cell(row, "B")
    if code != nil
      title = spreadsheet.sheet(worksheet).cell(row, "C")
      cdid = spreadsheet.sheet(worksheet).cell(row, "D")
      rate = spreadsheet.sheet(worksheet).cell(row, "E")
      notes = "<p>Last lower: #{spreadsheet.sheet(worksheet).cell(row, "F")}</p>" + 
      "<p>Last higher: #{spreadsheet.sheet(worksheet).cell(row, "G")}</p>" + 
      "<p>Same: #{spreadsheet.sheet(worksheet).cell(row, "H")}</p>"
      
      observation_slug = "obs-#{dataset_slug}-#{cdid.downcase}-#{date_month.downcase}"
      File.open( File.join( output_dir, "#{observation_slug}.json" ), "w") do |f|
        f.puts JSON.pretty_generate( {
          id: "#{release}/#{dataset_slug}/#{observation_slug}",
          slug: observation_slug,
          dataset_slug: dataset_slug,
          release_slug: release,
          type: "Observation",
          release: release,
          dataset: "#{release}/#{dataset_slug}",
          cdid: cdid,
          date: date_month,
          notes: notes,
          percentage_change: rate,
          unit_measure: "percentage"
        })
      end
    end
  end
  
  File.open( File.join( output_dir, "dataset-#{dataset_slug}.json" ), "w") do |f|
    f.puts JSON.pretty_generate( dataset )
  end
  
end
  
