require "sqlite3"
require "json"
require "google_search_results"
require "json"
require "httpx"
require 'dotenv/load'

APPLE_BOOK_ANNOTATION_PATH = "/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/AEAnnotation_v10312011_1727_local.sqlite"
APPLE_BOOK_LIBRARY_PATH = "/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/BKLibrary-1-091020131601.sqlite"
BOOK_DB_FILENAME = "ibook_history.json"
BOOKCOVER_FILENAME = "bookcovers_cached.json"

def get(path, sql, object)
  path = File.expand_path('~') + path
  db = SQLite3::Database.new path

  result = []
  db.execute(sql) do |row|
    obj = object.new(*row)
    result << obj.to_h
  end
  result
end

def cloud_upload(filename)
  file = File.read(filename)
  body = { files: Hash[filename, { content: file }] }
  auth_client = HTTPX.plugin(:authentication)
  auth_client.authentication("Bearer #{ENV["TOKEN"]}").patch(ENV["API_SERVER"], body: body.to_json )
end

SELECT_ANNOTATION=<<~SQL
  SELECT
    Z_PK AS PK,
    ZANNOTATIONASSETID AS BOOK_ID,
    ZFUTUREPROOFING5 AS CHAPTER,
    ZANNOTATIONSELECTEDTEXT AS TEXT,
    ZANNOTATIONREPRESENTATIVETEXT AS SENTENCE,
    ZANNOTATIONNOTE AS NOTE,
    ZANNOTATIONLOCATION AS PATH,
    ZANNOTATIONCREATIONDATE AS CREATED_AT,
    ZANNOTATIONMODIFICATIONDATE AS UPDATED_AT,
    ZANNOTATIONISUNDERLINE AS IS_INDERLINE,
    ZANNOTATIONSTYLE AS COLOR,
    ZANNOTATIONTYPE AS TYPE
  FROM ZAEANNOTATION
  WHERE ZANNOTATIONDELETED = 0
    AND (ZANNOTATIONSELECTEDTEXT IS NOT NULL AND ZANNOTATIONREPRESENTATIVETEXT IS NOT NULL)
  ORDER BY Z_PK DESC
SQL

Annotation = Struct.new(
  :pk, 
  :book_id, 
  :chapter, 
  :text, 
  :sentence, 
  :note, 
  :path, 
  :created_at, 
  :updated_at, 
  :is_inderline, 
  :color, 
  :type
)
annotations = get(APPLE_BOOK_ANNOTATION_PATH, SELECT_ANNOTATION, Annotation)


SELECT_LIBRARY=<<-SQL
  SELECT 
    ZASSETID AS BOOK_ID,
    ZAUTHOR AS AUTHOR, 
    ZTITLE AS TITLE,
    ZLASTENGAGEDDATE AS LAST_ENGAGED_DATE,
    ZREADINGPROGRESS AS READING_PROGRESS, 
    ZISFINISHED AS MARKED_AS_FINISHED, 
    ZPURCHASEDATE AS PURCHASE_DATE, 
    ZGENRE AS GENRE, 
    ZLANGUAGE AS LANG, 
    ZFILESIZE AS FILE_SIZE,
    ZPAGECOUNT AS PAGE_COUNT,
    ZCREATIONDATE AS CREATED_AT,
    ZMODIFICATIONDATE AS UPDATED_AT,
    ZASSETDETAILSMODIFICATIONDATE AS ASSET_DETAILS_MODIFICATION_DATE
  FROM ZBKLIBRARYASSET
  ORDER BY ZMODIFICATIONDATE DESC, Z_PK DESC
SQL

Library = Struct.new(
  :book_id,
  :author,
  :title,
  :last_engaged_date,
  :reading_progress,
  :marked_as_finished,
  :purchase_date,
  :genre,
  :lang,
  :file_size,
  :page_count,
  :created_at,
  :updated_at,
  :asset_details_modification_date
)
books = get(APPLE_BOOK_LIBRARY_PATH, SELECT_LIBRARY, Library)

annotations = annotations.group_by{|i| i[:book_id]}

book_covers_file = File.read(BOOKCOVER_FILENAME)
book_covers = JSON.parse(book_covers_file.empty? ? "{}" : book_covers_file)

# FOR TESTING
books = [books[1]]

books.each do |book| 
# DOC: Joins Annotation with Library by book_id
  book[:notes] = annotations[book[:book_id]] || []

  book[:covers] = book_covers[book[:book_id]] || []
  # Get a book cover online
  if book[:covers].empty?
    begin
      search = GoogleSearch.new(
        q: "#{book[:title]} #{book[:author]}", 
        tbm: "isch", 
        serp_api_key: ENV["SERP_API_KEY"], 
        num: 10
      )
      search = search.get_hash[:images_results]
    rescue
    end

    book[:covers] ||= search.take(10).map{|img| img.slice(:position, :thumbnail, :original)}
  end
end

result_set = {
  book_count: books.length,
  author_count: books.group_by{|i| i[:author]}.length,
  data: books
}

File.write(BOOK_DB_FILENAME, JSON.pretty_generate(result_set))

book_covers = {}
books.each do |book|
  book_covers[book[:book_id]] = book[:covers]
end
File.write(BOOKCOVER_FILENAME, JSON.pretty_generate(book_covers))

# DOC: Upload
cloud_upload(BOOKCOVER_FILENAME)
cloud_upload(BOOK_DB_FILENAME)
