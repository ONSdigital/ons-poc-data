require 'hpricot'
require 'open-uri'

RELEASE_INDEX="http://www.ons.gov.uk/ons/rel/ppi2/producer-price-index/index.html"

page = Hpricot( open(RELEASE_INDEX) )

releases = []
page.search(".previous-releases-results").each do |div|
  releases << div.at("a")["href"]
end

releases.each do |link|
  #excluded rebased versions for now
  match = link.match(/\/ons\/rel\/ppi2\/producer-price-index\/([a-z]+-[0-9]{4})\/index\.html/)
  if match
    basename = match[1]
    filename = File.join( ARGV[0], "#{basename}.html")
    File.open( filename , "w" ) do |f|
      f.puts open("http://www.ons.gov.uk#{link}").read
    end unless File.exists?(filename)
  end
end