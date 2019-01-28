"""API to expose book data"""
import hug
import handler


@hug.get('/')
def root():
    return {}


@hug.get('/by_isbn/{isbn}')
def book_by_isbn(isbn: int):
    """get a book via the isbn number"""
    return handler.book_by_isbn(isbn)
