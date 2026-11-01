# Network and firewall setup for devices that call Pauhu AI

This page tells network and security teams what a device needs so it can call the Pauhu AI API safely.
It applies to any device that speaks TCP/IP and HTTPS: a server, a router, a sensor or controller with a browser
or HTTP client.

Items marked **proposed** are planned and not available yet.

In this package:

- `README.md` (this page): what to allow and why.
- `HARDENING.md`: a fuller device hardening baseline with standards references.
- `firewall/`: example rules for common firewalls (section 11).
- `SECURITY.md`: how to report a security issue.

## Choose your setup

| Device environment | Recommended setup |
| --- | --- |
| Most devices: offices, servers, connected products | **Online.** The device calls the API over outbound HTTPS on the days it is used (sections 1 to 8). |
| Critical infrastructure, isolated or segmented industrial networks that cannot or must not connect out | **Offline (proposed).** The device works from a signed grant approved in advance and reconciles when a connection is allowed (section 9). |

Whichever setup you choose, three things keep a device working and its account correct:

- Recover from a short outage without dropping off: safe retries with backoff and token refresh (sections 6 and 8).
- Give each device its own revocable key, so one compromised device can be cut off without affecting the others
  (section 7, proposed).
- Keep the clock correct, because tokens, grants and daily usage records depend on it (section 5).

Billing per day of use is **proposed** for both setups.

## 1. Pauhu traffic is outbound only

For Pauhu, a device only opens outgoing connections:

| Direction | Protocol | Port | Destination | Why |
| --- | --- | --- | --- | --- |
| Outbound | TCP (HTTPS) | 443 | `api.pauhu.ai` | API requests |
| Outbound | TCP (HTTPS) | 443 | `auth.pauhu.ai` | Device sign-in and token refresh |

- No unsolicited inbound connection or port forwarding is needed for Pauhu. Allow the response traffic of these
  established connections.
- Pauhu application traffic uses no UDP. "Ping" in Pauhu terms means a normal HTTPS API request; ICMP echo is not a
  Pauhu API requirement.
- Keep the services your site already approves for the device: local name resolution (DNS, or a proxy that resolves
  names for it), time (NTP) and the network-control traffic your network needs, such as ICMPv6 (RFC 4890).
  Pauhu needs no extra public DNS or time server.
- Beyond that, deny by default under your site policy.

### Endpoints

This table is the Pauhu endpoint list that the example files in `firewall/` refer to. They use two
placeholders; use these values:

| Placeholder | Host name |
| --- | --- |
| `PAUHU_API_FQDN` | `api.pauhu.ai` |
| `PAUHU_AUTH_FQDN` | `auth.pauhu.ai` |

## 2. Allow by name, not by address

Write firewall rules for the two host names above, not for IP addresses. Addresses can change without notice,
and no address list is published. If your firewall can only filter by address, use a forward proxy that filters by
name (section 4).

## 3. Encryption

- TLS 1.2 or newer; TLS 1.3 preferred (RFC 8446, RFC 9325).
- Validate the full certificate chain against the device's standard public trust store, and check the host name.
- Do not pin a single leaf certificate: certificates are renewed routinely.
- If your network inspects TLS, the inspecting proxy must itself validate the upstream certificate and host name,
  and re-sign with a certificate authority the device trusts.

## 4. Proxies

Devices behind a corporate proxy can use HTTPS through an HTTP `CONNECT` proxy. Allow `CONNECT` to the two host
names on port 443 only.

## 5. Correct time

Keep the device clock correct with your approved time source (NTP, RFC 5905). TLS and signed tokens fail when the
clock is wrong.

## 6. Signing a device in

Devices sign in with the OAuth 2.0 device authorization grant (RFC 8628, on top of RFC 6749):

1. The device asks `auth.pauhu.ai` for a short code.
2. A person approves the code once on their phone or computer.
3. Meanwhile the device polls `auth.pauhu.ai` for its token, following the RFC 8628 rules: wait the given
   `interval`, keep waiting on `authorization_pending`, and slow down on `slow_down`.
4. The device then calls `api.pauhu.ai` with `Authorization: Bearer <token>` over TLS.

Both the device and the approving phone need to reach `auth.pauhu.ai` during sign-in.

**Proposed:** after the one-time approval each device holds its own key, so daily requests need only
`api.pauhu.ai`, and `auth.pauhu.ai` is contacted again only for sign-in and refresh.

## 7. Keys

- Keep tokens and keys in the device's secure storage, never in plain-text files, logs or source code.
- **Proposed:** one key per device, never shared between devices, and revocable on its own.

## 8. Retries

- Automatically retry only requests known to be safe to repeat (RFC 9110, section 9.2.2).
- For a request that may charge or change something, a lost reply does not mean it failed: follow that request's
  documented recovery procedure and check the outcome before sending it again.
- Where retries are safe, use a bounded number of attempts with exponential backoff and jitter, and honour
  `Retry-After`.
- Do not retry HTTP 401 or 403; fix the credentials.
- A 409 response with error `price_pending` means the item is not on sale yet; do not retry it automatically.
  For other 409 responses, follow the returned conflict information.
- Sign-in polling follows its own rules (section 6).

**Proposed:** one charge per device per day it is used, however many requests it makes that day.

## 9. Industrial and critical networks

- Put devices in their own zone with a single conduit that allows only outbound 443 to the two host names
  (IEC 62443-3-3 zones and conduits; NIST SP 800-82 Rev. 3). These rules are one part of such a design, not a
  certification, and not a reason to connect a controller that your site keeps isolated.
- Log the conduit at the boundary.
- **Proposed:** sites with no internet connection use a signed offline grant, approved in advance, that reconciles
  once when the device next connects.

## 10. Reporting a security issue

The security contact is in `https://pauhu.ai/.well-known/security.txt`. See also `SECURITY.md`.

## 11. Example configurations

The files in `firewall/` are **templates**, not drop-in configurations. Each one encodes the shape above:
outbound TCP 443 to the two host names, your trusted DNS and time sources, nothing inbound, everything else
denied, for both IPv4 and IPv6. For IPv6, check that the applied rules keep the neighbour and router discovery
your network needs (RFC 4890). Replace the placeholders using the Endpoints table (section 1), adapt them to
your topology, and check the applied result before you rely on it.

| File | Platform | Kind |
| --- | --- | --- |
| `firewall/nftables.conf` | Linux nftables | Ruleset; blocks the listed TCP/UDP services until you fill its sets (loopback, established traffic and the listed ICMPv6 types stay allowed); check with `nft list ruleset` |
| `firewall/iptables.sh` | Linux iptables | Script; replaces existing rules and refuses to finish unless the result is in effect |
| `firewall/ufw.sh` | Ubuntu/Debian UFW | Script; same checks |
| `firewall/windows-defender-firewall.ps1` | Windows Defender Firewall | Script; reads back the effective policy (local rules merged with Group Policy) and refuses to finish if it is not in effect |
| `firewall/pfsense-opnsense.md` | pfSense / OPNsense | Outline |
| `firewall/cisco-acl.txt` | Cisco IOS / ASA | Outline |
| `firewall/iec62443-ot-conduit.md` | Industrial zone and conduit | Outline |

The scripts replace the existing firewall rules on the machine they run on. Run them only on a device you
manage, with console access in case you lock yourself out.
