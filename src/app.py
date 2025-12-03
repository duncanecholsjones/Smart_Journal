import json
import boto3
import os
import time
from datetime import datetime, timezone

s3 = boto3.client("s3")
BUCKET = os.getenv("BUCKET_NAME")


def lex_response(intent_state: str, fulfillment_state: str, message: str):
    return {
        "sessionState": {
            "dialogAction": {"type": "Close", "fulfillmentState": fulfillment_state},
            "intent": {"name": "WriteJournalIntent", "state": intent_state},
        },
        "messages": [{"contentType": "PlainText", "content": message}],
    }


def extract_journal_entry(event):
    try:
        return event["sessionState"]["intent"]["slots"]["journalEntry"]["value"][
            "originalValue"
        ]
    except (KeyError, TypeError):
        return None


def lambda_handler(event, context):
    journal_text = extract_journal_entry(event)
    if not journal_text:
        return lex_response("Error", "Error", "Unable to parse journal entry.")

    # Timestamp formatting
    now = datetime.now(timezone.utc)
    iso_time = now.isoformat()
    epoch = int(now.timestamp())

    filename = f"duncan_{epoch}.txt"
    body = f"userId: duncan\nentryId: {iso_time}\ntimestamp: {iso_time}\nentry: {journal_text}\n"

    try:
        s3.put_object(
            Bucket=BUCKET,
            Key=filename,
            Body=body.encode("utf-8"),
            ContentType="text/plain",
        )

        return lex_response(
            intent_state="Fulfilled",
            fulfillment_state="Fulfilled",
            message="Journal entry successfully saved.",
        )

    except Exception as e:
        print(f"Error writing to S3: {e}")
        return {"statusCode": 500, "body": json.dumps({"error": str(e)})}
