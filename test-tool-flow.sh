#!/bin/bash
set -e

echo "=== CCR Tool Flow Test ==="
echo

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Health check
echo -e "${BLUE}1. Health check${NC}"
HEALTH=$(curl -s http://127.0.0.1:3456/health)
echo "$HEALTH"
if echo "$HEALTH" | grep -q '"status":"ok"'; then
  echo -e "${GREEN}✓ Router is healthy${NC}"
else
  echo "✗ Router health check failed"
  exit 1
fi
echo

# 2. Tool-use request
echo -e "${BLUE}2. Sending tool-use request${NC}"
TOOL_REQUEST=$(cat <<'EOF'
{
  "model":"ollama,qwen3:8b",
  "messages":[{"role":"user","content":"please echo hi"}],
  "tools":[{
    "name":"echo",
    "description":"echo back text",
    "input_schema":{
      "type":"object",
      "properties":{"text":{"type":"string"}},
      "required":["text"]
    }
  }]
}
EOF
)

TOOL_RESPONSE=$(curl -s -H "Content-Type: application/json" \
  -d "$TOOL_REQUEST" \
  http://127.0.0.1:3456/v1/messages)

echo "$TOOL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$TOOL_RESPONSE"
echo

# 3. Extract tool_call_id
echo -e "${BLUE}3. Extracting tool_call_id${NC}"
TOOL_CALL_ID=$(echo "$TOOL_RESPONSE" | python3 -c "
import json, sys
j = json.loads(sys.stdin.read())
content = j.get('content') or []
for c in content:
    if isinstance(c, dict) and c.get('type') == 'tool_use':
        print(c.get('id', ''))
        break
")

if [ -z "$TOOL_CALL_ID" ]; then
  echo "✗ Could not extract tool_call_id"
  exit 1
fi

echo -e "${GREEN}✓ Tool call ID: $TOOL_CALL_ID${NC}"
echo

# 4. Send tool result
echo -e "${BLUE}4. Sending tool result${NC}"
cat > /tmp/ccr_test_result.json <<EOF
{"model":"ollama,qwen3:8b","messages":[{"role":"user","content":"please echo hi"},{"role":"tool","tool_call_id":"$TOOL_CALL_ID","content":"{\"text\":\"hi\"}"}]}
EOF

FINAL_RESPONSE=$(curl -s -H "Content-Type: application/json" \
  --data-binary @/tmp/ccr_test_result.json \
  http://127.0.0.1:3456/v1/messages)

echo "$FINAL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$FINAL_RESPONSE"
echo

# 5. Verify final response
echo -e "${BLUE}5. Verification${NC}"
if echo "$FINAL_RESPONSE" | grep -q '"type":"text"'; then
  echo -e "${GREEN}✓ Tool flow completed successfully${NC}"
  echo -e "${YELLOW}Assistant responded with text content after receiving tool result${NC}"
else
  echo "✗ Unexpected response format"
  exit 1
fi
