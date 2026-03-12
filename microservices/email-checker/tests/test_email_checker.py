"""
Unit tests for email-checker (Microservice 1 – REST API).

Run with:
    pip install pytest boto3 flask
    pytest microservices/email-checker/tests/ -v
"""

import json
import sys
import os
import unittest
from unittest.mock import patch
from datetime import datetime, timezone

# ── Make app.py importable ────────────────────────────────────────────────────
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import app

VALID_TOKEN = "$DJISA<$#45ex3RtYr"

VALID_PAYLOAD = {
    "data": {
        "email_subject": "Happy new year!",
        "email_sender": "John doe",
        "email_timestream": "1693561101",
        "email_content": "Just want to say... Happy new year!!!",
    },
    "token": VALID_TOKEN,
}


class TestValidatePayload(unittest.TestCase):

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_valid_payload_passes(self, _):
        ok, err = app.validate_payload(VALID_PAYLOAD)
        self.assertTrue(ok)
        self.assertEqual(err, "")

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_invalid_token_rejected(self, _):
        payload = {**VALID_PAYLOAD, "token": "wrong"}
        ok, err = app.validate_payload(payload)
        self.assertFalse(ok)
        self.assertIn("Invalid token", err)

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_missing_token_field(self, _):
        payload = {"data": VALID_PAYLOAD["data"]}
        ok, err = app.validate_payload(payload)
        self.assertFalse(ok)
        self.assertIn("token", err.lower())

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_missing_data_field(self, _):
        payload = {"token": VALID_TOKEN}
        ok, err = app.validate_payload(payload)
        self.assertFalse(ok)
        self.assertIn("data", err.lower())

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_missing_one_data_subfield(self, _):
        data = {**VALID_PAYLOAD["data"]}
        del data["email_content"]
        ok, err = app.validate_payload({"data": data, "token": VALID_TOKEN})
        self.assertFalse(ok)
        self.assertIn("email_content", err)

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_empty_string_data_subfield(self, _):
        data = {**VALID_PAYLOAD["data"], "email_subject": "   "}
        ok, err = app.validate_payload({"data": data, "token": VALID_TOKEN})
        self.assertFalse(ok)
        self.assertIn("email_subject", err)

    @patch("app.get_expected_token", side_effect=Exception("SSM down"))
    def test_ssm_unavailable_returns_error(self, _):
        ok, err = app.validate_payload(VALID_PAYLOAD)
        self.assertFalse(ok)
        self.assertIn("unavailable", err.lower())


class TestHealthEndpoints(unittest.TestCase):

    def setUp(self):
        app.app.config["TESTING"] = True
        self.client = app.app.test_client()

    def test_health_returns_200(self):
        resp = self.client.get("/health")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.get_json()["status"], "healthy")

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    @patch("app.sqs_client")
    def test_ready_returns_200_when_dependencies_ok(self, mock_sqs, _):
        mock_sqs.get_queue_attributes.return_value = {}
        resp = self.client.get("/ready")
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.get_json()["ready"])

    @patch("app.get_expected_token", side_effect=Exception("SSM down"))
    @patch("app.sqs_client")
    def test_ready_returns_503_when_ssm_down(self, mock_sqs, _):
        mock_sqs.get_queue_attributes.return_value = {}
        resp = self.client.get("/ready")
        self.assertEqual(resp.status_code, 503)
        self.assertFalse(resp.get_json()["ready"])


class TestSendEndpoint(unittest.TestCase):

    def setUp(self):
        app.app.config["TESTING"] = True
        self.client = app.app.test_client()

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    @patch("app.sqs_client")
    def test_valid_payload_returns_200(self, mock_sqs, _):
        mock_sqs.send_message.return_value = {"MessageId": "test-id-123"}
        resp = self.client.post("/send", json=VALID_PAYLOAD)
        self.assertEqual(resp.status_code, 200)
        body = resp.get_json()
        self.assertEqual(body["status"], "published")
        self.assertEqual(body["message_id"], "test-id-123")

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    def test_wrong_token_returns_422(self, _):
        payload = {**VALID_PAYLOAD, "token": "bad"}
        resp = self.client.post("/send", json=payload)
        self.assertEqual(resp.status_code, 422)

    def test_non_json_body_returns_400(self):
        resp = self.client.post("/send", data="not json", content_type="text/plain")
        self.assertEqual(resp.status_code, 400)

    @patch("app.get_expected_token", return_value=VALID_TOKEN)
    @patch("app.sqs_client")
    def test_token_not_forwarded_to_sqs(self, mock_sqs, _):
        mock_sqs.send_message.return_value = {"MessageId": "abc"}
        self.client.post("/send", json=VALID_PAYLOAD)
        sent = json.loads(mock_sqs.send_message.call_args[1]["MessageBody"])
        self.assertNotIn("token", sent)
        self.assertIn("data", sent)
        self.assertIn("received_at", sent)


if __name__ == "__main__":
    unittest.main(verbosity=2)
