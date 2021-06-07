import os
from flask import Flask, make_response, render_template
from socket import gethostname
from http import HTTPStatus
from utils.cpu_burner import CpuBurner
from utils.gce_metadata import get_zone, get_template


app = Flask(__name__)
_is_healthy = True
_cpu_burner = None


@app.before_first_request
def init():
    global _cpu_burner
    _cpu_burner = CpuBurner()


@app.route("/hello", methods=["GET"])
@app.route('/hello/<name>', methods=["GET"])
def hello(name="Guest") -> str:
    global _cpu_burner, _is_healthy
    zone, err = get_zone()
    template, err = get_template()
    context = {
        "name": name,
        "hostname": gethostname(),
        "zone": zone,
        "template": template,
        "healthy": _is_healthy,
        "working": _cpu_burner.is_running()
    }
    return render_template("index.html", **context)


@app.route('/health')
def health():
    """Returns the simulated 'healthy'/'unhealthy' status of the server.
    Returns:
        HTTP status 200 if 'healthy', HTTP status 500 if 'unhealthy'
    """
    global _is_healthy
    template = render_template('health.html', healthy=_is_healthy)
    return make_response(template, HTTPStatus.OK if _is_healthy else HTTPStatus.INTERNAL_SERVER_ERROR)


@app.route('/make/healthy')
def make_healthy():
    """Sets the server to simulate a 'healthy' status."""
    global _cpu_burner, _is_healthy
    _is_healthy = True
    zone, err = get_zone()
    template, err = get_template()
    context = {
        "hostname": gethostname(),
        "zone": zone,
        "template": template,
        "healthy": _is_healthy,
        "working": _cpu_burner.is_running()
    }
    template = render_template('index.html', **context)
    response = make_response(template, HTTPStatus.FOUND)
    response.headers['Location'] = '/hello'
    return response


@app.route('/make/unhealthy')
def make_unhealthy():
    """Sets the server to simulate an 'unhealthy' status."""
    global _cpu_burner, _is_healthy
    _is_healthy = False
    zone, err = get_zone()
    template, err = get_template()
    context = {
        "hostname": gethostname(),
        "zone": zone,
        "template": template,
        "healthy": _is_healthy,
        "working": _cpu_burner.is_running()
    }
    template = render_template('index.html', **context)
    response = make_response(template, HTTPStatus.FOUND)
    response.headers['Location'] = '/hello'
    return response


@app.route('/start/load')
def start_load():
    """Sets the server to simulate high CPU load."""
    global _cpu_burner, _is_healthy
    _cpu_burner.start()
    zone, err = get_zone()
    template, err = get_template()
    context = {
        "hostname": gethostname(),
        "zone": zone,
        "template": template,
        "healthy": _is_healthy,
        "working": True
    }
    template = render_template('index.html', **context)
    response = make_response(template, HTTPStatus.FOUND)
    response.headers['Location'] = '/hello'
    return response


@app.route('/stop/load')
def stop_load():
    """Sets the server to stop simulating CPU load."""
    global _cpu_burner, _is_healthy
    _cpu_burner.stop()
    zone, err = get_zone()
    template, err = get_template()
    context = {
        "hostname": gethostname(),
        "zone": zone,
        "template": template,
        "healthy": _is_healthy,
        "working": True
    }
    template = render_template('index.html', **context)
    response = make_response(template, HTTPStatus.FOUND)
    response.headers['Location'] = '/hello'
    return response


if __name__ == "__main__":
    PORT = int(os.getenv("PORT", 8080))
    print(f"Server listening on port {PORT}")
    app.run(host="0.0.0.0", port=PORT, debug=True)

