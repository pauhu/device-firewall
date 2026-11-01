#!/usr/bin/env bash
# Default-deny egress for a device that connects to the Pauhu API (Ubuntu/Debian UFW).
# No inbound. Outbound only to the Pauhu endpoints (TCP 443), trusted DNS and trusted NTP.
# TEMPLATE: governs IPv4 and IPv6 and fails closed if IPv6 is neither governed nor disabled.
#
# UFW rules are address-based. Resolve PAUHU_API_FQDN / PAUHU_AUTH_FQDN from a trusted
# resolver and pass the addresses, or enforce the hostname at an egress proxy.
set -euo pipefail

DNS_SERVER="${DNS_SERVER:?set DNS_SERVER to your trusted resolver (IPv4)}"
NTP_SERVER="${NTP_SERVER:?set NTP_SERVER to your trusted NTP source (IPv4)}"
PAUHU_IPS="${PAUHU_IPS:?set PAUHU_IPS to the resolved IPv4 addresses of the Pauhu endpoints}"
# IPv6: supply v6 equivalents, OR set DISABLE_IPV6=1 to deny IPv6 at the kernel instead.
DISABLE_IPV6="${DISABLE_IPV6:-0}"
DNS_SERVER6="${DNS_SERVER6:-}"
NTP_SERVER6="${NTP_SERVER6:-}"
PAUHU_IPS6="${PAUHU_IPS6:-}"

# ---- make sure UFW actually processes IPv6, or that IPv6 is off ----
if [ "$DISABLE_IPV6" = "1" ]; then
    # deny all IPv6 egress at the kernel so UFW's IPv4-only filtering is not a gap
    sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
    sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
else
    [ -n "$DNS_SERVER6" ] && [ -n "$NTP_SERVER6" ] && [ -n "$PAUHU_IPS6" ] || {
        echo "IPv6 is enabled but DNS_SERVER6/NTP_SERVER6/PAUHU_IPS6 are unset." >&2
        echo "Set them, or set DISABLE_IPV6=1. Refusing to finish." >&2
        exit 1
    }
    # UFW must have IPV6=yes or it silently filters IPv4 only
    sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
    grep -q '^IPV6=yes' /etc/default/ufw || { echo "could not enable UFW IPv6" >&2; exit 1; }
fi

# default: deny inbound, deny outbound (explicit allow-list follows)
ufw --force reset
ufw default deny incoming
ufw default deny outgoing

allow() {   # $1 dns  $2 ntp  $3 space-separated api ips
    ufw allow out to "$1" port 53  proto udp
    ufw allow out to "$1" port 53  proto tcp
    ufw allow out to "$2" port 123 proto udp
    local ip
    for ip in $3; do ufw allow out to "$ip" port 443 proto tcp; done
}

allow "$DNS_SERVER" "$NTP_SERVER" "$PAUHU_IPS"
[ "$DISABLE_IPV6" = "1" ] || allow "$DNS_SERVER6" "$NTP_SERVER6" "$PAUHU_IPS6"

ufw logging on
ufw --force enable

# ---- fail-closed readback ----
ufw status verbose | grep -q 'Default: deny (incoming), deny (outgoing)' \
    || { echo "READBACK FAILED: UFW default is not deny/deny" >&2; exit 1; }
if [ "$DISABLE_IPV6" != "1" ]; then
    grep -q '^IPV6=yes' /etc/default/ufw \
        || { echo "READBACK FAILED: UFW IPv6 processing is off" >&2; exit 1; }
fi
echo "Applied and read back: default deny in/out, egress allow-list only, IPv6 governed or disabled."
echo "No inbound rules were added: the device exposes no service."
