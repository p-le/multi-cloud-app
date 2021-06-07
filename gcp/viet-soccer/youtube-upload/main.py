import os
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
import google.oauth2.credentials

from googleapiclient.http import MediaFileUpload
from flask import Flask, request, redirect, url_for
from http import HTTPStatus



app = Flask(__name__)
YOUTUBE_API_SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]
YOUTUBE_API_SERVICE_NAME  = "youtube"
YOUTUBE_API_VERSION       = "v3"

_credentials = None
_state = None

@app.route("/", methods=["POST"])
def index():
  global _credentials
  envelope = request.get_json()
  print(envelope)

  if not _credentials:
    return redirect('authorize')
  credentials = google.oauth2.credentials.Credentials(**_credentials)
  with googleapiclient.discovery.build(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION, credentials=credentials) as youtube:
    req = youtube.videos().insert(
      part="snippet,status",
      body={
        "snippet": {
          "categoryId": "22",
          "description": "Description of uploaded video.",
          "title": "Test video upload."
        },
        "status": {
          "privacyStatus": "private"
        }
      },
      media_body=MediaFileUpload("/app/KMSp6bFxLIQ_summary.mp4")
    )
    res = req.execute()
    print(res)
  return "Hello World", HTTPStatus.OK


@app.route("/authorize", methods=["GET"])
def authorize():
  global _state
  flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
    os.getenv("CLIENT_SECRET_FILE"),
    scopes=YOUTUBE_API_SCOPES
  )
  flow.redirect_uri = url_for('oauth2callback', _external=True)
  authorization_url, state = flow.authorization_url(
    access_type='offline',
    include_granted_scopes='true'
  )
  print(authorization_url)
  _state = state
  return redirect(authorization_url)



@app.route('/oauth2callback')
def oauth2callback():
  global _state, _credentials
  flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(
    os.getenv("CLIENT_SECRET_FILE"),
    scopes=YOUTUBE_API_SCOPES,
    state=_state
  )
  flow.redirect_uri = url_for('oauth2callback', _external=True)
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
  return redirect(url_for('index'))


if __name__ == "__main__":
  PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
  app.run(host="0.0.0.0", port=PORT, debug=True)
