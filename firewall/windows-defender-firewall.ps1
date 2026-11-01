# Default-deny egress for a Windows device that connects to the Pauhu API.
# Default-block inbound (only required link-local ICMPv6 control traffic is admitted). Outbound
# only to the Pauhu endpoints (TCP 443), trusted DNS and trusted NTP, plus the ICMPv6 a client
# host must send. TEMPLATE: run elevated, review against your management model (GPO/Intune/local).
#
# Windows Firewall rules are address-based. Set the address variables to the resolved addresses
# of PAUHU_API_FQDN / PAUHU_AUTH_FQDN, or enforce the hostname at an egress proxy.
#
# IMPORTANT (store consistency): a default Block action governs only traffic that no enabled rule
# matches, so any pre-existing ENABLED Allow rule would still permit traffic and defeat the
# allow-list. This script therefore keeps LOCAL rules admitted (AllowLocalFirewallRules True) so
# the allows it creates below take effect, disables every pre-existing enabled Allow rule that is
# not in the Pauhu-managed group, and then reads back the EFFECTIVE policy.
#
# INBOUND POSTURE (why AllowInboundRules is True, not False): IPv6 Neighbor/Router Discovery
# requires the device to RECEIVE link-local ICMPv6 (Router Advertisement, Neighbor Solicitation /
# Advertisement). Setting AllowInboundRules False would ignore every inbound Allow and break IPv6.
# Instead this script sets DefaultInboundAction Block with AllowInboundRules True and admits ONLY
# the Pauhu-managed inbound ICMPv6 control rule -- no inbound TCP/UDP allow exists, so no service
# or listener is exposed. The stray-Allow readback below proves nothing else inbound is effective.
#
# ICMPv6 (RFC 4890 4.4/4.4.1): the script creates role/direction-specific control rules for a
# CLIENT host -- inbound RA/NS/NA, echo-reply, MLD query and the must-not-drop errors; outbound
# RS/NS/NA, echo-request, MLD reports and errors. It does NOT send Router Advertisements. LIMITATION:
# Windows Defender Firewall cannot match hop limit, so the RFC 4861 on-link hop-limit-255 guarantee
# is NOT enforced here (nftables/iptables do enforce it); rely on a trusted L2 segment. Set
# $EnableIPv6 = $false on an IPv4-only host to omit the ICMPv6 rules.
#
# EFFECTIVE-POLICY READBACK (-PolicyStore ActiveStore): the readback queries the ActiveStore, the
# resultant set that actually filters traffic (local rules MERGED with Group Policy), for BOTH the
# per-rule checks AND the profile defaults. The default PersistentStore shows only local rules and
# would NOT reveal a GPO-pushed Allow rule or a GPO override of the profile default actions. A
# locally running script CANNOT disable a GPO rule or override a GPO profile setting, so it does not
# claim to: it neutralises pre-existing enabled LOCAL Allow rules, and the ActiveStore readback then
# FAILS CLOSED if ANY non-Pauhu Allow is still effective OR if any profile default is not the
# expected effective value -- a GPO allow or a GPO profile override is caught and throws here, it
# does not silently escape. If you manage rules centrally, publish the same allows through
# GPO/Intune and align AllowLocalFirewallRules with the store you actually use.
# Negative controls (verify on a managed host):
#   (1) add one enabled GPO Allow rule outside the Pauhu-managed group, gpupdate /force, re-run --
#       the script MUST throw at the stray-Allow check.
#   (2) set a GPO that overrides DefaultInboundAction to Allow (or AllowInboundRules), gpupdate
#       /force, re-run -- the script MUST throw at the profile readback.
#
# SAFE TO RE-RUN: the script removes any prior rules in the Pauhu-managed group before recreating
# them, so every invocation converges on the same effective set (run it twice and the second run
# leaves exactly the $spec rules, not duplicates).
#
# EXTENDING: $spec is the single source of truth. If this device legitimately needs other egress
# (for example DHCPv4 UDP 67/68, or DHCPv6 UDP 546->547 on a DHCPv6 segment -- the templates cover
# SLAAC/static addressing, not DHCPv6), add a reviewed entry to $spec below; it is
# then both created and validated by the readback. Do not add managed rules by any other path --
# the readback rejects managed rules that are not in $spec.
#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$DnsServer  = ''               # set to your trusted resolver (IPv4/IPv6)
$NtpServer  = ''               # set to your trusted NTP source
$PauhuIps   = @()              # resolved addresses of the Pauhu endpoints
$EnableIPv6 = $true            # set $false on an IPv4-only host to omit the ICMPv6 control rules

if (-not $DnsServer -or -not $NtpServer -or $PauhuIps.Count -eq 0) {
    throw 'Set $DnsServer, $NtpServer and $PauhuIps before running: this is a template.'
}

$marker = 'Pauhu-managed'

# Single source of truth for the allow-list: created AND validated from this array. 'net' entries
# are egress TCP/UDP; 'icmp6' entries are the required link-local ICMPv6 control traffic.
$spec = @(
    @{ Name = 'Pauhu-Out-DNS-UDP'; Kind = 'net'; Direction = 'Outbound'; Protocol = 'UDP'; Remote = $DnsServer; Port = 53  }
    @{ Name = 'Pauhu-Out-DNS-TCP'; Kind = 'net'; Direction = 'Outbound'; Protocol = 'TCP'; Remote = $DnsServer; Port = 53  }
    @{ Name = 'Pauhu-Out-NTP';     Kind = 'net'; Direction = 'Outbound'; Protocol = 'UDP'; Remote = $NtpServer; Port = 123 }
    @{ Name = 'Pauhu-Out-API-443'; Kind = 'net'; Direction = 'Outbound'; Protocol = 'TCP'; Remote = $PauhuIps;  Port = 443 }
)
if ($EnableIPv6) {
    # Inbound: a client RECEIVES RA (134), NS (135), NA (136), echo-reply (129), MLD query (130),
    # and the must-not-drop errors (1, 2, time-exceeded 3:0, parameter-problem 4:1 and 4:2).
    $spec += @{ Name = 'Pauhu-In-ICMPv6-Control';  Kind = 'icmp6'; Direction = 'Inbound';
                IcmpType = @('134','135','136','129','130','1','2','3:0','4:1','4:2') }
    # Outbound: a client SENDS RS (133), NS (135), NA (136), echo-request (128), MLD reports/done
    # (131,132,143) and the errors; it does NOT send RA (134).
    $spec += @{ Name = 'Pauhu-Out-ICMPv6-Control'; Kind = 'icmp6'; Direction = 'Outbound';
                IcmpType = @('133','135','136','128','131','132','143','1','2','3:0','4:1','4:2') }
}

# 1. Default-deny both directions on every profile. Keep local rules admitted so the allows take
#    effect; allow inbound rules so the ICMPv6 control rule applies (default inbound stays Block,
#    and no inbound TCP/UDP allow exists, so no service is exposed).
Set-NetFirewallProfile -Profile Domain,Private,Public `
    -DefaultInboundAction Block -DefaultOutboundAction Block `
    -AllowInboundRules True -AllowLocalFirewallRules True `
    -LogBlocked True -Enabled True

# 2. Make the apply idempotent: remove any prior Pauhu-managed rules so a re-run converges on
#    exactly $spec rather than appending duplicates.
Get-NetFirewallRule -Group $marker -ErrorAction SilentlyContinue | Remove-NetFirewallRule

# 3. Neutralise every pre-existing ENABLED Allow rule (any direction) that is not ours, so the
#    default-deny is the only policy in force before the allow-list is added. This disables the
#    built-in Core Networking rules too; the Pauhu-managed ICMPv6 rules created in step 4 restore
#    exactly the link-local control traffic a client needs.
Get-NetFirewallRule -ErrorAction SilentlyContinue |
    Where-Object { $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' -and $_.Group -ne $marker } |
    Set-NetFirewallRule -Enabled False

# 4. Create the allow-list from $spec (local store; grouped so the readback matches it).
foreach ($s in $spec) {
    if ($s.Kind -eq 'net') {
        New-NetFirewallRule -DisplayName $s.Name -Group $marker `
            -Direction $s.Direction -Action Allow -Enabled True `
            -Protocol $s.Protocol -RemoteAddress $s.Remote -RemotePort $s.Port | Out-Null
    } else {
        New-NetFirewallRule -DisplayName $s.Name -Group $marker `
            -Direction $s.Direction -Action Allow -Enabled True `
            -Protocol ICMPv6 -IcmpType $s.IcmpType | Out-Null
    }
}

# ---- fail-closed readback: prove the EFFECTIVE policy, not just the defaults ----
$profiles = Get-NetFirewallProfile -PolicyStore ActiveStore -Profile Domain,Private,Public
foreach ($p in $profiles) {
    if ($p.DefaultInboundAction -ne 'Block' -or $p.DefaultOutboundAction -ne 'Block' `
        -or $p.AllowInboundRules -ne 'True' -or $p.AllowLocalFirewallRules -ne 'True') {
        throw "READBACK FAILED on profile $($p.Name): effective default-deny / inbound-rules / local-rules posture not in effect (ActiveStore)."
    }
}

# every $spec rule exists, is enabled, and has exactly the intended direction/action/protocol and
# port/remote (net) or ICMPv6 types (icmp6), read from the EFFECTIVE (ActiveStore) policy.
foreach ($s in $spec) {
    $r = Get-NetFirewallRule -PolicyStore ActiveStore -DisplayName $s.Name -Group $marker -ErrorAction Stop
    if ($r.Direction -ne $s.Direction -or $r.Action -ne 'Allow' -or $r.Enabled -ne 'True') {
        throw "READBACK FAILED: rule $($s.Name) direction/action/enabled unexpected."
    }
    $pf = $r | Get-NetFirewallPortFilter
    if ($s.Kind -eq 'net') {
        if ($pf.Protocol -ne $s.Protocol -or "$($pf.RemotePort)" -ne "$($s.Port)") {
            throw "READBACK FAILED: rule $($s.Name) protocol/port unexpected ($($pf.Protocol)/$($pf.RemotePort))."
        }
        $af = $r | Get-NetFirewallAddressFilter
        $want = @($s.Remote); $have = @($af.RemoteAddress)
        foreach ($w in $want) {
            if ($have -notcontains $w) {
                throw "READBACK FAILED: rule $($s.Name) is missing expected remote address $w."
            }
        }
        foreach ($h in $have) {
            if ($want -notcontains $h) {
                throw "READBACK FAILED: rule $($s.Name) has an unexpected remote address $h."
            }
        }
    } else {
        if ($pf.Protocol -ne 'ICMPv6') {
            throw "READBACK FAILED: rule $($s.Name) is not ICMPv6 ($($pf.Protocol))."
        }
        $have = @($pf.IcmpType)
        foreach ($w in $s.IcmpType) {
            if ($have -notcontains $w) {
                throw "READBACK FAILED: rule $($s.Name) is missing expected ICMPv6 type $w."
            }
        }
    }
}

# exactly the $spec managed rules are enabled, and no other Allow rule survives enabled IN THE
# EFFECTIVE (ActiveStore) policy -- so a GPO-pushed Allow is caught here, not just local rules.
$managed = @(Get-NetFirewallRule -PolicyStore ActiveStore -Group $marker -ErrorAction SilentlyContinue | Where-Object { $_.Enabled -eq 'True' })
if ($managed.Count -ne $spec.Count) {
    throw "READBACK FAILED: expected $($spec.Count) managed allow rules enabled, found $($managed.Count)."
}
$strayAllow = @(Get-NetFirewallRule -PolicyStore ActiveStore -ErrorAction SilentlyContinue | Where-Object {
    $_.Enabled -eq 'True' -and $_.Action -eq 'Allow' -and $_.Group -ne $marker })
if ($strayAllow.Count -gt 0) {
    throw "READBACK FAILED: $($strayAllow.Count) non-Pauhu Allow rule(s) still effective (local or GPO); the allow-list is not strict."
}
Write-Host "Applied and read back: inbound default-block (only Pauhu-managed ICMPv6 control allowed, no service exposed), egress default-deny with exactly $($spec.Count) verified Pauhu allows in force (ActiveStore)."
Write-Host 'Safe to re-run: a second invocation leaves the same effective set. Manage by GPO/Intune? Publish the same allows there and align AllowLocalFirewallRules.'
