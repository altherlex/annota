const HIGHLIGHTS = {
  3: 'highlight-yellow',
  1: 'highlight-green',
  2: 'highlight-blue',
  4: 'highlight-pink',
  5: 'highlight-purple',
  6: 'highlight-underline'
}

function shortTitle(book) {
  var title = (book.ztitle || book.title);
  var shortTitle = jQuery.trim(title).substring(0, 28).trim(this) 
  if (shortTitle !== title){
    shortTitle = shortTitle + "...";
  }
  return shortTitle.toLowerCase()
}

function title(book) {
  return (book.ztitle || book.title || '').toLowerCase();
}

function author(book) {
  return (book.zauthor || book.author || '').toLowerCase();
}

function bookByID(id){
  return ibook_history.data.find(book => {
    return book.book_id === id
  })
}

function allBooks() {
  let year = (new URL(document.location)).searchParams.get('year');

  if (!year) {
    year = moment().year();
  }

  if (year === 'all') {
    return ibook_history.data
  } else {
    return ibook_history.data.filter(book => String(moment(book.created_at).year()) === String(year));
  }
}

function searchBooks(query=null) {
  if (query===null) return allBooks()

  options = {keys: ["title", "ztitle", "author", "zauthor"]}
  const fuse = new Fuse(allBooks(), options);
  var finds = fuse.search(query)
  return finds.map(function(fuse) { 
    return fuse.item
  })
}

function finishedBooks() {
  return allBooks().filter(book => {
    return book.reading_progress === 1 || book.marked_as_finished === 1
  })
}

function inProgressBooks() {
  return allBooks().filter(book => {
    return !!book.notes.length && !(book.reading_progress === 1 || book.marked_as_finished === 1)
  })
}

function booksWithNotes() {
  return ibook_history.data.filter(function(book){ 
    return !!book.notes.length
  })
}

function getRandomBookWithNote() {
  let books = booksWithNotes();
  let randomIndex = Math.floor(Math.random() * books.length);
  return books[randomIndex]
}