# Smart_Journal
Lex/Lambda/DynamoDB/Bedrock journal application

Run with:

- sam build
- sam validate
- sam sync --stack-name Smart-Journal-Stack
- ./lex_config.sh

From there, there is a small amount of manual configuration, namely adding the Bedrock Knowledge Base manually (as this is not supported in SAM/CF currently) and hooking up the knowledge base to the QnA intent.