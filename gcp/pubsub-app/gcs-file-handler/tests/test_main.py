import base64
from uuid import uuid4

import pytest
import main

@pytest.fixture
def client():
    main.app.testing = True
    return main.app.test_client()


def test_empty_payload(client):
    r = client.post("/", json="")
    assert r.status_code == 400


def test_invalid_payload(client):
    r = client.post("/", json={"nomessage": "invalid"})
    assert r.status_code == 400


def test_invalid_mimetype(client):
    r = client.post("/", json="{ message: true }")
    assert r.status_code == 400


def test_minimally_valid_message(client, capsys):
    r = client.post("/", json={"message": True})
    assert r.status_code == 204

    out, _ = capsys.readouterr()
    assert "Hello World!" in out


def test_populated_message(client, capsys):
    name = str(uuid4())
    data = base64.b64encode(name.encode()).decode()

    r = client.post("/", json={"message": {"data": data}})
    assert r.status_code == 204

    out, _ = capsys.readouterr()
    assert f"Hello {name}!" in out
