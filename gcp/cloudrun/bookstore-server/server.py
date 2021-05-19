"""The Python gRPC Bookstore Server Example."""

import os
import time
import grpc
import bookstore
import bookstore_pb2
import bookstore_pb2_grpc
import status

from concurrent import futures
from google.protobuf import struct_pb2

_ONE_DAY_IN_SECONDS = 60 * 60 * 24


class BookstoreServicer(bookstore_pb2_grpc.BookstoreServicer):
    """Implements the bookstore API server."""
    def __init__(self, store):
        self._store = store

    def ListShelves(self, unused_request, context):
        with status.context(context):
            response = bookstore_pb2.ListShelvesResponse()
            response.shelves.extend(self._store.list_shelf())
            return response

    def CreateShelf(self, request, context):
        with status.context(context):
            shelf, _ = self._store.create_shelf(request.shelf)
            return shelf

    def GetShelf(self, request, context):
        with status.context(context):
            return self._store.get_shelf(request.shelf)

    def DeleteShelf(self, request, context):
        with status.context(context):
            self._store.delete_shelf(request.shelf)
            return struct_pb2.Value()

    def ListBooks(self, request, context):
        with status.context(context):
            response = bookstore_pb2.ListBooksResponse()
            response.books.extend(self._store.list_books(request.shelf))
            return response

    def CreateBook(self, request, context):
        with status.context(context):
            return self._store.create_book(request.shelf, request.book)

    def GetBook(self, request, context):
        with status.context(context):
            return self._store.get_book(request.shelf, request.book)

    def DeleteBook(self, request, context):
        with status.context(context):
            self._store.delete_book(request.shelf, request.book)
            return struct_pb2.Value()


def create_sample_bookstore():
    """Creates a Bookstore with some initial sample data."""
    store = bookstore.Bookstore()

    shelf = bookstore_pb2.Shelf()
    shelf.theme = 'Fiction'
    _, fiction = store.create_shelf(shelf)

    book = bookstore_pb2.Book()
    book.title = 'REAMDE'
    book.author = "Neal Stephenson"
    store.create_book(fiction, book)

    shelf = bookstore_pb2.Shelf()
    shelf.theme = 'Fantasy'
    _, fantasy = store.create_shelf(shelf)

    book = bookstore_pb2.Book()
    book.title = 'A Game of Thrones'
    book.author = 'George R.R. Martin'
    store.create_book(fantasy, book)

    return store


def serve(port, shutdown_grace_duration):
    """Configures and runs the bookstore API server."""
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))

    store = create_sample_bookstore()
    bookstore_pb2_grpc.add_BookstoreServicer_to_server(
        BookstoreServicer(store), server)
    server.add_insecure_port('[::]:{}'.format(port))
    server.start()

    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop(shutdown_grace_duration)


if __name__ == '__main__':
    PORT = os.environ.get("PORT", 50051)
    SHUTDOWN_GRACE_DURATION = os.environ.get("SHUTDOWN_GRACE_DURATION", 5)
    print(f'Listening on port {PORT}')
    serve(PORT, SHUTDOWN_GRACE_DURATION)
