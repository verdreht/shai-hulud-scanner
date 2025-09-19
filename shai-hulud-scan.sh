#!/usr/bin/env bash
# ./scan.sh packages.txt /path/to/project
set -euo pipefail

CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[91m"
BLUE="\033[34m"
RESET="\033[0m"

if [ $# -lt 1 ]; then
    printf "Usage: %s <file-with-packages> [project-dir]\n" "$0"
    exit 1
fi

FILE="$1"
PROJECT_DIR="${2:-.}"

if [ ! -f "$FILE" ]; then
    printf "%b✘ File not found:%b %s\n" "$RED" "$RESET" "$FILE"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    printf "%b✘ Project directory not found:%b %s\n" "$RED" "$RESET" "$PROJECT_DIR"
    exit 1
fi

BAD_HASHES=(
    "de0e25a3e6c1e1e5998b306b7141b3dc4c0088da9d7bb47c1c00c91e6e4f85d6"
    "81d2a004a1bca6ef87a1caf7d0e0b355ad1764238e40ff6d1b1cb77ad4f595c3"
    "83a650ce44b2a9854802a7fb4c202877815274c129af49e6c2d1d5d5d55c501e"
    "4b2399646573bb737c4969563303d8ee2e9ddbd1b271f1ca9e35ea78062538db"
    "dc67467a39b70d1cd4c1f7f7a459b35058163592f4a9e8fb4dffcbba98ef210c"
    "46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09"
    "b74caeaa75e077c99f7d44f46daaf9796a3be43ecf24f2a1fd381844669da777"
)

packages=()
while IFS= read -r line || [ -n "$line" ]; do
    pkg=$(echo "$line" | xargs)
    [ -n "$pkg" ] && packages+=("$pkg")
done < "$FILE"

total=${#packages[@]}
found=0
not_found=0
found_list=()
notfound_list=()

draw_progress() {
    local current=$1
    local total=$2
    local pkg=$3
    local width=40
    local percent=$((current * 100 / total))
    (( percent > 100 )) && percent=100

    local filled=$((percent * width / 100))
    (( current == total )) && filled=$width
    local empty=$((width - filled))
    local bar_filled bar_empty

    if (( current == total )); then
        bar_filled=$(printf "%0.s█" $(seq 1 $filled))
    else
        local pulse_chars=("█" "▓")
        local pulse_idx=$((RANDOM % 2))
        bar_filled=$(printf "%0.s${pulse_chars[$pulse_idx]}" $(seq 1 $filled))
    fi

    bar_empty=$(printf "%0.s░" $(seq 1 $empty))

    local term_lines=$(tput lines)
    local bar_row=$term_lines
    printf "\033[s"
    printf "\033[%d;1H" "$bar_row"
    printf "\r[%b%s%b%s] %3d%%  %b" \
        "$BLUE" "$bar_filled" "$RESET" "$bar_empty" "$percent" "$pkg"
    printf "\033[u"
}

printf "%b➤ Starting worm check in project:%b %s\n" "$CYAN" "$RESET" "$PROJECT_DIR"
printf "%b➤ Total packages to check:%b %d\n" "$CYAN" "$RESET" "$total"
echo

for i in "${!packages[@]}"; do
    pkg="${packages[$i]}"
    idx=$((i+1))
    if [[ "$pkg" == *@* && "$pkg" != @* ]]; then
        name="${pkg%@*}"
    else
        name="$pkg"
    fi

    if (( idx != total )); then
        for ((j=0; j<2; j++)); do
            clear
            printf "%b➤ Worm scan in project:%b %s\n" "$CYAN" "$RESET" "$PROJECT_DIR"
            printf "%b➤ Total packages to check:%b %d\n\n" "$CYAN" "$RESET" "$total"
            if [ ${#notfound_list[@]} -gt 0 ]; then
                for nf in "${notfound_list[@]}"; do
                    printf "%b⚠ NOT FOUND:%b %s\n" "$YELLOW" "$RESET" "$nf"
                done
                printf "\n"
            fi
            draw_progress "$idx" "$total" "$pkg"
            sleep 0.05
        done
    fi

    if npm --prefix "$PROJECT_DIR" ls "$name" >/dev/null 2>&1; then
        found=$((found+1))
        found_list+=("$pkg")
    else
        not_found=$((not_found+1))
        notfound_list+=("$pkg")
    fi
done

clear

printf "%b➤ Checking for known bad file hashes...%b\n" "$CYAN" "$RESET"
hash_found=0
hash_tool=""
if command -v sha256sum >/dev/null 2>&1; then
    hash_tool="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    hash_tool="shasum -a 256"
fi

if [ -n "$hash_tool" ]; then
    for bad in "${BAD_HASHES[@]}"; do
        files=$(find "$PROJECT_DIR" -type f -name "*.js" -exec $hash_tool {} \; 2>/dev/null | grep -F "$bad" || true)
        if [ -n "$files" ]; then
            printf "%b✘ INFECTED%b Found bad hash: %s\n" "$RED" "$RESET" "$bad"
            echo "$files"
            hash_found=$((hash_found+1))
        fi
    done
else
    printf "%b⚠ No hash tool available (sha256sum/shasum). Skipping hash scan.%b\n" "$YELLOW" "$RESET"
fi

printf "\n%b===== SCAN SUMMARY =====%b\n" "$CYAN" "$RESET"
printf "%b✔ Packages found:   %d%b\n" "$GREEN" "$found" "$RESET"
printf "%b⚠ Packages missing: %d%b\n" "$YELLOW" "$not_found" "$RESET"
if [ "$hash_found" -gt 0 ]; then
    printf "%b✘ Bad file hashes detected: %d%b\n" "$RED" "$hash_found" "$RESET"
else
    printf "%b✔ No bad file hashes detected%b\n" "$GREEN" "$RESET"
fi

if [ ${#found_list[@]} -gt 0 ]; then
    printf "\n%bList of found packages:%b\n" "$CYAN" "$RESET"
    for p in "${found_list[@]}"; do
        printf "  %b\n" "$p"
    done
fi
