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

function allBooks() {
  return ibook_history.data
}

function finishedBooks() {
  return ibook_history.data.filter(function(book){ 
    return book.reading_progress === 1 || book.marked_as_finished === 1
  })
}

function inProgressBooks() {
  return ibook_history.data.filter(function(book){ 
    return !!book.notes.length && !(book.reading_progress === 1 || book.marked_as_finished === 1)
  })
}
