import base64
import os
from flask import Flask, request

app = Flask(__name__)

@app.route("/", methods=["POST"])
def index():
    envelope = request.get_json()
    token = request.args.get('token', '')
    print(token)
    if not envelope:
        msg = "no Pub/Sub message received"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 400
    if not isinstance(envelope, dict) or "message" not in envelope:
        msg = "invalid Pub/Sub message format"
        print(f"error: {msg}")
        return f"Bad Request: {msg}", 400
    pubsub_message = envelope["message"]
    name = "World"
    if isinstance(pubsub_message, dict) and "data" in pubsub_message:
        name = base64.b64decode(pubsub_message["data"]).decode("utf-8").strip()
    print(f"Hello {name}!")
    return ("", 204)


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
    app.run(host="0.0.0.0", port=PORT, debug=True)
