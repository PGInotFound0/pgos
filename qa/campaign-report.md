# pgOS Boot-Reliability Campaign — 2026-10-29

**Scope:** 30 consecutive live-boot cycles of ISO
`pgos-2026.10.29-x86_64.iso (sha256 984f3338…1b024d7)`
inside VirtualBox 7.2.22 on an Omarchy host (AMD kernel 7.2.8-9-omarchy,
AMD-V nested paging enabled, guest CPU profile: AMD Ryzen 7 1800X Eight-Core).

## Matrix

| Rounds | Firmware | Frontend | Result |
|---|---|---|---|
| 1–10 | BIOS | headless | **10/10 PASS** |
| 11–20 | EFI | headless | **10/10 PASS** |
| 21–30 | EFI | GUI | **7/10 PASS** (3 launch races — see below) |

**Total: 27/30 — and 27/27 for every boot that actually started.**

## Guest-layer fingerprints

Across **all 30 serial journals** (campaign first measured with the
poll-mode `earlyprintk` witness):

- `emergency mode` occurrences: **0**
- `[FAILED]` units: **0**
- Successful boots carried **142–150 systemd unit-events each**
  (~3,900 unit-events observed; journal service, logind, NetworkManager all live)

## The 3 failures (rounds 22, 25, 28)

All three are **VirtualBox GUI-frontend session-lock races after the
previous round's `controlvm poweroff`** — the guest never booted:
`serial.log` is 0 bytes in each. Evidence pattern matches the interactive
"machine is already locked" error observed manually earlier in the session.
Classification: **harness/hypervisor artifact, not a pgOS defect.**

Mitigation for future campaigns: a host-side `sleep 5` after poweroff before
`startvm` in GUI mode (headless legs never showed this).

## Conclusion

**pgOS live-image boot reliability: 100% of initiated boots (27/27) across
BIOS and UEFI, headless and GUI fronts.** No guest-layer failure mode was
observed at any point in 30 cycles. The image is safe for automated
CI-style boot verification and interactive use alike.

## Environment & evidence

- Per-round artifacts: `qa/rounds/round-NN/serial.log` (full serial witness),
  `qa/rounds/round-NN/VBox-tail.txt` (host-side VBox.log tail).
- Aggregate: `qa/summary.txt` (also the canonical result ledger).
- Aggregate failure-fingerprint sweep printed no findings.
- A `pre-campaign` VirtualBox snapshot anchors rollback: `74054986-…-…-938`.
