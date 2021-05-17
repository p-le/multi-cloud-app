from concurrent import futures
import time
import os
import grpc
import helloworld_pb2
import helloworld_pb2_grpc

def run(host, api_key):
    channel = grpc.insecure_channel(host)
    stub = helloworld_pb2_grpc.GreeterStub(channel)
    metadata = []
    if api_key:
        metadata.append(('x-api-key', api_key))

    response = stub.SayHello(helloworld_pb2.HelloRequest(name='you'), metadata=metadata)
    print('Greeter client received: ' + response.message)
    response = stub.SayHelloAgain(helloworld_pb2.HelloRequest(name='you'), metadata=metadata)
    print('Greeter client received: ' + response.message)


if __name__ == "__main__":
    HOST = os.environ.get("HOST", "localhost:50051")
    API_KEY = os.environ.get("API_KEY", None)
    run(HOST, API_KEY)
