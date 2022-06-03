#!/usr/bin/ruby
require "json"
require 'httparty'
require 'addressable/uri'
require 'dotenv/load'

# Full doc: https://developers.google.com/custom-search/v1/reference/rest/v1/cse/list
GOOGLE_IMAGE = "https://www.googleapis.com/customsearch/v1"
DATA_FILENAME = "data/ibook_history.js"
JS_CODE = "var ibook_history = "

def fetch_cover(q)
  uri = Addressable::URI.new
  uri.query_values = {
    key: ENV["GOOGLE_API_KEY"],
    cx: ENV["GOOGLE_SEARCH_CX"],
    q: q,
    searchType: "image",
    imgSize: "LARGE"
  }

  url = "#{GOOGLE_IMAGE}?#{uri.query}"
  results = HTTParty.get(url)
  (results['items']||[]).map{|i| i['link']}
end


content = File.read(DATA_FILENAME)
content = content.sub(JS_CODE, '')
db = JSON.parse(content.empty? ? '{"data":[]}' : content)

db["data"].each do |book|
  next if !(book["cover"]||{})["src"].nil?

  book["extra_covers"] = fetch_cover("#{book['title']} #{book['author']}")
  book["cover"] = { "src": book["extra_covers"][0] }
end

File.write(DATA_FILENAME, JS_CODE+JSON.pretty_generate(db))