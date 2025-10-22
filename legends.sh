#!/usr/bin/env bash
# Legends — Bash RPG (macOS/Bash 3.2 compatible)
set -euo pipefail

STATE_ROOT="$HOME/.local/state/legends"
mkdir -p "$STATE_ROOT"

# ========== UI ==========
banner() {
  cat <<'BANNER'
██╗     ███████╗ ██████╗  ██████╗ ███████╗███╗   ██╗███████╗
██║     ██╔════╝██╔═══██╗██╔════╝ ██╔════╝████╗  ██║██╔════╝
██║     █████╗  ██║   ██║██║  ███╗█████╗  ██╔██╗ ██║███████╗
██║     ██╔══╝  ██║   ██║██║   ██║██╔══╝  ██║╚██╗██║╚════██║
███████╗███████╗╚██████╔╝╚██████╔╝███████╗██║ ╚████║███████║
╚══════╝╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝
BANNER
}

pause() { read -r -p "Press Enter to continue..." _; }

# ========== RNG helpers ==========
d() { # d <sides> -> 1..sides
  local s=${1:-6}
  echo $(( 1 + RANDOM % s ))
}
clamp() { # clamp <val> <min> <max>
  local v=$1 lo=$2 hi=$3
  (( v<lo )) && v=$lo
  (( v>hi )) && v=$hi
  echo "$v"
}

# ========== Save system ==========
# Save format: KEY=VAL lines (safe for source)
save_path() {
  local n="$1" c="$2"
  echo "$STATE_ROOT/${n}_${c}.save"
}

save_player() {
  local p
  p=$(save_path "$NAME" "$CLASS")
  cat > "$p" <<EOF
NAME=$NAME
CLASS=$CLASS
HP=$HP
MAXHP=$MAXHP
GOLD=$GOLD
XP=$XP
LVL=$LVL
STR=$STR
DEX=$DEX
INT=$INT
VIT=$VIT
WIS=$WIS
POTIONS=$POTIONS
EOF
}

load_player_by_file() {
  local f="$1"
  # shellcheck disable=SC1090
  source "$f"
  # sanity defaults
  : "${NAME:=Hero}"
  : "${CLASS:=Peasant}"
  : "${LVL:=1}"
  : "${HP:=10}" ; : "${MAXHP:=10}"
  : "${GOLD:=5}" ; : "${XP:=0}"
  : "${STR:=3}" ; : "${DEX:=3}" ; : "${INT:=3}" ; : "${VIT:=3}" ; : "${WIS:=3}"
  : "${POTIONS:=0}"
  # post-load clamps
  MAXHP=$(clamp "${MAXHP:-10}" 1 999)
  HP=$(clamp "${HP:-10}" 1 "$MAXHP")
  LVL=$(clamp "${LVL:-1}" 1 99)
}

has_saves() {
  ls "$STATE_ROOT"/*.save >/dev/null 2>&1
}

list_saves() {
  find "$STATE_ROOT" -maxdepth 1 -name "*.save" -print 2>/dev/null | sort
}

# ========== Character ops ==========
pick_class() {
  echo "Choose your class:"
  echo "1) Warrior  (STR/VIT focus)"
  echo "2) Sorcerer (INT/WIS focus)"
  echo "3) Necromancer (INT/VIT; dark arts)"
  read -r -p "Class (1-3): " c
  case "$c" in
    1) CLASS="Warrior";   STR=5; VIT=4; DEX=3; INT=2; WIS=2; MAXHP=14; POTIONS=1 ;;
    2) CLASS="Sorcerer";  STR=2; VIT=3; DEX=3; INT=5; WIS=4; MAXHP=10; POTIONS=2 ;;
    3) CLASS="Necromancer"; STR=2; VIT=4; DEX=3; INT=5; WIS=3; MAXHP=11; POTIONS=2 ;;
    *) echo "Defaulting to Peasant."; CLASS="Peasant"; STR=3; VIT=3; DEX=3; INT=3; WIS=3; MAXHP=10; POTIONS=0 ;;
  esac
  HP=$MAXHP; GOLD=5; XP=0; LVL=1
}

create_character() {
  clear; banner
  echo "🧝 Create New Character"
  while true; do
    read -r -p "Enter name: " NAME
    NAME="${NAME:-Hero}"
    # normalize file-safe class later
    pick_class
    local p
    p=$(save_path "$NAME" "$CLASS")
    if [[ -f "$p" ]]; then
      echo "⚠️  A save for '$NAME' ($CLASS) already exists."
      read -r -p "Overwrite? (y/N): " ans
      case "$ans" in
        y|Y) break ;;
        *)   echo "Pick a different name or class."; continue ;;
      esac
    fi
    break
  done
  save_player
  echo "✅ Created: $NAME the $CLASS"
  pause
}

delete_character() {
  clear; banner
  if ! has_saves; then
    echo "No saves to delete."; pause; return
  fi
  echo "💀 Delete Character"
  local i=1 f choice
  while read -r f; do
    # shellcheck disable=SC1090
    source "$f"
    echo "$i) $NAME the $CLASS"
    i=$((i+1))
  done < <(list_saves)
  read -r -p "Pick number to delete (or blank to cancel): " choice
  [[ -z "${choice:-}" ]] && return
  i=1
  while read -r f; do
    if [[ "$i" -eq "$choice" ]]; then
      rm -f "$f"
      echo "🗑️  Deleted."
      pause
      return
    fi
    i=$((i+1))
  done < <(list_saves)
  echo "Invalid choice."; pause
}

switch_character() {
  clear; banner
  if ! has_saves; then
    echo "No saves found — creating new."; pause
    create_character
    return
  fi
  echo "📂 Load Character"
  local i=1 f choice
  while read -r f; do
    # shellcheck disable=SC1090
    source "$f"
    echo "$i) $NAME the $CLASS"
    i=$((i+1))
  done < <(list_saves)
  read -r -p "Pick number: " choice
  [[ -z "${choice:-}" ]] && return
  i=1
  while read -r f; do
    if [[ "$i" -eq "$choice" ]]; then
      load_player_by_file "$f"
      echo "✅ Loaded $NAME the $CLASS"
      pause; return
    fi
    i=$((i+1))
  done < <(list_saves)
  echo "Invalid choice."; pause
}

character_sheet() {
  clear; banner
  echo "🧙 Character:"
  echo "Name:  $NAME"
  echo "Class: $CLASS"
  echo "Level: $LVL"
  echo "HP:    $HP/$MAXHP"
  echo "Gold:  $GOLD"
  echo "XP:    $XP"
  echo "Stats: STR=$STR  DEX=$DEX  INT=$INT  VIT=$VIT  WIS=$WIS"
  echo "Items: Potions=$POTIONS"
  pause
}

character_menu() {
  while true; do
    clear; banner
    echo "== Character Menu =="
    echo "1) View Sheet"
    echo "2) New Character"
    echo "3) Delete Character"
    echo "4) Switch Character"
    echo "5) Back"
    read -r -p "Select: " c
    case "$c" in
      1) character_sheet ;;
      2) create_character ;;
      3) delete_character ;;
      4) switch_character ;;
      5) return ;;
      *) echo "Invalid."; sleep 1 ;;
    esac
  done
}

# ========== Combat ==========
battle() {
  local enemy="$1" ehp="$2"
  clear; banner
  echo "⚔️  A wild $enemy appears! (HP $ehp)"

  while (( ehp>0 && HP>0 )); do
    echo -n "Press [r]oll, [f]lee, or [p]otion: "
    read -r action
    # normalize manually (Bash 3.2: no ${x,,})
    action=$(printf "%s" "$action" | tr '[:upper:]' '[:lower:]')
    case "$action" in
      r)
        # player hit
        local base=$(( d 6 + STR/2 ))
        local dmg=$(clamp "$base" 1 12)
        echo "You strike for $dmg!"
        ehp=$(( ehp - dmg ))
        (( ehp<0 )) && ehp=0
        if (( ehp == 0 )); then
          local gold_gain=$(( 1 + RANDOM % 2 ))
          local xp_gain=$(( 4 + RANDOM % 4 ))
          GOLD=$((GOLD + gold_gain))
          XP=$((XP + xp_gain))
          echo "🏆 $enemy defeated! +$gold_gain Gold, +$xp_gain XP"
          break
        fi
        # enemy hits
        local edmg=$(( d 4 + (RANDOM%3) - VIT/3 ))
        edmg=$(clamp "$edmg" 0 8)
        (( edmg>0 )) && echo "$enemy hits you for $edmg!" || echo "$enemy misses!"
        HP=$((HP - edmg))
        (( HP<0 )) && HP=0
        ;;
      f)
        if (( RANDOM%100 < 50 )); then
          echo "💨 You escape!"
          break
        else
          echo "You fail to escape!"
          # penalty jab
          local jab=$(( 1 + RANDOM%3 ))
          echo "$enemy nicks you for $jab!"
          HP=$((HP - jab))
          (( HP<0 )) && HP=0
        fi
        ;;
      p)
        if (( POTIONS>0 && HP<MAXHP )); then
          local heal=$(( 4 + RANDOM % 6 ))
          HP=$(( HP + heal ))
          HP=$(clamp "$HP" 1 "$MAXHP")
          POTIONS=$((POTIONS-1))
          echo "🧪 You quaff a potion (+$heal HP). ($POTIONS left)"
        else
          echo "No usable potions."
        fi
        ;;
      *) echo "Invalid action." ;;
    esac

    if (( HP<=0 )); then
      echo "💀 You fall in battle... Respawning at half max HP."
      HP=$(( (MAXHP+1)/2 ))
      break
    fi
  done

  save_player
  pause
}

# ========== Modes ==========
free_roam() {
  while true; do
    clear; banner
    echo "🌲 Free Roam — what now?"
    echo "1) Wander (chance of battle/loot)"
    echo "2) Rest at camp (-1 gold, +2 HP)"
    echo "3) Back"
    read -r -p "Choose: " c
    case "$c" in
      1)
        local roll=$(( RANDOM%100 ))
        if (( roll<50 )); then
          # battle
          local mobs=("Wolf" "Boar" "Bandit" "Slime")
          local idx=$(( RANDOM % ${#mobs[@]} ))
          local mob="${mobs[$idx]}"
          local hp=$(( 8 + RANDOM%8 + LVL ))
          battle "$mob" "$hp"
        elif (( roll<75 )); then
          local g=$((1 + RANDOM%3))
          GOLD=$((GOLD + g))
          echo "💰 You find $g gold on the roadside."
          save_player; pause
        else
          echo "You wander peacefully. Nothing happens."
          pause
        fi
        ;;
      2)
        if (( GOLD>0 )); then
          GOLD=$((GOLD-1))
          HP=$((HP+2))
          HP=$(clamp "$HP" 1 "$MAXHP")
          echo "😴 You rest and recover."
          save_player; pause
        else
          echo "Not enough gold."; pause
        fi
        ;;
      3) return ;;
      *) echo "Invalid."; sleep 1 ;;
    esac
  done
}

campaign_intro() {
  clear; banner
  echo "📖 Campaign — Chapter 1"
  echo
  case "$CLASS" in
    Warrior)
      echo "Steel sings. The Ruins test your mettle, not your mercy."
      ;;
    Sorcerer)
      echo "The air hums with latent sigils. Power waits to be shaped."
      ;;
    Necromancer)
      echo "Whispers coil in stone. The dead remember your name."
      ;;
    *) echo "The air is thick as you enter the Forgotten Ruins..." ;;
  esac
  echo
  read -r -p "[1] Enter  [2] Retreat: " a
  case "$a" in
    1)
      echo "⚔️  You step deeper into the ruins..."
      sleep 1
      local e="Ruins Slime"
      local h=$(( 10 + RANDOM%7 + LVL ))
      battle "$e" "$h"
      ;;
    2) ;;
    *) ;;
  esac
}

# ========== Main Menu ==========
main_menu() {
  while true; do
    clear; banner
    echo "== Legends — Choose Mode =="
    echo "1) Free Roam (open exploration)"
    echo "2) Campaign (story-driven)"
    echo "3) Character Menu"
    echo "4) Save + Quit"
    read -r -p "Select: " m
    case "$m" in
      1) free_roam ;;
      2) campaign_intro ;;
      3) character_menu ;;
      4)
        save_player
        echo "💾 Saved. Farewell, $NAME."
        exit 0
        ;;
      *) echo "Invalid."; sleep 1 ;;
    esac
  done
}

# ========== Bootstrap ==========
trap 'save_player; echo; echo "💾 Autosaved. Bye!"; exit 0' INT

# Load last played, otherwise make/select one
LAST_LINK="$STATE_ROOT/last.save"
if [[ -L "$LAST_LINK" && -f "$LAST_LINK" ]]; then
  load_player_by_file "$LAST_LINK"
else
  if has_saves; then
    switch_character
  else
    create_character
  fi
fi

# update "last" pointer
rm -f "$LAST_LINK"
ln -s "$(save_path "$NAME" "$CLASS")" "$LAST_LINK"

main_menu