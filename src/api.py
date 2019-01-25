"""API to expose book data"""
import hug

book_db = {
    1111111111111: {
        "isbn": 1111111111111,
        "name": "amazing book about numbers"
    }
}


@hug.get('/by_isbn/{isbn}')
def book_by_isbn(isbn: int):
    """get a book via the isbn number"""
    return book_db.get(isbn)
