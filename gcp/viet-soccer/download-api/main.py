import os
import time
import hashlib

from flask import Flask, abort, request, jsonify
from http import HTTPStatus
from pytube import YouTube


app = Flask(__name__)
app.config["RESOLUTION"]    = os.getenv("RESOLUTION", "720p")
app.config["OUTPUT_DIR"]    = os.getenv("OUTPUT_DIR", "/dist")
app.config["OUTPUT_FPS"]    = int(os.getenv("OUTPUT_FPS")) if os.getenv("OUTPUT_FPS") else 24
app.config["YOUTUBE_URI"]   = "https://www.youtube.com/watch"

@app.errorhandler(HTTPStatus.BAD_REQUEST)
def invalid_request(e):
    return jsonify({"success": False, "error": str(e)}), HTTPStatus.BAD_REQUEST

@app.errorhandler(HTTPStatus.NOT_FOUND)
def not_found(e):
    return jsonify({"success": False, "error": str(e)}), HTTPStatus.NOT_FOUND

@app.route("/", methods=["GET"])
def index():
    return ("Hello World", HTTPStatus.OK)


@app.route("/download/youtube", methods=["POST"])
def download_youtube():
    """
    Test: curl -X POST -H "Content-Type: application/json" -d '{"video_id":"edhdJWzm6So"}' localhost:8080/download/youtube
    """
    try:
        video_id = request.json['video_id']
        video_url = f"{app.config['YOUTUBE_URI']}?v={video_id}"
        print(f"Download URL: {video_url}")
        start_time = time.time()
        resolution = app.config["RESOLUTION"]
        output_dir = app.config["OUTPUT_DIR"]
        yt = YouTube(video_url)
        streams = yt.streams.filter(res=resolution, file_extension='mp4')
        if len(streams) > 0:
            file_path = streams.first().download(
                output_path=output_dir,
                filename=hashlib.md5(yt.title.encode('utf-8')).hexdigest(),
                filename_prefix=f"{video_id}_"
            )
        else:
            print(f"Not found video with the resolution: {resolution}, Please consider to downgrade!")
            abort(HTTPStatus.NOT_FOUND, description=f"Not found {resolution}")

        print(f"Download Time: {time.time() - start_time} seconds")
        return jsonify({"success": True, "file_path": file_path}), HTTPStatus.OK
    except Exception as e:
        print(f"Error Occured: {e}")
        abort(HTTPStatus.BAD_REQUEST, description="Invalid Request")


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
    app.run(host="0.0.0.0", port=PORT, debug=True)
