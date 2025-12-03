import json
import boto3
import os
import time

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.getenv("TABLE_NAME"))


def lex_response(intent_state: str, fulfillment_state: str, message: str):
    """
    Helper to build a Lex response.
    intent_state: "Fulfilled" | "Failed" | "Error"
    fulfillment_state: "Fulfilled" | "Failed" | "Error"
    message: user-facing message text
    """
    return {
        "sessionState": {
            "dialogAction": {"type": "Close", "fulfillmentState": fulfillment_state},
            "intent": {"name": "WriteJournalIntent", "state": intent_state},
        },
        "messages": [{"contentType": "PlainText", "content": message}],
    }


def extract_journal_entry(event):
    try:
        return event["sessionState"]["intent"]["slots"]["entry"]["value"][
            "originalValue"
        ]
    except (KeyError, TypeError):
        return None


def lambda_handler(event, context):
    journal_entry = extract_journal_entry(event)
    if not journal_entry:
        return lex_response(
            intent_state="Error",
            fulfillment_state="Error",
            message="Unable to parse journal entry.",
        )

    item = {
        "id": str(int(time.time())),
        "entryText": journal_entry,
    }

    try:
        table.put_item(Item=item)
        return lex_response(
            intent_state="Fulfilled",
            fulfillment_state="Fulfilled",
            message="Journal entry successfully saved.",
        )
    except Exception as e:
        print(f"Error writing to DynamoDB: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)}),
        }
