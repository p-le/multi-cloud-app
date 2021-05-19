from contextlib import contextmanager

import grpc


@contextmanager
def context(grpc_context):
    """A context manager that automatically handles KeyError."""
    try:
        yield
    except KeyError as key_error:
        grpc_context.code(grpc.StatusCode.NOT_FOUND)
        grpc_context.details(
            'Unable to find the item keyed by {}'.format(key_error))
