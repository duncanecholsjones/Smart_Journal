import json
import boto3

# Initialize the DynamoDB resource
dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):
    # Specify your DynamoDB table name
    table_name = "MyTable"
    table = dynamodb.Table(table_name)

    # Define the item you want to write. This example assumes your table
    # has a primary key named 'id'.
    # For a real application, you might extract data from the 'event' object.
    item = {"id": "001", "name": "Sample Item", "value": 123}

    try:
        # Put the item into the table
        response = table.put_item(Item=item)
        return {
            "statusCode": 200,
            "body": json.dumps("Item written to DynamoDB successfully!"),
        }
    except Exception as e:
        print(f"Error writing to DynamoDB: {e}")
        return {"statusCode": 500, "body": json.dumps(f"Error: {str(e)}")}
