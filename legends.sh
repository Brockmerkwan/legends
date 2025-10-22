#!/usr/bin/env bash
set -euo pipefail

SAVE_DIR="$HOME/.local/state"
SAVE_FILE="$SAVE_DIR/legends.save"
mkdir -p "$SAVE_DIR"

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

# --- Utils ---
press_any() { read -n1 -s -r -p "Press any key to continue..." _; echo; }
num_or_default() { [[ "$1" =~ ^[0-9]+$ ]] && echo "$1" || echo "$2"; }
strip_quotes() { local s="$*"; s="${s%\"}"; s="${s#\"}"; echo "${s//\"/}"; }

# --- Save/Load (with migration) ---
save_player() {
  : "${NAME:=Hero}"; : "${CLASS:=Peasant}"
  : "${HP:=10}" : "${MAXHP:=10}" : "${GOLD:=0}" : "${XP:=0}" : "${LVL:=1}"
  : "${STR:=3}" : "${DEX:=3}" : "${INT:=3}" : "${VIT:=3}" : "${WIS:=3}"
  echo "$NAME|$CLASS|$HP|$MAXHP|$GOLD|$XP|$LVL|$STR|$DEX|$INT|$VIT|$WIS" > "$SAVE_FILE"
}

migrate_save_if_needed() {
  [[ -f "$SAVE_FILE" ]] || return 0
  local first; first="$(head -n1 "$SAVE_FILE" || true)"
  # Already pipe-delimited?
  if [[ "$first" == *"|"* ]]; then return 0; fi
  # Legacy format (shell assignments). Source it safely.
  # shellcheck disable=SC1090
  set +u
  source "$SAVE_FILE" || true
  set -u
  NAME="$(strip_quotes "${NAME:-Hero}")"
  CLASS="$(strip_quotes "${CLASS:-Peasant}")"
  HP="$(num_or_default "${HP:-10}" 10)"
  MAXHP="$(num_or_default "${MAXHP:-10}" 10)"
  GOLD="$(num_or_default "${GOLD:-0}" 0)"
  XP="$(num_or_default "${XP:-0}" 0)"
  LVL="$(num_or_default "${LVL:-1}" 1)"
  STR="$(num_or_default "${STR:-3}" 3)"
  DEX="$(num_or_default "${DEX:-3}" 3)"
  INT="$(num_or_default "${INT:-3}" 3)"
  VIT="$(num_or_default "${VIT:-3}" 3)"
  WIS="$(num_or_default "${WIS:-3}" 3)"
  save_player
}

load_player() {
  migrate_save_if_needed
  [[ -f "$SAVE_FILE" ]] || return 1
  IFS="|" read -r NAME CLASS HP MAXHP GOLD XP LVL STR DEX INT VIT WIS < "$SAVE_FILE" || return 1
  NAME="$(strip_quotes "${NAME:-Hero}")"
  CLASS="$(strip_quotes "${CLASS:-Peasant}")"
  HP="$(num_or_default "${HP:-10}" 10)"
  MAXHP="$(num_or_default "${MAXHP:-10}" 10)"
  GOLD="$(num_or_default "${GOLD:-0}" 0)"
  XP="$(num_or_default "${XP:-0}" 0)"
  LVL="$(num_or_default "${LVL:-1}" 1)"
  STR="$(num_or_default "${STR:-3}" 3)"
  DEX="$(num_or_default "${DEX:-3}" 3)"
  INT="$(num_or_default "${INT:-3}" 3)"
  VIT="$(num_or_default "${VIT:-3}" 3)"
  WIS="$(num_or_default "${WIS:-3}" 3)"
  return 0
}

create_player() {
  echo "New adventurer arises..."
  read -rp "Enter your name: " NAME; NAME="$(strip_quotes "$NAME")"
  echo "Choose your class:"
  echo "1) Warrior   2) Rogue    3) Sorcerer   4) Necromancer   5) Ranger"
  read -rp "> " c
  case "$c" in
    1) CLASS="Warrior";     STR=6; DEX=4; INT=2; VIT=6; WIS=3 ;;
    2) CLASS="Rogue";       STR=4; DEX=6; INT=3; VIT=4; WIS=3 ;;
    3) CLASS="Sorcerer";    STR=2; DEX=3; INT=7; VIT=3; WIS=5 ;;
    4) CLASS="Necromancer"; STR=3; DEX=3; INT=6; VIT=4; WIS=6 ;;
    5) CLASS="Ranger";      STR=5; DEX=5; INT=3; VIT=5; WIS=3 ;;
    *) CLASS="Peasant";     STR=3; DEX=3; INT=3; VIT=3; WIS=3 ;;
  esac
  MAXHP=$((VIT + 6))
  HP=$MAXHP; GOLD=0; XP=0; LVL=1
  save_player
  echo "Character created: $NAME the $CLASS (HP $HP)"
}

level_up() {
  local needed=$((LVL * 10))
  while (( XP >= needed )); do
    ((LVL++))
    ((MAXHP+=2)); HP=$MAXHP
    ((STR+=1)); ((VIT+=1))
    echo "Level Up! You are now Level $LVL."
    needed=$((LVL * 10))
  done
  save_player
}

battle() {
  local enemy="$1"
  local eHP="$2"
  echo "A wild $enemy appears! (HP $eHP)"
  while (( eHP > 0 && HP > 0 )); do
    read -rp "Press [r]oll or [f]lee: " act
    case "$act" in
      r|R)
        local base=$((STR>0?STR:1))
        local dmg=$((RANDOM % (base + 2) + 1))
        local edmg=$((RANDOM % 4 + 1))
        ((eHP-=dmg)); ((eHP<0)) && eHP=0
        echo "You hit $enemy for $dmg!"
        if (( eHP > 0 )); then
          ((HP-=edmg)); ((HP<0)) && HP=0
          echo "$enemy hits you for $edmg!"
        fi
        ;;
      f|F) echo "You flee the fight!"; return ;;
      *) echo "Invalid." ;;
    esac
  done

  if (( HP <= 0 )); then
    echo "You fall in battle... Respawning with half HP."
    HP=$((MAXHP / 2)); ((HP<1)) && HP=1
  else
    echo "$enemy defeated! +5 XP, +3 Gold"
    ((XP+=5)); ((GOLD+=3))
    level_up
  fi
  save_player
}

campaign() {
  echo
  echo "Campaign — Chapter 1"
  echo
  echo "The air is thick as you enter the Forgotten Ruins..."
  read -rp "[1] Enter  [2] Retreat: " ans
  [[ "$ans" == "1" ]] || return
  battle "Slime" 12
}

free_roam() {
  echo "You roam the wild lands..."
  local event=$((RANDOM % 3))
  case "$event" in
    0) echo "You find 5 gold in an old pouch!"; ((GOLD+=5));;
    1) echo "A goblin ambushes you!"; battle "Goblin" 10;;
    2) echo "You rest by a campfire and recover 2 HP."; ((HP+=2)); ((HP>MAXHP)) && HP=$MAXHP;;
  esac
  save_player
  press_any
}

character_sheet() {
  echo "Character:"
  echo "Name:  $NAME"
  echo "Class: $CLASS"
  echo "Level: $LVL"
  echo "HP:    $HP/$MAXHP"
  echo "Gold:  $GOLD"
  echo "XP:    $XP"
  echo "Stats: STR=$STR  DEX=$DEX  INT=$INT  VIT=$VIT  WIS=$WIS"
  press_any
}

menu() {
  while true; do
    clear; banner; echo
    echo "== Legends — Choose Mode =="
    echo "1) Free Roam (open exploration)"
    echo "2) Campaign (story-driven)"
    echo "3) Check Character"
    echo "4) Quit"
    read -rp "Select: " m
    case "$m" in
      1) free_roam ;;
      2) campaign ;;
      3) character_sheet ;;
      4) echo "Game saved. Farewell, $NAME."; save_player; exit 0 ;;
      *) echo "Invalid choice."; sleep 1 ;;
    esac
  done
}

clear; banner
if ! load_player; then create_player; fi
menu
