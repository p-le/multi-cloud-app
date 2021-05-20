import os
import subprocess
from flask import Flask, make_response, request

app = Flask(__name__)


@app.route("/diagram.png", methods=["GET"])
def index():
    # Takes an HTTP GET request with query param dot and
    # returns a png with the rendered DOT diagram in a HTTP response.
    try:
        image = create_diagram(request.args.get("dot"))
        response = make_response(image)
        response.headers.set("Content-Type", "image/png")
        return response

    except Exception as e:
        print("error: {}".format(e))
        # If no graphviz definition or bad graphviz def, return 400
        if "syntax" in str(e):
            return "Bad Request: {}".format(e), 400

        return "Internal Server Error", 500


def create_diagram(dot):
    if not dot:
        raise Exception("syntax: no graphviz definition provided")

    dot_args = [  # These args add a watermark to the dot graphic.
        "-Glabel=Made on Cloud Run",
        "-Gfontsize=10",
        "-Glabeljust=right",
        "-Glabelloc=bottom",
        "-Gfontcolor=gray",
        "-Tpng",
    ]

    # Uses local `dot` binary from Graphviz:
    # https://graphviz.gitlab.io
    image = subprocess.run(
        ["dot"] + dot_args, input=dot.encode("utf-8"), stdout=subprocess.PIPE
    ).stdout
    if not image:
        raise Exception("syntax: bad graphviz definition provided")
    return image


if __name__ == "__main__":
    PORT = int(os.getenv("PORT")) if os.getenv("PORT") else 8080
    app.run(host="0.0.0.0", port=PORT, debug=True)
