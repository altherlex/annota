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
