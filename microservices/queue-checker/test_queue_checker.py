import json
import os
import sys
import unittest
from datetime import datetime, timezone
from unittest.mock import patch

import app
from botocore.exceptions import ClientError

SAMPLE_MSG = {
    "MessageId": "msg-001",
    "ReceiptHandle": "rh-abc123",
    "Body": json.dumps(
        {
            "data": {
                "email_subject": "Happy new year!",
                "email_sender": "John doe",
                "email_timestream": "1693561101",
                "email_content": "Just want to say... Happy new year!!!",
            },
            "received_at": "2024-01-01T00:00:00Z",
        }
    ),
}


class TestBuildS3Key(unittest.TestCase):

    def test_key_contains_partitions(self):
        with patch("app.datetime") as mock_dt:
            mock_dt.now.return_value = datetime(2024, 6, 15, tzinfo=timezone.utc)
            key = app.build_s3_key("msg-xyz")

        self.assertIn("2024", key)
        self.assertIn("06", key)
        self.assertIn("15", key)
        self.assertIn("msg-xyz.json", key)
        self.assertTrue(key.startswith(app.S3_PREFIX))

    def test_key_starts_with_prefix(self):
        key = app.build_s3_key("any-id")
        self.assertTrue(key.startswith(app.S3_PREFIX))


class TestUploadToS3(unittest.TestCase):

    @patch("app.s3_client")
    def test_upload_calls_put_object(self, mock_s3):
        app.S3_BUCKET_NAME = "test-bucket"
        mock_s3.put_object.return_value = {}

        key = app.upload_to_s3("msg-001", {"foo": "bar"})

        mock_s3.put_object.assert_called_once()
        kwargs = mock_s3.put_object.call_args[1]
        self.assertEqual(kwargs["Bucket"], "test-bucket")
        self.assertEqual(kwargs["ContentType"], "application/json")
        self.assertIn("msg-001", key)

    @patch("app.s3_client")
    def test_upload_content_is_valid_json(self, mock_s3):
        mock_s3.put_object.return_value = {}
        app.upload_to_s3("msg-002", {"key": "value"})
        body = mock_s3.put_object.call_args[1]["Body"]
        parsed = json.loads(body)
        self.assertEqual(parsed["key"], "value")


class TestProcessMessage(unittest.TestCase):

    @patch("app.delete_message")
    @patch("app.upload_to_s3")
    def test_success_returns_true(self, mock_upload, mock_delete):
        mock_upload.return_value = "emails/2024/01/01/msg-001.json"
        result = app.process_message(SAMPLE_MSG)
        self.assertTrue(result)
        mock_upload.assert_called_once()
        mock_delete.assert_called_once_with(SAMPLE_MSG["ReceiptHandle"])

    @patch("app.delete_message")
    @patch("app.upload_to_s3")
    def test_bad_json_returns_false(self, mock_upload, mock_delete):
        bad_msg = {**SAMPLE_MSG, "Body": "not json{{"}
        result = app.process_message(bad_msg)
        self.assertFalse(result)
        mock_upload.assert_not_called()
        mock_delete.assert_not_called()

    @patch("app.delete_message")
    @patch("app.upload_to_s3")
    def test_s3_failure_returns_false(self, mock_upload, mock_delete):
        mock_upload.side_effect = ClientError(
            {"Error": {"Code": "NoSuchBucket", "Message": "gone"}}, "PutObject"
        )
        result = app.process_message(SAMPLE_MSG)
        self.assertFalse(result)
        mock_delete.assert_not_called()

    @patch("app.delete_message")
    @patch("app.upload_to_s3")
    def test_delete_failure_still_returns_true(self, mock_upload, mock_delete):
        mock_upload.return_value = "emails/2024/01/01/msg-001.json"
        mock_delete.side_effect = ClientError(
            {"Error": {"Code": "ReceiptHandleIsInvalid", "Message": "expired"}},
            "DeleteMessage",
        )
        result = app.process_message(SAMPLE_MSG)
        self.assertTrue(result)


class TestReceiveMessages(unittest.TestCase):

    @patch("app.sqs_client")
    def test_returns_messages(self, mock_sqs):
        mock_sqs.receive_message.return_value = {"Messages": [SAMPLE_MSG]}
        msgs = app.receive_messages()
        self.assertEqual(len(msgs), 1)

    @patch("app.sqs_client")
    def test_empty_queue_returns_empty_list(self, mock_sqs):
        mock_sqs.receive_message.return_value = {}
        msgs = app.receive_messages()
        self.assertEqual(msgs, [])


if __name__ == "__main__":
    unittest.main(verbosity=2)
