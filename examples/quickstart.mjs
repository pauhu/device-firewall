// Pauhu quickstart (Node 18+): lists the tools the Pauhu demo backend offers you. Needs PAUHU_DEV_KEY.
const key = process.env.PAUHU_DEV_KEY;
if (!key) { console.log('Set PAUHU_DEV_KEY first. Get a free Pauhu developer key at https://pauhu.dev/developer-terms/'); process.exit(2); }
const U = 'https://mcp.pauhu.ai/mcp';
const h = { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' };
const post = (body, sid) => fetch(U, { method: 'POST', headers: sid ? { ...h, 'Mcp-Session-Id': sid } : h, body: JSON.stringify(body) });
const r = await post({ jsonrpc: '2.0', id: 1, method: 'initialize', params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'pauhu-quickstart', version: '0.1.0' } } });
const sid = r.headers.get('mcp-session-id') || undefined;
await post({ jsonrpc: '2.0', method: 'notifications/initialized' }, sid);
console.log(await (await post({ jsonrpc: '2.0', id: 2, method: 'tools/list' }, sid)).text());
