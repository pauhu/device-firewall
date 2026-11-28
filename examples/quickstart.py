"""Pauhu quickstart (Python 3.9+, standard library only): lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY."""
import json, os, sys, urllib.request
key = os.environ.get("PAUHU_DEV_KEY")
if not key:
    print("Set PAUHU_DEV_KEY first. Get a free Pauhu developer key at https://pauhu.dev/developer-terms/"); sys.exit(2)
U = "https://mcp.pauhu.ai/mcp"
H = {"Authorization": f"Bearer {key}", "Content-Type": "application/json", "Accept": "application/json, text/event-stream"}
def post(body, sid=None):
    h = dict(H, **({"Mcp-Session-Id": sid} if sid else {}))
    return urllib.request.urlopen(urllib.request.Request(U, json.dumps(body).encode(), h), timeout=30)
r = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "pauhu-quickstart", "version": "0.1.0"}}})
sid = r.headers.get("Mcp-Session-Id"); r.read()
post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid).read()
print(post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid).read().decode())
