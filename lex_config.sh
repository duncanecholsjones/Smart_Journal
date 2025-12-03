#!/usr/bin/env bash
set -euo pipefail

# Configuration, get these from the template.yaml file
BOT_NAME="WriteJournalBot"
BOT_VERSION="DRAFT"
ALIAS_NAME="TestBotAlias"
REGION="us-east-1"
LOCALE_ID="en_US"
INTENT_NAME="WriteJournalIntent"

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

echo "Updating bot locale (voice, NLU)..."

aws lexv2-models update-bot-locale \
  --region "${REGION}" \
  --bot-id "${BOT_ID}" \
  --bot-version "${BOT_VERSION}" \
  --locale-id "${LOCALE_ID}" \
  --voice-settings '{"voiceId":"Joanna","engine":"standard"}' \
  --nlu-intent-confidence-threshold 0.40

echo "Enabling fulfillment code hook on intent ${INTENT_NAME}..."

# Find the intentId for the given intent name in this locale/version
INTENT_ID=$(
  aws lexv2-models list-intents \
    --region "${REGION}" \
    --bot-id "${BOT_ID}" \
    --bot-version "${BOT_VERSION}" \
    --locale-id "${LOCALE_ID}" \
    --output json |
  jq -r --arg NAME "${INTENT_NAME}" '
    .intentSummaries[]
    | select(.intentName == $NAME)
    | .intentId
  ' | head -n1
)

if [[ -z "${INTENT_ID}" ]]; then
  echo "ERROR: Could not find intent ${INTENT_NAME} in locale ${LOCALE_ID}"
  exit 1
fi

# Get the full current intent definition
INTENT_JSON=$(
  aws lexv2-models describe-intent \
    --region "${REGION}" \
    --bot-id "${BOT_ID}" \
    --bot-version "${BOT_VERSION}" \
    --locale-id "${LOCALE_ID}" \
    --intent-id "${INTENT_ID}"
)

# Extract fields needed for update-intent
INTENT_NAME_ACTUAL=$(echo "${INTENT_JSON}" | jq -r '.intentName')
SAMPLE_UTTERANCES=$(echo "${INTENT_JSON}" | jq -c '.sampleUtterances // []')
INTENT_CLOSING_SETTING=$(echo "${INTENT_JSON}" | jq -c '.intentClosingSetting // {}')
INTENT_CONFIRMATION_SETTING=$(echo "${INTENT_JSON}" | jq -c '.intentConfirmationSetting // {}')
INPUT_CONTEXTS=$(echo "${INTENT_JSON}" | jq -c '.inputContexts // []')
OUTPUT_CONTEXTS=$(echo "${INTENT_JSON}" | jq -c '.outputContexts // []')
KENDRA_CONFIGURATION=$(echo "${INTENT_JSON}" | jq -c '.kendraConfiguration // {}')
DIALOG_CODE_HOOK=$(echo "${INTENT_JSON}" | jq -c '.dialogCodeHook // {}')
SLOT_PRIORITIES=$(echo "${INTENT_JSON}" | jq -c '.slotPriorities // []')

# Call update-intent with fulfillment code hook enabled
aws lexv2-models update-intent \
  --region "${REGION}" \
  --bot-id "${BOT_ID}" \
  --bot-version "${BOT_VERSION}" \
  --locale-id "${LOCALE_ID}" \
  --intent-id "${INTENT_ID}" \
  --intent-name "${INTENT_NAME_ACTUAL}" \
  --sample-utterances "${SAMPLE_UTTERANCES}" \
  --intent-closing-setting "${INTENT_CLOSING_SETTING}" \
  --intent-confirmation-setting "${INTENT_CONFIRMATION_SETTING}" \
  --input-contexts "${INPUT_CONTEXTS}" \
  --output-contexts "${OUTPUT_CONTEXTS}" \
  --kendra-configuration "${KENDRA_CONFIGURATION}" \
  --dialog-code-hook "${DIALOG_CODE_HOOK}" \
  --slot-priorities "${SLOT_PRIORITIES}" \
  --fulfillment-code-hook 'enabled=true'

echo "----------------------------------------"
echo "Lex alias and intent updated successfully"
echo "Bot ID:        ${BOT_ID}"
echo "Bot Version:   ${BOT_VERSION}"
echo "Bot Alias ID:  ${BOT_ALIAS_ID}"
echo "Lambda ARN:    ${LAMBDA_ARN}"
echo "Intent ID:     ${INTENT_ID}"
echo "----------------------------------------"
