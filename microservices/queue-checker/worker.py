import json
import os
import time
from datetime import datetime

import boto3

sqs = boto3.client("sqs", region_name=os.getenv("AWS_REGION", "eu-west-1"))
s3 = boto3.client("s3", region_name=os.getenv("AWS_REGION", "eu-west-1"))

QUEUE_URL = os.environ.get("QUEUE_URL")
BUCKET_NAME = os.environ.get("BUCKET_NAME")

while True:

    response = sqs.receive_message(
        QueueUrl=QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=10
    )

    messages = response.get("Messages", [])

    for msg in messages:

        body = json.loads(msg["Body"])
        key = f"emails/{datetime.now().timestamp()}.json"

        s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=json.dumps(body))

        sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])

    time.sleep(5)
