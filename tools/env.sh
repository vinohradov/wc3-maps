# Shared settings for tools/*.sh (Git Bash)
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MPQ="$ROOT/tools/bin/mpqeditor/x64/MPQEditor.exe"
PJASS="$ROOT/tools/bin/pjass.exe"
WC3="/c/Program Files/Warcraft III"
ORIGINAL="$ROOT/maps/original/Legion TD Mega v3.5 x10.w3x"
# Output name — this is also the file name other players download in the lobby
OUT_NAME="Legion TD Mega v3.5 x10 mod.w3x"
OUT="$ROOT/maps/build/$OUT_NAME"
# Named text files we edit (paths inside the archive)
FILES=(
  war3map.j war3map.wts war3mapExtra.txt
  'Units\AbilityBuffData.slk' 'Units\AbilityData.slk' 'Units\CampaignAbilityStrings.txt'
  'Units\CampaignUnitFunc.txt' 'Units\ItemData.slk' 'Units\ItemFunc.txt'
  'Units\NeutralUpgradeStrings.txt' 'Units\UnitAbilities.slk' 'Units\UnitBalance.slk'
  'Units\UnitData.slk' 'Units\UnitWeapons.slk' 'Units\UpgradeData.slk' 'Units\unitUI.slk'
)
w() { cygpath -w "$1"; }
unix_path() { printf '%s' "$1" | tr '\\' '/'; }
