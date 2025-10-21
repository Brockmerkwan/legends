#!/usr/bin/env bash
set -euo pipefail

HP=20
GOLD=5
XP=0

function roll() { echo $(( (RANDOM % $1) + 1 )); }

function combat() {
  local monster=("Goblin" "Skeleton" "Dark Wolf" "Cultist" "Slime")
  local name=${monster[$RANDOM % ${#monster[@]}]}
  local mHP=$(roll 10)
  local loot=$(roll 5)
  echo "⚔️  A wild $name appears!  (HP $mHP)"
  while (( HP>0 && mHP>0 )); do
    echo -n "Press [r]oll or [f]lee: "
    read -r A
    case $A in
      r|R)
        dmg=$(roll 6)
        mdmg=$(roll 4)
        ((mHP-=dmg))
        ((HP-=mdmg))
        echo "You hit $name for $dmg damage!"
        echo "$name hits you for $mdmg."
        ;;
      f|F)
        echo "You flee to safety!"
        return
        ;;
    esac
  done

  if (( HP<=0 )); then
    echo "💀 You were defeated by $name."
    exit 0
  else
    ((GOLD+=loot))
    ((XP+=5))
    echo "🏆 $name defeated! Loot +$loot gold, +5 XP."
  fi
}

function menu() {
  while true; do
    echo ""
    echo "🌲 You stand at a crossroads."
    echo "1) Venture North to the Forgotten Ruins"
    echo "2) Head East to the Village of Mistvale"
    echo "3) Rest (+2 HP, -1 Gold)"
    echo "4) Check Stats"
    echo "5) Quit"
    read -p "Choose your path: " CH
    case $CH in
      1) combat ;;
      2) echo "🏘️ The villagers wave at you." ;;
      3) ((HP+=2)); ((GOLD--)); echo "You rest and recover +2 HP." ;;
      4) echo "HP $HP | Gold $GOLD | XP $XP" ;;
      5) echo "Farewell, adventurer!"; exit 0 ;;
    esac
  done
}

menu
