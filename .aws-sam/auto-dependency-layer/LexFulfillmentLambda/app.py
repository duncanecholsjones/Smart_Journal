import json
import boto3
import os
import time

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):

    table_name = os.getenv("TABLE_NAME")
    table = dynamodb.Table(table_name)

    try:
        user_input = event["sessionState"]["intent"]["slots"]["entry"]["value"][
            "interpretedValue"
        ]
    except KeyError:
        return {
            "sessionState": {
                "dialogAction": {"type": "Close", "fulfillmentState": "Error"},
                "intent": {"name": "WriteJournalIntent", "state": "Error"},
            },
            "messages": [
                {
                    "contentType": "PlainText",
                    "content": "Unable to parse journal entry.",
                }
            ],
        }

    item = {"id": str(time.time()), "entryText": user_input}

    try:
        table.put_item(Item=item)
        return {
            "sessionState": {
                "dialogAction": {"type": "Close", "fulfillmentState": "Fulfilled"},
                "intent": {"name": "WriteJournalIntent", "state": "Fulfilled"},
            },
            "messages": [
                {
                    "contentType": "PlainText",
                    "content": "Journal response successfully saved.",
                }
            ],
        }

    except Exception as e:
        print(f"Error writing to DynamoDB: {e}")
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}
