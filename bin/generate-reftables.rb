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
  date_month = Date.parse( date ).strftime("%Y%^b")
  dataset = {
    type: "Dataset",
    release: release,
    id: "#{release}/#{dataset_slug}",
    source: "#{release}/ppi-csdb-ds",
    coverage: "http://statistics.data.gov.uk/doc/statistical-geography/K02000001",
    title: spreadsheet.sheet(worksheet).cell(1, "B"),
    published: Date.parse( date ).strftime("%Y-%m-%d"),
    structure: {
      cdid: {
        id: "/def/producer-price-index/cdid",
        title: "CDID",
        type: "dimension",
        values: {
        }
      },
      date: {
         id: "/def/producer-price-index/date",
         title: "Time Period",
         type: "timedimension",
         values: {
           "#{date_month}" => {
             id: "/def/producer-price-index/date/#{date_month.downcase}",
             notation: date_month,
             title: Date.parse( date ).strftime("%Y %^b")          
           }
         }
      },
      unit_measure: {
        id: "/def/measures/unit-measure",
        type: "attribute",
        values: {
          "percentage" => {
            id: "/def/measures/unit-measure/percentage",
            notation: "percentage",
            title: "Percentage"
          }
        }
      },
      percentage_change: {
         id: "/def/producer-price-index/percentage-change",
         title: "Percentage Change",
         type: "primarymeasure"
      },
      reporting_period: {
         id: "/def/producer-price-index/reporting-period",
         title: "Reference Period",
         type: "dimension",
         values: {
           month: {
             id: "/def/producer-price-index/reporting-period/monthly",
             notation: "monthly"
           },
           annual: {
             id: "/def/producer-price-index/reporting-period/annual",
             notation: "annual"
           }          
         }
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
      
      dataset[:structure][:cdid][:values][cdid] = {
        id: "/def/producer-price-index/cdid/#{cdid}",
        notation: cdid,
        title: title
      }
      
      observation_slug = "obs-#{dataset_slug}-#{cdid.downcase}-#{date_month.downcase}"
      File.open( File.join( output_dir, "#{observation_slug}.json" ), "w") do |f|
        f.puts JSON.pretty_generate( {
          id: "#{release}/#{dataset_slug}/#{observation_slug}",
          type: "Observation",
          release: release,
          dataset: "#{release}/#{dataset_slug}",
          cdid: cdid,
          date: date_month,
          notes: notes,
          percentage_change: rate,
          unit_measure: "percentage",
          reporting_period: worksheet.include?("12mth") ? "annual" : "monthly"
        })
      end
    end
  end
  
  File.open( File.join( output_dir, "dataset-#{dataset_slug}.json" ), "w") do |f|
    f.puts JSON.pretty_generate( dataset )
  end
  
end
  
