#!/bin/bash
set -e

echo ">> Wallets & DIDs Creation Started"
echo "{" > /data/hospital_tokens.json
sed -i 's/\r$//' /data/hospital.csv

tail -n +2 /data/hospital.csv | while IFS=',' read -r hospital_kor hospital_code hospital_wallet_key; do
  hospital_kor=$(echo "$hospital_kor"  | xargs)
  hospital_code=$(echo "$hospital_code" | xargs)
  hospital_code_lower=${hospital_code,,}
  hospital_wallet_key=$(echo "$hospital_wallet_key" | xargs)

  echo ">> 테넌트 지갑 생성: $hospital_kor ($hospital_code)"
  WALLET_RES=$(curl -s -X POST http://localhost:8002/multitenancy/wallet \
    -H "Content-Type: application/json" \
    -d '{
      "wallet_name": "'"$hospital_code"'",
      "wallet_key":  "'"$hospital_wallet_key"'",
      "wallet_type": "askar",
      "label":       "'"$hospital_kor"'",
      "wallet_dispatch_type": "default",
      "wallet_endpoint": "http://localhost:8002"
    }')



  if ! echo "$WALLET_RES" | jq -e . >/dev/null; then
    echo "Wallet 생성 오류: $WALLET_RES"
    exit 1
  fi
  TOKEN=$(echo "$WALLET_RES" | jq -r .token)

#  echo ">> Peer DID 생성: $hospital_kor"
#  DID_RES=$(curl -X POST http://localhost:8002/wallet/did/create \
#    -H "Authorization: Bearer $TOKEN" \
#    -H "Content-Type: application/json" \
#    -d '{
#      "method": "did:peer:2",
#      "options": {
#        "key_type":"ed25519",
#        "peer": { "numalgo":2 }
#      },
#      "service": [
#                {
#                  "id": "#didcomm-0",
#                  "type": "did-communication",
#                  "recipientKeys": ["#key-1"],
#                  "routingKeys": [],
#                  "serviceEndpoint": "http://hospital-acapy-agent:8005"
#                }
#              ]
#
#    }')
#
#  DID=$(echo "$DID_RES" | jq -r .result.did)
#
#
#  echo ">> DID 저장 완료: $hospital_kor → $DID"
  echo "  \"${hospital_code}\": \"${TOKEN}\"," >> /data/hospital_tokens.json
  echo "================================================================="
done

# 마지막 쉼표 제거 및 JSON 마무리
sed -i '$ s/,$//' /data/hospital_tokens.json
echo "}" >> /data/hospital_tokens.json

echo ">> Sending tokens to tenant-service..."

# tenant-service 로 token update POST 요청 (압축 JSON 사용)
HTTP_RESPONSE=$(jq -c . /data/hospital_tokens.json | \
  curl -s -o /dev/null -w "%{http_code}" -X POST http://tenant-service:60007/update \
  -H "Content-Type: application/json" \
  -d @-)

if [ "$HTTP_RESPONSE" -eq 200 ]; then
  echo "✅ Tokens successfully updated to tenant-service"
else
  echo "❌ Failed to update tokens. HTTP status code: $HTTP_RESPONSE"
  exit 1
fi

echo ">> All wallets & DIDs creation completed"
