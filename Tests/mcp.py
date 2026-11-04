import json
import subprocess
import sys

requests = [
    {"id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25"}},
    {"method": "notifications/initialized"},
    {"id": 2, "method": "tools/list"},
    {"id": 3, "method": "tools/call", "params": {"name": "get_progress_summary", "arguments": {"days": True}}},
    {"id": 4, "method": "tools/call", "params": {"name": "get_progress_summary", "arguments": {"days": 31}}},
    {"id": 5, "method": "tools/call", "params": {"name": "get_progress_summary", "arguments": {"days": 7, "extra": True}}},
    {"id": 6, "method": "tools/call", "params": {"name": "write_goal", "arguments": {}}},
]
data = "".join(json.dumps({"jsonrpc": "2.0", **request}) + "\n" for request in requests)
result = subprocess.run([sys.argv[1], "mcp"], input=data, capture_output=True, text=True, check=True, timeout=5)
responses = {item["id"]: item for item in map(json.loads, result.stdout.splitlines())}
assert set(responses) == {1, 2, 3, 4, 5, 6}
assert responses[1]["result"]["protocolVersion"] == "2025-11-25"
tools = responses[2]["result"]["tools"]
assert len(tools) == 1 and tools[0]["name"] == "get_progress_summary" and tools[0]["annotations"]["readOnlyHint"]
assert all(responses[i]["error"]["code"] == -32602 for i in range(3, 7))
print("OK: MCP stdio, descubrimiento y rechazo de argumentos y escritura.")
