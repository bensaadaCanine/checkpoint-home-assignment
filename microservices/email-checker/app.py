import json
import os

import boto3
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI()

sqs = boto3.client("sqs", region_name=os.getenv("AWS_REGION", "eu-west-1"))
ssm = boto3.client("ssm", region_name=os.getenv("AWS_REGION", "eu-west-1"))

QUEUE_URL = os.environ.get("QUEUE_URL")
TOKEN_PARAM = ssm.get_parameter(
    Name="/email-checker/validation-token", WithDecryption=True
)["Parameter"]["Value"]


class EmailData(BaseModel):
    email_subject: str
    email_sender: str
    email_timestream: str
    email_content: str


class RequestModel(BaseModel):
    data: EmailData
    token: str


@app.post("/publish")
def publish(request: RequestModel):

    if request.token != TOKEN_PARAM:
        raise HTTPException(status_code=401, detail="Invalid token")

    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=request.json())

    return {"status": "Message sent to queue"}
