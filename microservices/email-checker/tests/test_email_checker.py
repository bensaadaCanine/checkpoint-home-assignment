from unittest.mock import patch

import pytest
from app import app
from fastapi.testclient import TestClient

client = TestClient(app)

payload_valid = {
    "data": {
        "email_subject": "Hello",
        "email_sender": "John",
        "email_timestream": "1693561101",
        "email_content": "Test content",
    },
    "token": "correct_token",
}

payload_invalid = dict(payload_valid)
payload_invalid["token"] = "wrong_token"


@patch("app.ssm.get_parameter")
@patch("app.sqs.send_message")
def test_publish_valid(mock_sqs, mock_ssm):
    mock_ssm.return_value = {"Parameter": {"Value": "correct_token"}}
    response = client.post("/publish", json=payload_valid)
    assert response.status_code == 200
    mock_sqs.assert_called_once()


@patch("app.ssm.get_parameter")
def test_publish_invalid_token(mock_ssm):
    mock_ssm.return_value = {"Parameter": {"Value": "correct_token"}}
    response = client.post("/publish", json=payload_invalid)
    assert response.status_code == 401
