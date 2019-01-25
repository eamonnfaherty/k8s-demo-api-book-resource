"""abstraction layer for the data store"""

book_db = {
    1111111111111: {
        "isbn": 1111111111111,
        "name": "amazing book about numbers"
    }
}


def book_by_isbn(isbn: int):
    """get a book via the isbn number"""
    return book_db.get(isbn)
