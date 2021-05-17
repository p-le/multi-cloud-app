from concurrent import futures
import time
import os
import grpc
import helloworld_pb2
import helloworld_pb2_grpc

_5MINS_IN_SECONDS = 5 * 60

class Greeter(helloworld_pb2_grpc.GreeterServicer):
    def SayHello(self, request, context):
        return helloworld_pb2.HelloReply(message='Hello, %s!' % request.name)

    def SayHelloAgain(self, request, context):
        return helloworld_pb2.HelloReply(
            message='Hello again, %s!' % request.name)

def serve(port: int, shutdown_grace_duration):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    helloworld_pb2_grpc.add_GreeterServicer_to_server(Greeter(), server)
    server.add_insecure_port(f"[::]:{port}")
    server.start()
    print(f'Listening on port {port}')
    try:
        while True:
            time.sleep(_5MINS_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop(grace=shutdown_grace_duration)

if __name__ == "__main__":
    PORT = os.environ.get("PORT", 50051)
    GRACE_DURATION_SECS = 5
    serve(PORT, GRACE_DURATION_SECS)
