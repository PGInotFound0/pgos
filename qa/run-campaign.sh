#!/usr/bin/env bash
#
# run-campaign.sh — pgOS boot-reliability campaign: 30 live-boot cycles.
# Matrix: rounds 1-10 BIOS/headless, 11-20 EFI/headless, 21-30 EFI/gui.
# Evidence per round: serial.log + VBox.log tail; aggregate in summary.txt.
#
set -u

BASE="$HOME/pgos"
QA="$BASE/qa"
ROUNDS="$QA/rounds"
SUMMARY="$QA/summary.txt"
SERIAL_BASE="/tmp/opencode/campaign-serial.log"
VMLOG="/mnt/data/Virtual machine/pgOS/Logs/VBox.log"
vm() { VBoxManage "$@"; }

mkdir -p "$ROUNDS" "$QA"
: > "$SUMMARY"

echo "=== pgOS 30-run campaign $(date -Iseconds) ===" | tee -a "$SUMMARY"

# Bring the VM down first, THEN take the snapshot anchor
vm controlvm pgOS poweroff 2>/dev/null
wait_off() {
    local n=0
    while [ "$n" -lt 20 ]; do
        s="$(vm showvminfo pgOS 2>/dev/null | awk '/^State:/{print $2}')"
        [ "$s" = "powered" ] && return 0
        sleep 3; n=$((n + 1))
    done
    return 1
}
wait_off || echo "[campaign] slow initial poweroff" >&2
vm snapshot pgOS take pre-campaign 2>/dev/null && \
    echo "[campaign] snapshot 'pre-campaign' taken" | tee -a "$SUMMARY"

verdict() { # $1=round $2=verdict $3=note
    printf "round %-2s : %-4s : fw=%-4s type=%-8s : %s\n" \
        "$1" "$2" "$3" "$4" "$5" | tee -a "$SUMMARY"
}

run_round() {
    local i="$1" fw="$2" type="$3"
    local log="$ROUNDS/round-$i"
    mkdir -p "$log"
    local serial="$log/serial.log"
    local note="" verdict_result="?"

    vm controlvm pgOS poweroff 2>/dev/null
    wait_off || echo "[warn $i] slow poweroff" >&2
    sleep 2

    vm modifyvm pgOS --firmware "$fw" 2>/dev/null
    vm modifyvm pgOS --uart1 0x3F8 4 2>/dev/null
    vm modifyvm pgOS --uartmode1 file "$serial" 2>/dev/null
    : > "$serial"

    if vm startvm pgOS --type "$type" >/dev/null 2>&1; then
        echo "[$i] started ($fw/$type)" >&2
    else
        verdict "$i" "FAIL" "$fw" "$type" "startvm refused" ; return 1
    fi

    # Watch the boot: within 100s, look for multi-user-ish markers in serial.
    local tries=0 pass=0
    while [ "$tries" -lt 45 ]; do
        if grep -qE "Reached target Multi-User|Started Journal Service|systemd-logind" \
               "$serial" 2>/dev/null; then
            pass=1; break
        fi
        s="$(vm showvminfo pgOS 2>/dev/null | awk '/^State:/{print $2}')"
        case "$s" in
            aborted|saved) pass=0; break ;;
        esac
        sleep 4; tries=$((tries + 1))
    done

    sleep 3   # let the last lines land
    if [ "$pass" -eq 1 ]; then
        verdict_result="PASS"
        note="boot reached userspace ($(grep -c 'systemd\[1\]' "$serial" 2>/dev/null) systemd events)"
    else
        verdict_result="FAIL"
        note="no userspace markers in $(wc -l < "$serial" 2>/dev/null) serial lines"
    fi
    verdict "$i" "$verdict_result" "$fw" "$type" "$note"

    # Save VBox.log tail for the round
    [ -f "$VMLOG" ] && tail -c 20000 "$VMLOG" > "$log/VBox-tail.txt" 2>/dev/null

    vm controlvm pgOS poweroff 2>/dev/null
    wait_off
    return 0
}

echo "process=serial-witness-per-round" | tee -a "$SUMMARY"

for i in $(seq 1 10);   do run_round "$i" bios headless;  done
for i in $(seq 11 20);  do run_round "$i" efi  headless;  done
for i in $(seq 21 30);  do run_round "$i" efi  gui;       done

echo "=== total ===" | tee -a "$SUMMARY"
pass_total=$(grep -c ": PASS :" "$SUMMARY")
fail_total=$(grep -c ": FAIL :" "$SUMMARY")
echo "PASS=$pass_total FAIL=$fail_total of 30" | tee -a "$SUMMARY"

grep -h "FAIL" "$SUMMARY" | while read -r line; do echo "[divergence] $line"; done >> "$SUMMARY"
echo "=== serial sanity: aggregate failure fingerprints ==="
for f in "$ROUNDS"/round-*/serial.log; do
    emark=$(grep -ci emergency "$f" 2>/dev/null)
    fmark=$(grep -cE "\[FAILED\]" "$f" 2>/dev/null)
    [ "$emark" -gt 0 ] || [ "$fmark" -gt 0 ] && \
        echo "$(basename "$(dirname "$f")"): emergency=$emark failed=$fmark" >> "$SUMMARY"
done
echo "=== campaign end $(date -Iseconds) ===" | tee -a "$SUMMARY"
