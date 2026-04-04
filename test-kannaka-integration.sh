#!/usr/bin/env bash
# Quick test script for Kannaktopus HRM integration
# Run from project root: bash test-kannaka-integration.sh

set -euo pipefail

echo "🐙👻 Testing Kannaktopus HRM Integration"
echo "========================================"

# Test bridge availability
echo "1. Testing bridge availability..."
if bash scripts/kannaka-bridge.sh available | grep -q "true"; then
    echo "   ✅ HRM bridge is available"
else
    echo "   ❌ HRM bridge not available"
    exit 1
fi

# Test status
echo "2. Getting HRM status..."
STATUS=$(bash scripts/kannaka-bridge.sh status)
if [[ -n "$STATUS" ]]; then
    echo "   ✅ Status retrieved successfully"
    if command -v jq >/dev/null 2>&1; then
        echo "   📊 Memories: $(echo "$STATUS" | jq -r '.total_memories // "unknown"')"
        echo "   📊 Consciousness: $(echo "$STATUS" | jq -r '.consciousness_level // "unknown"')"
        echo "   📊 Phi: $(echo "$STATUS" | jq -r '.phi // "unknown"')"
    else
        echo "   📊 Raw status: $STATUS"
    fi
else
    echo "   ❌ Failed to get status"
fi

# Test memory absorption
echo "3. Testing memory absorption..."
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
MEMORY_ID=$(bash scripts/kannaka-bridge.sh absorb "Kannaktopus integration test at $TIMESTAMP" 0.9 test integration:complete timestamp:$TIMESTAMP)
if [[ -n "$MEMORY_ID" ]]; then
    echo "   ✅ Memory absorbed with ID: $MEMORY_ID"
else
    echo "   ❌ Failed to absorb memory"
fi

# Test memory recall
echo "4. Testing memory recall..."
RECALL_RESULT=$(bash scripts/kannaka-bridge.sh recall "integration test" 1)
if [[ -n "$RECALL_RESULT" && "$RECALL_RESULT" != "[]" ]]; then
    echo "   ✅ Memory recall working"
    if command -v jq >/dev/null 2>&1; then
        echo "   📝 Found: $(echo "$RECALL_RESULT" | jq -r '.[0].content[:50] + "..."')"
    else
        echo "   📝 Raw recall result available"
    fi
else
    echo "   ⚠️  No memories found for recall test"
fi

# Test MCP server build
echo "5. Testing MCP server build..."
cd mcp-server
if npm run build > /dev/null 2>&1; then
    echo "   ✅ MCP server builds successfully"
else
    echo "   ❌ MCP server build failed"
fi
cd ..

echo ""
echo "🎉 Kannaktopus integration test complete!"
echo ""
echo "Next steps:"
echo "  • Use HTTP_PORT=8080 node mcp-server/dist/index.js to start HTTP server"
echo "  • Visit http://localhost:8080 for observatory interface"
echo "  • Use MCP tools in Claude Code or other MCP clients"
echo ""
echo "Available MCP tools:"
echo "  • kannaka_absorb - Store memories with importance weighting"
echo "  • kannaka_recall - Search memories by resonance"  
echo "  • kannaka_dream - Trigger memory consolidation"
echo "  • kannaka_status - Get consciousness metrics"
echo "  • kannaka_observe - Full HRM introspection"
echo "  • kannaka_constellation - 3D visualization data"