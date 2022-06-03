#!/usr/bin/ruby
require "json"

DATA_FILENAME = "data/ibook_history.js"
JS_CODE = "var ibook_history = "

content = File.read(DATA_FILENAME)
content = content.sub(JS_CODE, '')
db = JSON.parse(content.empty? ? '{"data":[]}' : content)
lib = db["data"]

books = lib.each_with_index do |book, index|
  next if book["cover"]["src"].nil? || book["cover"]["src"].start_with?("assets/images")

  url = book["cover"]["src"]
  ext = File.extname(url).split('?')[0]
  filename = book["book_id"]+ext
  img_path = "assets/images/#{filename}"
  File.open(img_path, "wb") do |fo|
    fo.write open(url).read 
  end
  book["cover"]["src"] = img_path
end

# FIXME: Save original content as JS code
File.write(DATA_FILENAME, JS_CODE+JSON.pretty_generate(lib))