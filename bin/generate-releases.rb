require 'hpricot'
require 'date'
require 'json'

Dir.glob("#{ARGV[0]}/*.html") do |file|
  release_page = Hpricot( open(file) )
  date = release_page.at(".release-date").inner_text.strip.match( /\AReleased: ([a-zA-Z0-9 ]+)\s?(\(Latest\))?/ )[1]
  if date
    date = Date.parse( date ).strftime("%Y-%m-%d")
    release = {
      title: release_page.at("h1").inner_text.strip,
      published: date,
      id: "/statistics/producer-price-index/#{date}",
      series: "/statistics/producer-price-index",
      type: "Release"
    }
    
    if release_page.at(".srp-key-points")
      release[:notes] = release_page.at(".srp-key-points").inner_html
    end  

    if release_page.at(".srp-correction")
      release[:correction] = release_page.at(".srp-correction").inner_html
    end  
        
    File.open( File.join( ARGV[1], "ppi-release-#{date}.json"), "w") do |f|
      f.puts JSON.pretty_generate(release) 
    end
  else
    puts "Unable to find date: #{link}"
  end

end
