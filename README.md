# Smart_Journal
Lex/Lambda/S3/Bedrock/SAM personal journaling application. The concept is to have a GenAI-enabled chatbot assistant be able to make updates to my personal journal via audio or text input (represented by .txt files in S3) and then use Bedrock Knowledge Base RAG retrieval to perform queries and do inference against that personal journal data.

Run with:

- sam build
- sam validate
- sam sync --stack-name Smart-Journal-Stack
- ./lex_config.sh

From there, there is a small amount of manual configuration, namely adding the Bedrock Knowledge Base manually (as this is not supported in SAM/CF currently) and hooking up the knowledge base to the QnA intent.