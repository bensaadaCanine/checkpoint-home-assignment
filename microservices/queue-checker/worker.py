import json
import logging
import os
import time
from datetime import datetime

import boto3

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] [%(name)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger(__name__)

logger.info("Initializing boto3 clients")
sqs = boto3.client("sqs", region_name=os.getenv("AWS_REGION", "eu-west-1"))
s3 = boto3.client("s3", region_name=os.getenv("AWS_REGION", "eu-west-1"))

QUEUE_URL = os.environ.get("QUEUE_URL")
BUCKET_NAME = os.environ.get("BUCKET_NAME")

while True:

    logger.info("Waiting for messages")
    response = sqs.receive_message(
        QueueUrl=QUEUE_URL, MaxNumberOfMessages=1, WaitTimeSeconds=10
    )

    messages = response.get("Messages", [])
    if messages != []:
        logger.info("Dealing with queued messages")

    for msg in messages:

        body = json.loads(msg["Body"])
        key = f"emails/{datetime.now().timestamp()}.json"

        logger.info("Uploads message to S3 bucket")
        s3.put_object(Bucket=BUCKET_NAME, Key=key, Body=json.dumps(body))

        logger.info("Deletes Message from SQS queue")
        sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])

    time.sleep(10)
