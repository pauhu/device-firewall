# OT zone & conduit outline for a Pauhu-connected device (IEC 62443 / NIST SP 800-82 Rev. 3)

For industrial and operational-technology (OT) sites, model the device that connects to the
Pauhu API as a component in a **zone**, reaching the Internet through a single controlled
**conduit**. This is the IEC 62443 zones-and-conduits approach, aligned with the layered
segmentation in NIST SP 800-82 Rev. 3.

The firewall rules in the sibling files enforce the conduit; this file is the design around
them.

## 1. Zones

- **Control zone** - PLCs, RTUs, sensors and actuators performing the physical process.
  Highest integrity/availability requirement. **No direct Internet access.**
- **Pauhu-connect zone** - the device(s) that call the Pauhu API. A dedicated segment/VLAN,
  separated from the control zone by a firewall. This is the only zone with an outbound
  Internet conduit.
- **IT / enterprise zone** - business systems. Kept separate from both of the above.

A device must sit in exactly one zone and must not bridge zones (no dual-homing that
connects the control zone to the Internet).

## 2. The outbound conduit

- A single, explicitly defined conduit carries traffic from the Pauhu-connect zone to
  `PAUHU_API_FQDN` / `PAUHU_AUTH_FQDN` over TCP 443 (TLS), plus the DNS and NTP the device
  needs. Everything else is denied (see the firewall examples).
- The conduit is **outbound-initiated only**. Nothing from the Internet initiates a
  connection into any zone.
- Where the use case is send-only (telemetry out, no command in), consider a
  **data diode (a one-way link)** so the control zone is physically unable to
  receive inbound traffic.
- Place a managed boundary device (firewall, or firewall + egress proxy) at the conduit.
  Log and monitor it. (IEC 62443-3-3 system requirements; NIST SP 800-82 Rev. 3 §5.)

## 3. Conduit integrity between control and Pauhu-connect zones

- If process data must reach the Pauhu-connect zone, pass it through a broker / historian /
  historian, not by exposing a PLC directly. The Pauhu-connect device reads from the broker.
- Apply least privilege on that internal conduit: only the specific protocol/port the broker
  needs, one direction where possible.

## 4. Safety and availability (fail-safe)

- An OT safety or control function must **never** depend on reaching the Pauhu API. Loss of
  the conduit degrades to a defined safe state; it never fails open and never stalls the
  process. (This is the OT-specific form of the fail-safe requirement in the hardening guide's
  "Fail-safe, never fail-open" section.)
- Clock: provide NTP locally so TLS validation on the conduit does not depend on the
  Internet being reachable first.

## 5. Mapping to the firewall examples

| Control                         | Where enforced                                  |
|---------------------------------|-------------------------------------------------|
| Default-deny egress allow-list  | `nftables.conf` / `iptables.sh` / `ufw.sh` / `cisco-acl.txt` on the conduit device |
| No inbound                      | all examples (no listener, no port forward)     |
| Single conduit per zone         | boundary placement (this file §2)               |
| Send-only option                | data diode / one-way link (this file §2)        |
| Rate budgeting                  | shaper on the conduit (`pfsense-opnsense.md` §4) |

## 6. Standards

- **IEC 62443** - zones, conduits, foundational requirements (esp. 62443-3-2 risk
  assessment and 62443-3-3 system requirements).
- **NIST SP 800-82 Rev. 3** - Guide to OT Security (network segmentation, boundary
  protection).
- **NIST SP 800-41 Rev. 1** - firewall policy (default-deny).
- **EU** - NIS2 and the Cyber Resilience Act for in-scope operators.

This is a design outline, not a site-specific risk assessment. Run IEC 62443-3-2 against
your own process before relying on it.
