# pfSense / OPNsense - egress allow-list for a Pauhu-connected segment

A rule outline for a boundary firewall (pfSense or OPNsense) that fronts one or more devices which
connect to the Pauhu API. The goal is the same everywhere: **default-deny egress, no
inbound, allow-list to the Pauhu endpoints over TLS, plus DNS and NTP.** Both platforms
resolve a hostname alias at rule-load time and refresh it periodically, so you can
allow-list by hostname rather than by raw IP.

## 1. Define aliases

Create host aliases (Firewall → Aliases):

- `PAUHU_ENDPOINTS` - type **Host(s)**, entries `PAUHU_API_FQDN` and `PAUHU_AUTH_FQDN`
  (replace with the hostnames from the Endpoints table in the hardening guide / README).
  The platform resolves and refreshes these on its alias update interval.
- `DNS_SERVERS` - your trusted resolver(s).
- `NTP_SERVERS` - your trusted time source(s).

## 2. Place the devices on their own interface / VLAN

Put the connecting devices on a dedicated interface or VLAN (e.g. `PAUHU_SEG`). Do not
let that segment route to your LAN or OT networks except through these explicit rules.

## 3. Rules on the PAUHU_SEG interface (ordered, first match wins)

| # | Action | Proto | Source      | Destination        | Port | Notes                        |
|---|--------|-------|-------------|--------------------|------|------------------------------|
| 1 | Pass   | UDP   | PAUHU_SEG net | DNS_SERVERS      | 53   | name resolution              |
| 2 | Pass   | TCP   | PAUHU_SEG net | DNS_SERVERS      | 53   | DNS over TCP                 |
| 3 | Pass   | UDP   | PAUHU_SEG net | NTP_SERVERS      | 123  | clock for TLS validation     |
| 4 | Pass   | TCP   | PAUHU_SEG net | PAUHU_ENDPOINTS  | 443  | Pauhu API + sign-in (TLS)    |
| 5 | Block  | any   | PAUHU_SEG net | any              | any  | default-deny, enable logging |

- No rule permits traffic **to** the segment from the Internet: the WAN interface keeps
  its default block-inbound posture and you add no port forwards.
- Enable logging on rule 5 so denied egress is visible.
- Apply the identical rule set to the interface's **IPv6** traffic (or disable IPv6 on the
  segment if unused). Do not leave an IPv6 any/any pass in place.

## 4. Optional hardening

- Route rule 4 through an explicit outbound/TLS-inspecting proxy if your policy requires
  deep egress inspection (remember this is incompatible with certificate pinning on the
  device).
- Add a per-host traffic shaper / connection-rate limit on the segment to cap the outbound
  cadence. Measure your device's actual request rate, response sizes and connection duration
  and set a limit appropriate to its workload (billing is per usage day, which is not itself a
  traffic limit: a device may make several calls or use a streaming response on a usage day).

Confirm the endpoint hostnames against the Endpoints table in the hardening guide (README)
before deploying.
