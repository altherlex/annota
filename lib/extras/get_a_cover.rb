# brew tap homebrew/cask
# brew install phantomjs --cask
GOOGLE_API_KEY = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
GOOGLE_SEARCH_CX = "xxxxxxxxxxxxxxxxxxxxxxxx"

# require 'scrapix'
# scraper = Scrapix::GoogleImages.new
# scraper.query = "Democracia na América Alexis de Tocqueville"
# scraper.options = { safe: false, size: "large" }
# scraper.total = 1
# scraper.find

# require 'epub/parser'
# book = EPUB::Parser.parse('/Users/altheralves/Downloads/book.epub')
# path = File.basename book.metadata.cover_image.href.to_s 
# # "cover.jpeg"
# File.write '/Users/altheralves/Downloads/my_cover.jpeg', book.metadata.cover_image.read

require 'uri'
require 'net/http'
require 'openssl'

# url = URI("https://contextualwebsearch-websearch-v1.p.rapidapi.com/api/Search/ImageSearchAPI?q=joaquim%20nabuco%20minha%20formacao&pageNumber=1&pageSize=10&autoCorrect=true&safeSearch=false")

# http = Net::HTTP.new(url.host, url.port)
# http.use_ssl = true
# http.verify_mode = OpenSSL::SSL::VERIFY_NONE

# request = Net::HTTP::Get.new(url)
# request["X-RapidAPI-Host"] = 'contextualwebsearch-websearch-v1.p.rapidapi.com'
# request["X-RapidAPI-Key"] = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

# response = http.request(request)
# puts response.read_body

#--------------------------------------------------------

require 'httparty'
require 'addressable/uri'

uri = Addressable::URI.new
# Full doc: https://developers.google.com/custom-search/v1/reference/rest/v1/cse/list
uri.query_values = {
  key: GOOGLE_API_KEY,
  cx: GOOGLE_SEARCH_CX,
  q:  "joaquim nabuco minha formacao",
  searchType: "image",
  imgSize: "LARGE"
}

url = "https://www.googleapis.com/customsearch/v1?#{uri.query}"
results = HTTParty.get(url)
results['items'][2]['link']
results['items'].map{|i| i['link']}
puts results.class
