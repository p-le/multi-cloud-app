import os
from google.cloud import pubsub_v1
from flask import Flask, abort, request, jsonify
from http import HTTPStatus

from proto import message

app = Flask(__name__)
client = None
project_id = os.getenv("PROJECT_ID")
youtube_comment_endpoint = os.getenv("YOUTUBE_COMMENT_ENDPOINT")
youtube_upload_endpoint = os.getenv("YOUTUBE_UPLOAD_ENDPOINT")

@app.before_first_request
def init_pubsub_emulator() -> None:
  global client
  client = pubsub_v1.PublisherClient()
  youtube_comment_topic_path = client.topic_path(project_id, "viet-soccer-youtube-comment")
  topic = client.create_topic(request={"name": youtube_comment_topic_path})
  print(f"Created topic: {topic.name}")
  youtube_upload_topic_path = client.topic_path(project_id, "viet-soccer-youtube-upload")
  topic = client.create_topic(request={"name": youtube_upload_topic_path})
  print(f"Created topic: {topic.name}")

  with pubsub_v1.SubscriberClient() as subscriber:
      subscription_path = subscriber.subscription_path(project_id, "viet-soccer-youtube-comment")
      push_config = pubsub_v1.types.PushConfig(push_endpoint=youtube_comment_endpoint)
      subscription = subscriber.create_subscription(
        request={"name": subscription_path, "topic": youtube_comment_topic_path, "push_config": push_config}
      )
      print(f"Push subscription created: subcription={subscription} endpoint={youtube_comment_endpoint}.")
      subscription_path = subscriber.subscription_path(project_id, "viet-soccer-youtube-upload")
      push_config = pubsub_v1.types.PushConfig(push_endpoint=youtube_upload_endpoint)
      subscription = subscriber.create_subscription(
        request={"name": subscription_path, "topic": youtube_upload_topic_path, "push_config": push_config}
      )
      print(f"Push subscription created: subcription={subscription} endpoint={youtube_upload_endpoint}.")


@app.route("/", methods=["GET"])
def index():
  return "Hello World", HTTPStatus.OK


@app.route("/youtube/comment", methods=["POST"])
def youtube_comment():
  """
  curl -X POST -H "Content-Type: application/json" -d '{"data":"hello world"}' localhost:8087/youtube/comment
  """
  global client
  try:
    data = request.json['data']
    topic_path = client.topic_path(project_id, "viet-soccer-youtube-comment")


    future = client.publish(topic_path, data.encode("utf-8"), origin="python-sample", username="gcp")
    message_id = future.result()
    print(f"Published data={data} to topic={topic_path}: message_id={message_id}")
  except Exception as e:
    print(e)
    abort(HTTPStatus.BAD_REQUEST, description="Invalid Request")

  return jsonify({"success": True}), HTTPStatus.OK


@app.route("/youtube/upload", methods=["POST"])
def youtube_upload():
  """
  curl -X POST -H "Content-Type: application/json" -d '{"data":"hello world"}' localhost:8087/youtube/upload
  """
  global client
  try:
    data = request.json['data']
    topic_path = client.topic_path(project_id, "viet-soccer-youtube-upload")
    future = client.publish(topic_path, data.encode("utf-8"), origin="python-sample", username="gcp")
    message_id = future.result()
    print(f"Published data={data} to topic={topic_path}: message_id={message_id}")
  except Exception as e:
    print(e)
    abort(HTTPStatus.BAD_REQUEST, description="Invalid Request")

  return jsonify({"success": True}), HTTPStatus.OK



if __name__ == "__main__":
  PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
  app.run(host="0.0.0.0", port=PORT, debug=True)
