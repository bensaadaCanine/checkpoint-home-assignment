import json
import os

import boto3
import logger
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

logger = logging.getLogger("uvicorn.error")

app = FastAPI()

sqs: "boto3.client"
ssm: "boto3.client"
QUEUE_URL: str
TOKEN_PARAM: str


class EmailData(BaseModel):
    email_subject: str
    email_sender: str
    email_timestream: str
    email_content: str


class RequestModel(BaseModel):
    data: EmailData
    token: str


@app.on_event("startup")
def startup_event():
    global sqs, ssm, QUEUE_URL, TOKEN_PARAM

    QUEUE_URL = os.environ["QUEUE_URL"]
    region = os.getenv("AWS_REGION", "eu-west-1")

    logger.info("Initializing boto3 clients")
    sqs = boto3.client("sqs", region_name=region)
    ssm = boto3.client("ssm", region_name=region)

    logger.info("Retrieving validation token from SSM")
    TOKEN_PARAM = ssm.get_parameter(
        Name="/email-checker/validation-token", WithDecryption=True
    )["Parameter"]["Value"]

    logger.info("Startup initialization completed")


@app.post("/publish")
def publish(request: RequestModel):

    logger.info("Dealing with incoming message")
    if request.token != TOKEN_PARAM:
        logger.error("Message has invalid token")
        raise HTTPException(status_code=401, detail="Invalid token")

    logger.info("Sending message to queue")
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=request.json())

    return {"status": "Message sent to queue"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def readiness():
    return {"status": "ready"}
