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
      description: "A comprehensive selection of data on input and output index series. Contains producer price indices of materials and fuels purchased and output of manufacturing industry by broad sector.",
      published: date,
      slug: date,
      state: "released",
      id: "/statistics/producer-price-index/#{date}",
      series_slug: "producer-price-index",
      series: "/statistics/producer-price-index",
      type: "Release"
    }
    
    next_release = release_page.search(".release-date")[1]
    if next_release
      next_release = next_release.inner_text.strip.match( /\Next edition:\s+([a-zA-Z0-9 ]+)/ )[1]
      next_release = Date.parse( next_release ).strftime("%Y-%m-%d")
      release[:superseded_by] = "/statistics/producer-price-index/#{next_release}"
    end
    
    if release_page.at(".srp-key-points")
      release[:notes] = release_page.at(".srp-key-points").inner_html
    end  

    if release_page.at(".srp-correction")
      release[:correction] = release_page.at(".srp-correction").inner_html
    end  

    if release_page.at(".srp-contact")
      contact = release_page.at(".srp-contact")
      name = contact.search("p[1]").inner_text
      dept = contact.search("p[2]").inner_text
      tel = contact.search("p[4]").inner_text.gsub("Telephone: ", "")
      email = contact.search("p[3]").inner_text.strip
      release[:contact] = {
        name: name,
        department: dept,
        telephone: tel,
        email: email
      }
    end  
    
            
    File.open( File.join( ARGV[1], "release-ppi-#{date}.json"), "w") do |f|
      f.puts JSON.pretty_generate(release) 
    end
  else
    puts "Unable to find date: #{link}"
  end

end

