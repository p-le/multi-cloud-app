import os
import grpc
import google.auth.credentials
import credential_pb2
import credential_pb2_grpc
import time
from concurrent import futures
from google.cloud import firestore
from google.protobuf.json_format import MessageToDict


_ONE_DAY_IN_SECONDS = 60 * 60 * 24

class OauthCredentialsServicer(credential_pb2_grpc.OauthCredentialsServicer):
    COLLECTION_NAME = u'youtube-oauth-credentials'

    def __init__(self):
        self._db = firestore.Client()


    def SaveCredentials(self, request: credential_pb2.SaveCredentialsRequest, context: grpc.ServicerContext):
        credentials = request.credentials
        host = request.host
        credentials_ref = self._db.collection(OauthCredentialsServicer.COLLECTION_NAME)
        print(f"Save credentials: {MessageToDict(credentials, preserving_proto_field_name=True)} for host {host}")
        credentials_ref.document(host).set(MessageToDict(credentials, preserving_proto_field_name=True))
        return credential_pb2.SaveCredentialsResponse(success=True)

    def GetCredentials(self, request: credential_pb2.GetCredentialsRequest, context: grpc.ServicerContext):
        host = request.host
        credentials_ref = self._db.collection(OauthCredentialsServicer.COLLECTION_NAME)
        try:
            doc_ref = credentials_ref.document(host)
            doc = doc_ref.get()
            response = credential_pb2.GetCredentialsResponse(credentials=credential_pb2.Credentials(**doc.to_dict()))
        except Exception as ex:
            print(f"Credentials does not exist for host {host}")
            response = credential_pb2.GetCredentialsResponse(credentials=None)
        return response


def serve(port, shutdown_grace_duration):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    credential_pb2_grpc.add_OauthCredentialsServicer_to_server(OauthCredentialsServicer(), server)
    server.add_insecure_port('[::]:{}'.format(port))
    server.start()
    try:
        while True:
            time.sleep(_ONE_DAY_IN_SECONDS)
    except KeyboardInterrupt:
        server.stop(shutdown_grace_duration)


if __name__ == '__main__':
    port = os.environ.get("PORT", 50051)
    shutdown_grace_duration = os.environ.get("SHUTDOWN_GRACE_DURATION", 5)
    print(f'Listening on port {port}')
    serve(port, shutdown_grace_duration)


# @app.before_first_request
# def get_firestore_client() -> None:
#     global client
#     if os.getenv("FIRESTORE_EMULATOR_HOST"):
#         # Firestore Emulator on Localhost
#         project_id = os.getenv("PROJECT_ID")
#         credentials = mock.Mock(spec=google.auth.credentials.Credentials)
#         client = firestore.Client(project=project_id, credentials=credentials)
#     else:
#         # Service Account Credentials on Production
#         client = firestore.Client()


# @app.route('/create', methods=['GET'])
# def create():
#     global client
#     viet_soccers_ref = client.collection(u'viet-soccers')
#     doc_ref = viet_soccers_ref.document(u'alovelace')
#     doc_ref.set({
#         u'first': u'Ada',
#         u'last': u'Lovelace',
#         u'born': 1815
#     })
#     print(viet_soccers_ref)
#     return jsonify({"success": True}), HTTPStatus.OK

# @app.route('/get', methods=['GET'])
# def get():
#     global client
#     viet_soccers_ref = client.collection(u'viet-soccers')
#     print(viet_soccers_ref)

#     for doc in viet_soccers_ref.stream():
#         print(u'{} => {}'.format(doc.id, doc.to_dict()))

#     return jsonify({"success": True}), HTTPStatus.OK

# @app.route('/add', methods=['POST'])
# def create():
#     """
#         create() : Add document to Firestore collection with request body.
#         Ensure you pass a custom ID as part of json body in post request,
#         e.g. json={'id': '1', 'title': 'Write a blog post'}
#     """
#     try:
#         id = request.json['id']
#         todo_ref.document(id).set(request.json)
#         return jsonify({"success": True}), 200
#     except Exception as e:
#         return f"An Error Occured: {e}"

# @app.route('/list', methods=['GET'])
# def read():
#     """
#         read() : Fetches documents from Firestore collection as JSON.
#         todo : Return document that matches query ID.
#         all_todos : Return all documents.
#     """
#     try:
#         # Check if ID was passed to URL query
#         todo_id = request.args.get('id')
#         if todo_id:
#             todo = todo_ref.document(todo_id).get()
#             return jsonify(todo.to_dict()), 200
#         else:
#             all_todos = [doc.to_dict() for doc in todo_ref.stream()]
#             return jsonify(all_todos), 200
#     except Exception as e:
#         return f"An Error Occured: {e}"

# @app.route('/update', methods=['POST', 'PUT'])
# def update():
#     """
#         update() : Update document in Firestore collection with request body.
#         Ensure you pass a custom ID as part of json body in post request,
#         e.g. json={'id': '1', 'title': 'Write a blog post today'}
#     """
#     try:
#         id = request.json['id']
#         todo_ref.document(id).update(request.json)
#         return jsonify({"success": True}), 200
#     except Exception as e:
#         return f"An Error Occured: {e}"

# @app.route('/delete', methods=['GET', 'DELETE'])
# def delete():
#     """
#         delete() : Delete a document from Firestore collection.
#     """
#     try:
#         # Check for ID in URL query
#         todo_id = request.args.get('id')
#         todo_ref.document(todo_id).delete()
#         return jsonify({"success": True}), 200
#     except Exception as e:
#         return f"An Error Occured: {e}"

# @app.route("/", methods=["GET"])
# def index():
#     return ("Hello World", HTTPStatus.OK)

# if __name__ == '__main__':
#     port = int(os.environ.get('PORT', 8080))
#     app.run(threaded=True, host='0.0.0.0', port=port)
