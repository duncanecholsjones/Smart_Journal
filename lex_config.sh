#!/usr/bin/env bash
set -euo pipefail

# Configuration, get these from the template.yaml file
BOT_NAME="WriteJournalBot"
BOT_VERSION="DRAFT"
ALIAS_NAME="TestBotAlias"
REGION="us-east-1"
LOCALE_ID="en_US"

# Lambda prefix (matches SAM-deployed function names automatically)
LAMBDA_FUNCTION_PREFIX="Smart-Journal-Stack-LexFulfillmentLambda"

# Locate Bot ID
BOT_ID=$(
  aws lexv2-models list-bots \
    --region "${REGION}" \
    --sort-by attribute=BotName,order=Ascending \
    --output json |
  jq -r --arg NAME "${BOT_NAME}" '
    .botSummaries[] 
    | select(.botName == $NAME) 
    | .botId
  ' | head -n1
)

if [[ -z "${BOT_ID}" ]]; then
  echo "ERROR: Could not find bot with name ${BOT_NAME}"
  exit 1
fi

# Locate Alias ID
BOT_ALIAS_ID=$(
  aws lexv2-models list-bot-aliases \
    --region "${REGION}" \
    --bot-id "${BOT_ID}" \
    --output json |
  jq -r --arg NAME "${ALIAS_NAME}" '
    .botAliasSummaries[] 
    | select(.botAliasName == $NAME) 
    | .botAliasId
  ' | head -n1
)

if [[ -z "${BOT_ALIAS_ID}" ]]; then
  echo "ERROR: Could not find alias ${ALIAS_NAME}"
  exit 1
fi

# Find Lambda ARN
LAMBDA_ARN=$(
  aws lambda list-functions \
    --region "${REGION}" \
    --output json |
  jq -r --arg PREFIX "${LAMBDA_FUNCTION_PREFIX}" '
    .Functions[]
    | select(.FunctionName | startswith($PREFIX))
    | .FunctionArn
  ' | head -n1
)

if [[ -z "${LAMBDA_ARN}" ]]; then
  echo "ERROR: Could not find Lambda starting with prefix ${LAMBDA_FUNCTION_PREFIX}"
  exit 1
fi

# Update Bot Alias with Lambda and Voice options
echo "Updating bot alias with Lambda code hook..."

aws lexv2-models update-bot-alias \
  --region "${REGION}" \
  --bot-id "${BOT_ID}" \
  --bot-alias-id "${BOT_ALIAS_ID}" \
  --bot-version "${BOT_VERSION}" \
  --bot-alias-name "${ALIAS_NAME}" \
  --bot-alias-locale-settings "{
    \"${LOCALE_ID}\": {
      \"enabled\": true,
      \"codeHookSpecification\": {
        \"lambdaCodeHook\": {
          \"lambdaARN\": \"${LAMBDA_ARN}\",
          \"codeHookInterfaceVersion\": \"1.0\"
        }
      }
    }
  }"

aws lexv2-models update-bot-locale \
  --bot-id "${BOT_ID}" \
  --bot-version "${BOT_VERSION}" \
  --locale-id "${LOCALE_ID}" \
  --voice-settings '{"voiceId":"Joanna","engine":"standard"}' \
  --nlu-intent-confidence-threshold 0.40

echo "----------------------------------------"
echo "Lex alias updated successfully"
echo "Bot ID:        ${BOT_ID}"
echo "Bot Version:   ${BOT_VERSION}"
echo "Bot Alias ID:  ${BOT_ALIAS_ID}"
echo "Lambda ARN:    ${LAMBDA_ARN}"
echo "----------------------------------------"
