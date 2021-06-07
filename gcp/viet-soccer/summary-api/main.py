import numpy as np
import os
import time

from flask import Flask, abort, request, jsonify
from http import HTTPStatus
from moviepy.editor import VideoFileClip, concatenate_videoclips


app = Flask(__name__)
app.config["INPUT_DIR"]         = os.getenv("INPUT_DIR", "/dist/download")
app.config["INPUT_GCS_BUCKET"]  = os.getenv("INPUT_GCS_BUCKET", "/dist")
app.config["OUTPUT_DIR"]        = os.getenv("OUTPUT_DIR", "/dist/summary")
app.config["OUTPUT_FPS"]        = int(os.getenv("OUTPUT_FPS")) if os.getenv("OUTPUT_FPS") else 24
# Number of seconds around an event
app.config["DIFF_FROM_PEAK"]    = int(os.getenv("DIFF_FROM_PEAK")) if os.getenv("DIFF_FROM_PEAK") else 10

@app.errorhandler(HTTPStatus.BAD_REQUEST)
def invalid_request(e):
    return jsonify({"success": False, "error": str(e)}), HTTPStatus.BAD_REQUEST

@app.errorhandler(HTTPStatus.NOT_FOUND)
def not_found(e):
    return jsonify({"success": False, "error": str(e)}), HTTPStatus.NOT_FOUND

@app.route("/", methods=["GET"])
def index():
    return ("Hello World", HTTPStatus.OK)

def _analyze_sound(video, avg_step=10):
    cut = lambda i: video.audio.subclip(i, i+1).to_soundarray(fps=22000)
    volume = lambda array: np.sqrt(((1.0 * array) ** 2).mean())
    volumes = [volume(cut(i)) for i in range(0, int(video.duration-1))]
    averaged_volumes = np.array([sum(volumes[i:i+avg_step])/avg_step for i in range(len(volumes)-avg_step)])
    increases = np.diff(averaged_volumes)[:-1]>=0
    decreases = np.diff(averaged_volumes)[1:]<=0
    peaks_times = (increases * decreases).nonzero()[0]
    peaks_vols = averaged_volumes[peaks_times]
    peaks_times = peaks_times[peaks_vols > np.percentile(peaks_vols, 90)]
    return peaks_times, averaged_volumes


@app.route("/summary", methods=["POST"])
def summary():
    """
    Test:
    curl -X POST -H "Content-Type: application/json" -d '{"video_file":"edhdJWzm6So_7d0e52ab3669cf6c72b68a7bbc27e79c.mp4"}' localhost:8081/summary
    """
    try:
        start_time = time.time()

        video_file = request.json['video_file']
        fps = app.config["OUTPUT_FPS"]
        input_dir = app.config["INPUT_DIR"]
        output_dir = app.config["OUTPUT_DIR"]
        diff_from_peak = app.config["DIFF_FROM_PEAK"]
        file_path = f"{input_dir}/{video_file}"
        video = VideoFileClip(file_path)
        print(f"Start Processing Video File: {file_path}")
        peaks_times, averaged_volumes = _analyze_sound(video)
        final_times=[peaks_times[0]]
        for t in peaks_times:
            if (t - final_times[-1]) < 60:
                if averaged_volumes[t] > averaged_volumes[final_times[-1]]:
                    final_times[-1] = t
            else:
                final_times.append(t)
        print(f"Number of important events: {len(final_times)}")
        final_video = concatenate_videoclips([video.subclip(
                        max(t - diff_from_peak, 0),
                        min(t + diff_from_peak, video.duration)
                    ) for t in final_times], method='compose')
        final_video.write_videofile(f"{output_dir}/{video_file}", codec="libx264", audio_codec="aac", fps=fps)
        print(f"Summarized time: {time.time() - start_time} seconds")
        return jsonify({"success": True}), HTTPStatus.OK
    except Exception as e:
        print(f"Error Occured: {e}")
        abort(HTTPStatus.BAD_REQUEST, description="Invalid Request")


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
    app.run(host="0.0.0.0", port=PORT, debug=True)
