#!/usr/bin/ruby

require "sqlite3"
require "active_support/core_ext"
require "json"

APPLE_BOOK_ANNOTATION_PATH = "/Library/Containers/com.apple.iBooksX/Data/Documents/AEAnnotation/AEAnnotation_v10312011_1727_local.sqlite"
APPLE_BOOK_LIBRARY_PATH = "/Library/Containers/com.apple.iBooksX/Data/Documents/BKLibrary/BKLibrary-1-091020131601.sqlite"
DATA_FILENAME = "data/ibook_history.js"
JS_CODE = "var ibook_history = "

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

# ? Not known why iBook insert date 31 years ago.
def convert_date(int)
  Time.at(int).next_year(31) if int
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
    AND (ZANNOTATIONSELECTEDTEXT IS NOT NULL OR ZANNOTATIONREPRESENTATIVETEXT IS NOT NULL)
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
  ORDER BY ZASSETDETAILSMODIFICATIONDATE DESC, ZMODIFICATIONDATE DESC, Z_PK DESC
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

# DOC: convert date
annotations.map! do |annota| 
  annota[:created_at] = convert_date(annota[:created_at])
  annota[:updated_at] = convert_date(annota[:updated_at])
  annota[:words_count] = (annota[:text] || annota[:sentence] || '').split.count 
  annota
end

vocabularies = annotations.select{|annota| annota[:words_count] == 1}
annotations.reject!{|annota| annota[:words_count] == 1}

new_words_grouped = vocabularies.group_by{|i| i[:book_id]}
annota_grouped = annotations.group_by{|i| i[:book_id]}

content = File.read(DATA_FILENAME)
content.slice!(JS_CODE)
cache = JSON.parse(content.empty? ? '{"data":[]}' : content)

# DOC: Mount books from current data
books.map! do |book|
  book[:last_engaged_date] = convert_date(book[:last_engaged_date])
  book[:purchase_date] = convert_date(book[:purchase_date])
  book[:created_at] = convert_date(book[:created_at])
  book[:updated_at] = convert_date(book[:updated_at])
  book[:asset_details_modification_date] = convert_date(book[:asset_details_modification_date])
  # DOC: Join Annotations
  book[:notes] = annota_grouped[book[:book_id]] || []
  # DOC: Join Vocabulary
  book[:new_words] = new_words_grouped[book[:book_id]] || []
  book
end

new_books_id = books.map{|i| i[:book_id]} - cache["data"].map{|i| i['book_id']}
new_book = books.select{|i| new_books_id.include?(i[:book_id]) }

# DOC: update
books = cache["data"].map do |cbook|
  cbook = cbook.deep_transform_keys(&:to_sym)
  book = books.find{|b| b[:book_id]==cbook[:book_id]}
  book = cbook.merge(book)
  book
end

# DOC: insert
books = [*books, *new_book]

result_set = {
  updated_at: Time.now,
  book_count: books.length,
  author_count: books.group_by{|i| i[:author]}.length,
  notes_count: annotations.length,
  new_words_count: vocabularies.length,
  data: books.sort_by{|i| i[:updated_at]}.reverse
}

File.write(DATA_FILENAME, JS_CODE+JSON.pretty_generate(result_set))
