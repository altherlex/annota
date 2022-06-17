#!/usr/bin/ruby
require "json"
require "open-uri"

DATA_FILENAME = "data/ibook_history.js"
JS_CODE = "var ibook_history = "

def download(book)
  url = book["cover"]["src"]
  ext = File.extname(url).split('?')[0] || ''
  filename = book["book_id"]+ext
  img_path = "assets/images/#{filename}"

  File.open(img_path, "wb") do |fo|
    fo.write open(url).read 
  end

  img_path
end

content = File.read(DATA_FILENAME)
content = content.sub(JS_CODE, '')
db = JSON.parse(content.empty? ? '{"data":[]}' : content)

db["data"].each do |book|
  next if book["cover"]["src"].nil? || book["cover"]["src"].start_with?("assets/images")

  book["cover"]["src"] = download(book)
end

File.write(DATA_FILENAME, JS_CODE+JSON.pretty_generate(db))