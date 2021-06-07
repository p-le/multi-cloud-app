import os
import google_auth_oauthlib.flow
import googleapiclient.discovery
import googleapiclient.errors
from google.cloud import pubsub_v1
from flask import Flask, request
from http import HTTPStatus

app = Flask(__name__)
scopes = ["https://www.googleapis.com/auth/youtube.force-ssl"]

API_SERVICE_NAME = "youtube"
API_VERSION = "v3"


@app.before_first_request
def init_pubsub_emulator() -> None:
  if os.environ["PUBSUB_EMULATOR_HOST"]:
    publisher = pubsub_v1.PublisherClient()
    project_id = os.getenv("PROJECT_ID")
    topic_id = os.getenv("TOPIC_ID")
    topic_path = publisher.topic_path(project_id, topic_id)
    topic = publisher.create_topic(request={"name": topic_path})
    print(f"Created topic: {topic.name}")


@app.route("/", methods=["POST"])
def index():
  envelope = request.get_json()
  print(envelope)
  client_secrets_file = "YOUR_CLIENT_SECRET_FILE.json"
  flow = google_auth_oauthlib.flow.InstalledAppFlow.from_client_secrets_file(client_secrets_file, scopes)
  # flow = google_auth_oauthlib.flow.Flow.from_client_secrets_file(client_secrets_file, scopes)

  credentials = flow.run_console()
  with googleapiclient.discovery.build(API_SERVICE_NAME, API_VERSION, credentials=credentials) as youtube:
    request = youtube.commentThreads().insert(
        part="snippet",
        body={
          "snippet": {
            "videoId": "YOUR_VIDEO_ID",
            "topLevelComment": {
              "snippet": {
                "textOriginal": "This is the start of a comment thread."
              }
            }
          }
        }
    )
    response = request.execute()
    print(response)

  return "Hello World", HTTPStatus.OK


if __name__ == "__main__":
  PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
  app.run(host="0.0.0.0", port=PORT, debug=True)
