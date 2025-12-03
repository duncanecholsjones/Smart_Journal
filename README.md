# Smart_Journal: AWS Serverless + GenAI Personal Journaling Assistant
AWS Lex/Lambda/S3/Bedrock/SAM personal journaling application. The concept is to have a GenAI-enabled chatbot assistant be able to make updates to my personal journal via audio or text input (represented by .txt files in S3) and then use Bedrock Knowledge Base RAG retrieval to perform queries and do inference against that personal journal data.

Run with:

- sam build
- sam validate
- sam sync --stack-name Smart-Journal-Stack
- ./lex_config.sh

From there, there is a small amount of manual configuration, namely adding the Bedrock Knowledge Base manually (as this is not supported in SAM/CF currently) and hooking up the knowledge base to the QnA intent.

<iframe width="560" height="315" src="https://www.youtube.com/embed/npjVN-kUgnc?si=rXGPS_TY_TZzdBlw" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>


[![Watch the video](https://img.youtube.com/vi/npjVN-kUgnc/0.jpg)](https://www.youtube.com/watch?v=npjVN-kUgnc)
