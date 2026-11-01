#!/usr/bin/env bash
# Default-deny egress for a device that connects to the Pauhu API (legacy iptables).
# No inbound. Outbound only to the Pauhu endpoints (TCP 443), trusted DNS and trusted NTP.
# This TEMPLATE governs BOTH IPv4 and IPv6 and fails closed: it refuses to finish unless both
# families end in a DROP default policy. Review against your own topology before running.
#
# iptables matches IP addresses, not hostnames. Set the address variables from the resolved
# addresses of PAUHU_API_FQDN / PAUHU_AUTH_FQDN (from a trusted resolver) and refresh them
# when they change, or enforce the hostname at an egress proxy instead.
set -euo pipefail

DNS_SERVER="${DNS_SERVER:?set DNS_SERVER to your trusted resolver (IPv4)}"
NTP_SERVER="${NTP_SERVER:?set NTP_SERVER to your trusted NTP source (IPv4)}"
PAUHU_IPS="${PAUHU_IPS:?set PAUHU_IPS to the resolved IPv4 addresses of the Pauhu endpoints}"  # space-separated
# IPv6: supply the v6 equivalents, OR set DISABLE_IPV6=1 to deny ALL IPv6 egress instead.
DISABLE_IPV6="${DISABLE_IPV6:-0}"
DNS_SERVER6="${DNS_SERVER6:-}"
NTP_SERVER6="${NTP_SERVER6:-}"
PAUHU_IPS6="${PAUHU_IPS6:-}"

prog() {   # $1 = iptables | ip6tables
    local ipt="$1"
    # start from a clean slate so no pre-existing ACCEPT rule survives
    "$ipt" -F
    "$ipt" -X
    "$ipt" -P INPUT DROP
    "$ipt" -P FORWARD DROP
    "$ipt" -P OUTPUT DROP
    "$ipt" -A INPUT  -i lo -j ACCEPT
    "$ipt" -A INPUT  -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    "$ipt" -A OUTPUT -o lo -j ACCEPT
    "$ipt" -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
}

allow_egress() {   # $1 = iptables|ip6tables  $2 = dns  $3 = ntp  $4.. = api ips
    local ipt="$1" dns="$2" ntp="$3"; shift 3
    "$ipt" -A OUTPUT -p udp -d "$dns" --dport 53  -j ACCEPT
    "$ipt" -A OUTPUT -p tcp -d "$dns" --dport 53  -j ACCEPT
    "$ipt" -A OUTPUT -p udp -d "$ntp" --dport 123 -j ACCEPT
    local ip
    for ip in "$@"; do
        "$ipt" -A OUTPUT -p tcp -d "$ip" --dport 443 -j ACCEPT
    done
    "$ipt" -A OUTPUT -j LOG --log-prefix "pauhu-egress-drop: "
}

icmp6_allow() {   # $1 = INPUT | OUTPUT  -- ip6tables only
    # RFC 4890 4.4/4.4.1: permit only the REQUIRED link-local ICMPv6 for a CLIENT host, ROLE and
    # DIRECTION specific. established,related does not cover the initial ND a device sends/receives.
    # hop limit 255 = the RFC 4861 on-link guarantee; MLD is kept link-local by hop limit 1 (NOT by
    # a destination prefix: an MLDv1 report goes to the group address, whose scope may exceed ff02::).
    local ch="$1" t
    if [ "$ch" = INPUT ]; then
        # a client RECEIVES RA (134), NS (135), NA (136); it does NOT accept RS (only routers do)
        for t in 134 135 136; do
            ip6tables -A INPUT -p icmpv6 --icmpv6-type "$t" -m hl --hl-eq 255 -j ACCEPT
        done
        ip6tables -A INPUT -p icmpv6 --icmpv6-type 129 -j ACCEPT                 # echo reply
        ip6tables -A INPUT -p icmpv6 --icmpv6-type 130 -m hl --hl-eq 1 -j ACCEPT # MLD query
    else
        # a client SENDS RS (133), NS (135), NA (136); it does NOT send RA (134 = rogue router)
        for t in 133 135 136; do
            ip6tables -A OUTPUT -p icmpv6 --icmpv6-type "$t" -m hl --hl-eq 255 -j ACCEPT
        done
        ip6tables -A OUTPUT -p icmpv6 --icmpv6-type 128 -j ACCEPT                # echo request
        for t in 131 132 143; do                                                # MLD reports / done
            ip6tables -A OUTPUT -p icmpv6 --icmpv6-type "$t" -m hl --hl-eq 1 -j ACCEPT
        done
    fi
    # ICMPv6 errors that must not be dropped, both directions (RFC 4890 4.4.1): dest-unreachable (1),
    # packet-too-big (2, PMTUD), time-exceeded code 0 (3/0), parameter-problem codes 1 and 2 (4/1,4/2).
    ip6tables -A "$ch" -p icmpv6 --icmpv6-type 1   -j ACCEPT
    ip6tables -A "$ch" -p icmpv6 --icmpv6-type 2   -j ACCEPT
    ip6tables -A "$ch" -p icmpv6 --icmpv6-type 3/0 -j ACCEPT
    ip6tables -A "$ch" -p icmpv6 --icmpv6-type 4/1 -j ACCEPT
    ip6tables -A "$ch" -p icmpv6 --icmpv6-type 4/2 -j ACCEPT
    # Covers IPv6 addressing by SLAAC or static configuration. NOT configured: DHCPv6 (a device that
    # gets its address by DHCPv6 also needs UDP sport 546 -> dport 547 to the server/relay -- add it
    # if your network uses DHCPv6), SEND (148/149), inverse ND (141/142), multicast-router discovery
    # (151-153). Add rules for those if your device uses them.
}

# ---- IPv4 ----
prog iptables
allow_egress iptables "$DNS_SERVER" "$NTP_SERVER" $PAUHU_IPS

# ---- IPv6 ----
prog ip6tables
if [ "$DISABLE_IPV6" = "1" ]; then
    # deny all IPv6 egress (loopback + established already allowed by prog)
    ip6tables -A OUTPUT -j LOG --log-prefix "pauhu-egress-drop6: "
else
    [ -n "$DNS_SERVER6" ] && [ -n "$NTP_SERVER6" ] && [ -n "$PAUHU_IPS6" ] || {
        echo "IPv6 is enabled but DNS_SERVER6/NTP_SERVER6/PAUHU_IPS6 are unset." >&2
        echo "Set them, or set DISABLE_IPV6=1 to deny all IPv6 egress. Refusing to finish." >&2
        exit 1
    }
    # required link-local ICMPv6 control traffic first (RFC 4890), then the egress allow-list
    icmp6_allow INPUT
    icmp6_allow OUTPUT
    allow_egress ip6tables "$DNS_SERVER6" "$NTP_SERVER6" $PAUHU_IPS6
fi

# ---- fail-closed readback: both families must default to DROP ----
for ipt in iptables ip6tables; do
    for chain in INPUT FORWARD OUTPUT; do
        pol=$("$ipt" -S "$chain" | sed -n '1p')
        case "$pol" in
            "-P $chain DROP") ;;
            *) echo "READBACK FAILED: $ipt $chain is not DROP ($pol)" >&2; exit 1 ;;
        esac
    done
done
echo "Applied and read back: IPv4 and IPv6 default to DROP, egress allow-list only."
