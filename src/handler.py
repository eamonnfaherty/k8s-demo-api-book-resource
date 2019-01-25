"""abstraction layer between api and data store"""
import data_store


def book_by_isbn(isbn: int):
    """get a book via the isbn number"""
    return data_store.book_by_isbn(isbn)
