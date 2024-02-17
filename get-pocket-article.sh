#!/bin/sh

source .env

# 認証・認可
## POCKET_AUTH_CODE には `code=xxxx` 形式でレスポンスが返ってくる
POCKET_AUTH_CODE=$(curl -s "https://getpocket.com/v3/oauth/request?consumer_key=${POCKET_PROJECT_KEY}&redirect_uri=https://example.com" | awk -F'[=]' '{print $2}')
echo $POCKET_AUTH_CODE

open "https://getpocket.com/auth/authorize?request_token=${POCKET_AUTH_CODE}&redirect_uri=https://example.com"

## 一定の時間内に上記の url で認可するようにするとアクセストークンを発行できる。時間をすぎると「アクセスキー取得」で 403 になる
sleep 5

## アクセスキーの取得
## POCKET_ACCESS_KEY には `access_token=xxxx&username=xxxx` 形式でレスポンスが返ってくる
POCKET_ACCESS_KEY=$(curl "https://getpocket.com/v3/oauth/authorize?consumer_key=${POCKET_PROJECT_KEY}&code=${POCKET_AUTH_CODE}" | awk -F'[=&]' '{print $2}')
echo $POCKET_ACCESS_KEY

# 読んだ記事の数を月ごとに集計して表示する
## 多すぎる場合には since を師弟すること
## see also https://getpocket.com/developer/docs/v3/retrieve
curl -s -X POST 'https://getpocket.com/v3/get' \
    -d consumer_key=${POCKET_PROJECT_KEY} \
    -d access_token="${POCKET_ACCESS_KEY}" \
    -d state='archive' \
    -d sort='newest' | \
    jq '.list[] | .time_read | tonumber | strftime("%Y-%m")' | \
    jq -s '.' | \
    jq 'group_by(.) | map({key: .[0], value: length}) | reverse | from_entries'
