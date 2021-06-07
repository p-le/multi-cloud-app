import os
import base64
import logging
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
import google.oauth2.credentials
import grpc
from werkzeug.wrappers import response
import credential_pb2_grpc
import credential_pb2
from flask import Flask, request, redirect, url_for
from http import HTTPStatus

class ReverseProxied(object):
  def __init__(self, app):
    self.app = app

  def __call__(self, environ, start_response):
    environ['wsgi.url_scheme'] = 'https'
    return self.app(environ, start_response)


app = Flask(__name__)
if os.getenv("ENV", "development") == "production":
  app.wsgi_app = ReverseProxied(app.wsgi_app)

YOUTUBE_API_SCOPES        = ["https://www.googleapis.com/auth/youtube.force-ssl"]
YOUTUBE_API_SERVICE_NAME  = "youtube"
YOUTUBE_API_VERSION       = "v3"
FIREBASE_API_HOST         = os.getenv("FIREBASE_API_HOST")
FIREBASE_API_PORT         = int(os.getenv("FIREBASE_API_PORT"))

_credentials = None
_state = None
_stub = None

@app.before_first_request
def create_table() -> None:
    global _stub
    channel = grpc.insecure_channel('{}:{}'.format(FIREBASE_API_HOST, FIREBASE_API_PORT))
    _stub = credential_pb2_grpc.OauthCredentialsStub(channel)


@app.route("/", methods=["POST"])
def index():
  global _credentials
  envelope = request.get_json()
  print(envelope)
  if not envelope:
    msg = "no Pub/Sub message received"
    print(f"error: {msg}")
    return f"Bad Request: {msg}", HTTPStatus.BAD_REQUEST

  if not isinstance(envelope, dict) or "message" not in envelope:
      msg = "invalid Pub/Sub message format"
      print(f"error: {msg}")
      return f"Bad Request: {msg}", HTTPStatus.BAD_REQUEST

  message = envelope["message"]

  if isinstance(message, dict) and "data" in message:
    video_id = base64.b64decode(message["data"]).decode("utf-8").strip()

  if not video_id:
    print(f"Error: Invalid video_id")
    return f"Bad Request: Invalid video_id", HTTPStatus.BAD_REQUEST

  response = _stub.GetCredentials(credential_pb2.GetCredentialsRequest(host=request.headers['Host']))
  _credentials = response.credentials
  if not _credentials:
    return redirect('authorize')

  credentials = google.oauth2.credentials.Credentials(**_credentials)
  with googleapiclient.discovery.build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION, credentials=credentials) as youtube:
    req = youtube.commentThreads().insert(
        part="snippet",
        body={
          "snippet": {
            "videoId": video_id,
            "topLevelComment": {
              "snippet": {
                "textOriginal": "Comment automatically through API"
              }
            }
          }
        }
    )
    res = req.execute()
    print(res)
  return "Hello World", HTTPStatus.OK



@app.route("/authorize", methods=["GET"])
def authorize():
  global _state, _stub
  flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
    os.getenv("CLIENT_SECRET_FILE"),
    scopes=YOUTUBE_API_SCOPES
  )
  if "OAUTHLIB_INSECURE_TRANSPORT" in os.environ:
    flow.redirect_uri = url_for('oauth2callback', _external=True)
  else:
    flow.redirect_uri = url_for('oauth2callback', _external=True, _scheme='https')

  authorization_url, state = flow.authorization_url(
    access_type='offline',
    include_granted_scopes='true'
  )
  print(authorization_url)
  _state = state
  return redirect(authorization_url)



@app.route('/oauth2callback')
def oauth2callback():
  global _state, _credentials, _stub
  flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
    os.getenv("CLIENT_SECRET_FILE"),
    scopes=YOUTUBE_API_SCOPES,
    state=_state
  )

  if "OAUTHLIB_INSECURE_TRANSPORT" in os.environ:
    flow.redirect_uri = url_for('oauth2callback', _external=True)
  else:
    flow.redirect_uri = url_for('oauth2callback', _external=True, _scheme='https')

  authorization_response = request.url
  flow.fetch_token(authorization_response=authorization_response)
  credentials = flow.credentials
  print(credentials)

  _credentials = {
    'token': credentials.token,
    'refresh_token': credentials.refresh_token,
    'token_uri': credentials.token_uri,
    'client_id': credentials.client_id,
    'client_secret': credentials.client_secret,
    'scopes': credentials.scopes
  }

  result = _stub.SaveCredentials(credential_pb2.SaveCredentialsRequest(
    host=request.headers['Host'],
    credentials=credential_pb2.Credentials(**_credentials))
  )
  print(result)
  return redirect(url_for('index'))


if __name__ == "__main__":
  PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
  logging.info(f"Server listening on port {PORT}")
  app.run(host="0.0.0.0", port=PORT, debug=True)
