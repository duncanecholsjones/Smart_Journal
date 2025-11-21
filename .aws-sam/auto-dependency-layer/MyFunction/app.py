import json


def lambda_handler(event, context):
    """
    This function is the entry point for the Lambda function.
    The name matches the 'Handler: app.lambda_handler' in the template.
    """
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "message": "hello world",
            }
        ),
    }
