# Device hardening baseline for the Pauhu API

Guidance for operators who run a TCP/IP device - a phone, PC, server, robot, network device,
industrial sensor or embedded chip - that connects to the Pauhu API for answers
or data.

This document describes **how your device reaches Pauhu**. It does not describe Pauhu's
own infrastructure. Everything here is about the firewall and network posture of **your**
equipment, under your control.

> **Placeholders.** Examples use two names for Pauhu's public service endpoints:
> `PAUHU_API_FQDN` (the API) and `PAUHU_AUTH_FQDN` (sign-in / device authorisation).
> Replace them with the host names in the Endpoints table of `README.md`. Allow-list by
> **hostname**, not by IP address - service addresses change, and hostname allow-listing
> stays correct and is the recommended practice.

---

## 1. The connection model (why this is simple to secure)

Pauhu uses a **pull model**:

- Your device **initiates** every connection, outbound, over HTTPS (TCP 443).
- Pauhu **never initiates** a connection to your device. Nothing needs to listen for
  inbound traffic, and no port needs to be opened to the Internet.
- Billing per device per day of use is **proposed**. It is a billing unit, not a traffic limit: a device
  may make many requests on a day it is used.

Because the device is a *client* and never a *server*, the correct firewall is a narrow
**default-deny egress allow-list with no inbound exposure**. It reduces unsolicited access to the
device and unauthorised outbound traffic from it.

This follows the "deny by default, permit by exception" principle in **NIST SP 800-41 Rev. 1**
(Guidelines on Firewalls and Firewall Policy) and the "no implicit trust" posture of
**NIST SP 800-207** (Zero Trust, NIST SP 800-207).

---

## 2. Core requirements

### 2.1 Default-deny egress with a minimal allow-list

Permit outbound only what the device genuinely needs:

| Purpose            | Destination              | Protocol / Port |
|--------------------|--------------------------|-----------------|
| Pauhu API          | `PAUHU_API_FQDN`         | TCP 443 (TLS)   |
| Pauhu sign-in      | `PAUHU_AUTH_FQDN`        | TCP 443 (TLS)   |
| Name resolution    | your trusted DNS resolver| UDP/TCP 53 (or DoT/DoH 853/443) |
| Time synchronisation | your trusted NTP source | UDP 123         |

Also keep the local network-control traffic your network needs, such as IPv6 neighbour and router
discovery (RFC 4890). The templates cover IPv6 addressing by SLAAC or static configuration; if your network
assigns addresses by DHCPv6, add a scoped client rule for UDP 546 to 547. Deny all other outbound traffic. Time sync matters: TLS certificate validation depends on
an accurate clock. (CIS Controls v8 - Controls 4 "Secure Configuration" and 13 "Network
Monitoring and Defense".)

### 2.2 No inbound

- No port forwarding, no inbound NAT, no public listener on the device.
- The device accepts no unsolicited connection from the Internet.
- Management access (SSH, RDP, local web UI) is never exposed to the Internet; reach it
  only over a separate management network or VPN.

### 2.3 Transport security

- Require **TLS 1.2 or higher**; prefer **TLS 1.3** (RFC 8446). Disable TLS 1.1 and
  earlier and all plaintext HTTP (RFC 8996 deprecates TLS 1.1 and below).
- Validate the full certificate chain and the hostname on every connection. Never disable
  certificate verification "to make it work".
- Do not pin a single leaf certificate: certificates are renewed routinely. If your network
  inspects TLS, the inspecting proxy must itself validate the upstream certificate and host name.
- Honour HSTS (RFC 6797) where your client stack supports it.

### 2.4 Device identity and keys (application layer, not the firewall)

- **Proposed:** each device authenticates with its **own key**. One device, one key.
- Store the key in a hardware secure element / TPM where the device has one; otherwise in
  OS-protected storage with least-privilege file permissions.
- **Never** commit a key, token or secret to a source repository, image or firmware blob.
  Provision it at enrolment and make it rotatable if a device is compromised.
- The firewall complements authentication; it does not replace it. (NIST SP 800-207.)

### 2.5 Segmentation and zoning (especially OT)

For industrial / operational-technology sites, follow **IEC 62443** zones and conduits and
**NIST SP 800-82 Rev. 3** (Guide to OT Security):

- Place the connecting device in its own network segment / VLAN, isolated from the control
  network and from unrelated IT.
- Define a single **conduit** for the device's outbound path to `PAUHU_API_FQDN`; the
  device must not bridge the IT and OT networks.
- For the strictest sites, route outbound through a controlled boundary - an egress proxy,
  or a data diode (a one-way link) where the use case allows send-only telemetry.

### 2.6 Egress rate budgeting

- Measure your device's request rate, response sizes and connection duration, and set limits
  appropriate to its workload.
- A sudden rise in outbound volume or new destinations is an early signal of a compromised
  device being used for exfiltration, scanning or command-and-control. Rate caps contain
  that blast radius.

### 2.7 Fail-safe, never fail-open

- If egress is blocked or the API is unreachable, the device must degrade **safely**: it
  keeps functioning in a defined safe state and retries later, following the safe-retry and
  recovery rules in `README.md` section 8. It must not drop open, lose
  queued work, or make a safety function depend on reaching the network.
- An OT safety or control function must **never** depend on a successful API call.
- **Proposed:** a previously approved signed offline grant reconciles once when connectivity
  returns, without duplicating a billed effect. A cache you run yourself is not a Pauhu entitlement.

### 2.8 IPv6 parity

- Apply the same default-deny egress rules to **IPv6** as to IPv4. A device that enforces
  IPv4 rules but leaves IPv6 open is a common and serious gap.
- If the device does not need IPv6, disable it.

### 2.9 Logging, monitoring and maintenance

- Log allowed and denied egress. Alert on connections to anything outside the allow-list.
- Forward logs to your SIEM / monitoring where you run one. (CIS Control 8 "Audit Log
  Management", Control 13 "Network Monitoring and Defense".)
- Keep firmware and the OS patched and signed. Verify software supply-chain integrity.
- For EU operators, this baseline can be one input to work under **NIS2** and the
  **Cyber Resilience Act**. It is not a certification or a statement of compliance.

---

## 3. Standards referenced

- **NIST SP 800-41 Rev. 1** - Guidelines on Firewalls and Firewall Policy (default-deny).
- **NIST SP 800-207** - Zero Trust (no implicit trust; per-request posture).
- **NIST SP 800-82 Rev. 3** - Guide to Operational Technology (OT) Security.
- **IEC 62443** - Industrial communication networks; zones and conduits.
- **NIST SP 800-183** - Networks of 'Things' (IoT composition).
- **CIS Controls v8** - Controls 4, 8, 12, 13.
- **RFC 9293** - Transmission Control Protocol (TCP).
- **RFC 8446** - TLS 1.3. **RFC 8996** - Deprecating TLS 1.0 and 1.1.
- **RFC 6797** - HTTP Strict Transport Security (HSTS).
- **EU** - NIS2 Directive; Cyber Resilience Act (CRA).

---

## 4. Example configurations

These are **templates**, not drop-in configurations. Each encodes the same target shape -
default-deny egress with an allow-list to `PAUHU_API_FQDN` and `PAUHU_AUTH_FQDN` over TCP
443, trusted DNS and trusted NTP, and no inbound. Every one needs **site-specific
implementation and a verification readback** before you rely on it. In particular you must
supply the real addresses (or an egress proxy that enforces the hostnames), confirm the
applied direction and interface for your topology, and govern **both** IPv4 and IPv6 (or
verifiably disable IPv6). For IPv6, make sure the applied rules keep the neighbour and router
discovery your network needs (RFC 4890) and check it before use. Confirm the hostnames against the Endpoints table in `README.md`.

The **scripts** (`iptables.sh`, `ufw.sh`, `windows-defender-firewall.ps1`) flush or replace
existing rules. The two Linux scripts **fail closed**: each refuses to finish, and reads back,
unless the default-deny / no-inbound / both-families posture is in effect. The Windows script
neutralises pre-existing local allow rules, then reads back the effective policy
(`-PolicyStore ActiveStore`, local rules merged with Group Policy) and refuses to finish if any
other allow rule or a different profile default is in effect.
`nftables.conf` is an **atomic ruleset file** loaded with `nft -f`: `flush ruleset` replaces all
existing rules in one transaction and the TCP/UDP allow rules are bound to sets that ship empty, so
the listed services (HTTPS, DNS, NTP) are blocked until you populate them. Loopback, established
and related traffic and the listed ICMPv6 types, including echo request, stay allowed regardless
of the sets. The file itself
performs no post-apply readback, so after loading it you must verify the result yourself with
`nft list ruleset`. The `pfsense-opnsense.md`, `cisco-acl.txt` and `iec62443-ot-conduit.md`
entries are **outlines**: implement them in your platform and verify the applied result yourself.

- `firewall/nftables.conf` - Linux nftables (atomic `nft -f` ruleset; empty sets block the listed TCP/UDP services; verify with `nft list ruleset`)
- `firewall/iptables.sh` - Linux iptables, legacy (script, flushes both families, fail-closed readback)
- `firewall/ufw.sh` - Ubuntu/Debian UFW (script, fail-closed readback)
- `firewall/windows-defender-firewall.ps1` - Windows Defender Firewall (script, neutralises stray local allows, effective-policy readback including Group Policy)
- `firewall/pfsense-opnsense.md` - pfSense / OPNsense rule outline
- `firewall/cisco-acl.txt` - Cisco IOS / ASA egress ACL outline
- `firewall/iec62443-ot-conduit.md` - OT zone & conduit outline

> These templates are a security baseline, not a guarantee and not an attestation that your
> device is secured. Review them against your own risk assessment and the standards above,
> implement the site-specific parts, and verify the applied result before relying on them.
