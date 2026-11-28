// Pauhu quickstart (Node 18+): lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY.
const key = process.env.PAUHU_DEV_KEY;
if (!key) { console.log('Set PAUHU_DEV_KEY first. Get a free Pauhu developer key by signing in with GitHub at https://api.pauhu.ai/v1/dev/github/start (terms: https://pauhu.dev/developer-terms/)'); process.exit(2); }
const U = 'https://mcp.pauhu.ai/mcp';
const h = { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' };
const post = async (body, sid) => {
  const r = await fetch(U, { method: 'POST', headers: sid ? { ...h, 'Mcp-Session-Id': sid } : h, body: JSON.stringify(body) });
  const text = await r.text();
  if (!r.ok) { console.error(`HTTP ${r.status}: ${text.slice(0, 500)}`); process.exit(1); }
  const data = text.split('\n').filter(l => l.startsWith('data:')).map(l => l.slice(5)).pop() ?? text;
  let msg = null; try { msg = data.trim() ? JSON.parse(data) : null; } catch { console.error('Unreadable reply: ' + text.slice(0, 300)); process.exit(1); }
  if (msg && msg.error) { console.error(JSON.stringify(msg.error).slice(0, 500)); process.exit(1); }
  return { r, text };
};
const init = await post({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'pauhu-quickstart', version: '0.1.0' } } });
const sid = init.r.headers.get('mcp-session-id') || undefined;
await post({ jsonrpc: '2.0', method: 'notifications/initialized' }, sid);
console.log((await post({ jsonrpc: '2.0', id: 2, method: 'tools/list' }, sid)).text);
