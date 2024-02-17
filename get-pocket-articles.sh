#!/bin/sh

source .env

# Authz
## response is in format like `code=xxxx`
POCKET_AUTH_CODE=$(curl -s "https://getpocket.com/v3/oauth/request?consumer_key=${POCKET_PROJECT_KEY}&redirect_uri=https://example.com" | awk -F'[=]' '{print $2}')
echo "[INFO] your auth code: $POCKET_AUTH_CODE"

open "https://getpocket.com/auth/authorize?request_token=${POCKET_AUTH_CODE}&redirect_uri=https://example.com"

## You can issue an access token if you authorize it with the above url within a certain time. If you exceed the time, you will get 403 with "Get access key".
sleep 5

## getting access key
## response is in format like `access_token=xxxx&username=xxxx`
POCKET_ACCESS_KEY=$(curl "https://getpocket.com/v3/oauth/authorize?consumer_key=${POCKET_PROJECT_KEY}&code=${POCKET_AUTH_CODE}" | awk -F'[=&]' '{print $2}')
echo "[INFO] your access key: $POCKET_ACCESS_KEY"

# Display a monthly count of the number of articles read
echo "[INFO] getting time read for archived articles by month"
curl -s -X POST 'https://getpocket.com/v3/get' \
    -d consumer_key=${POCKET_PROJECT_KEY} \
    -d access_token="${POCKET_ACCESS_KEY}" \
    -d state='archive' \
    -d sort='newest' | \
    jq '.list[] | .time_read | tonumber | strftime("%Y-%m")' | \
    jq -s '.' | \
    jq 'group_by(.) | map({key: .[0], value: length}) | reverse | from_entries'

# Display a monthly count of the number of articles piled up.
## Too many to retrieve so dividing with state.
echo "[INFO] getting time added for unread articles by month"
curl -s -X POST 'https://getpocket.com/v3/get' \
    -d consumer_key=${POCKET_PROJECT_KEY} \
    -d access_token="${POCKET_ACCESS_KEY}" \
    -d state='unread' \
    -d sort='newest' | \
    jq '.list[] | .time_added | tonumber | strftime("%Y-%m")' | \
    jq -s '.' | \
    jq 'group_by(.) | map({key: .[0], value: length}) | reverse | from_entries'

echo "[INFO] getting time added for archived articles by month"
curl -s -X POST 'https://getpocket.com/v3/get' \
    -d consumer_key=${POCKET_PROJECT_KEY} \
    -d access_token="${POCKET_ACCESS_KEY}" \
    -d state='archive' \
    -d sort='newest' | \
    jq '.list[] | .time_added | tonumber | strftime("%Y-%m")' | \
    jq -s '.' | \
    jq 'group_by(.) | map({key: .[0], value: length}) | reverse | from_entries'