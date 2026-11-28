"""Pauhu quickstart (Python 3.9+, standard library only): lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY."""
import json, os, sys, urllib.error, urllib.request
key = os.environ.get("PAUHU_DEV_KEY")
if not key:
    print("Set PAUHU_DEV_KEY first. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/)"); sys.exit(2)
U = "https://mcp.pauhu.ai/mcp"
H = {"Authorization": f"Bearer {key}", "Content-Type": "application/json", "Accept": "application/json, text/event-stream"}
def post(body, sid=None):
    h = dict(H, **({"Mcp-Session-Id": sid} if sid else {}))
    try:
        r = urllib.request.urlopen(urllib.request.Request(U, json.dumps(body).encode(), h), timeout=30)
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code}: {e.read()[:500].decode(errors='replace')}", file=sys.stderr); sys.exit(1)
    text = r.read().decode(errors="replace")
    lines = [l[5:] for l in text.splitlines() if l.startswith("data:")]
    data = (lines[-1] if lines else text).strip()
    try:
        msg = json.loads(data) if data else None
    except ValueError:
        print("Unreadable reply: " + text[:300], file=sys.stderr); sys.exit(1)
    if isinstance(msg, dict) and msg.get("error"):
        print(json.dumps(msg["error"])[:500], file=sys.stderr); sys.exit(1)
    return r, text
r, _ = post({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-06-18", "capabilities": {}, "clientInfo": {"name": "pauhu-quickstart", "version": "0.1.0"}}})
sid = r.headers.get("Mcp-Session-Id")
post({"jsonrpc": "2.0", "method": "notifications/initialized"}, sid)
print(post({"jsonrpc": "2.0", "id": 2, "method": "tools/list"}, sid)[1])
