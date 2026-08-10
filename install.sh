#!/usr/bin/env bash
#
# Installe le kit TDD dans ~/.claude/ (agents + slash commands).
#
#   ./install.sh              symlinks (recommandé — `git pull` met tout à jour)
#   ./install.sh --copy       copies indépendantes
#   ./install.sh --uninstall  retire ce que le kit a posé
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
MODE="symlink"
STAMP="$(date +%Y%m%d-%H%M%S)"

case "${1:-}" in
  --copy)      MODE="copy" ;;
  --uninstall) MODE="uninstall" ;;
  "")          ;;
  *)           echo "Usage: $0 [--copy|--uninstall]" >&2; exit 2 ;;
esac

install_one() {
  local src="$1" dest_dir="$2"
  local dest="$dest_dir/$(basename "$src")"

  mkdir -p "$dest_dir"

  if [ "$MODE" = "uninstall" ]; then
    # On ne retire que ce qui pointe vers ce repo, ou une copie identique.
    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
      rm "$dest"; echo "  retiré   $dest"
    elif [ -f "$dest" ] && cmp -s "$src" "$dest"; then
      rm "$dest"; echo "  retiré   $dest"
    elif [ -e "$dest" ]; then
      echo "  gardé    $dest (modifié localement — à supprimer à la main)"
    fi
    return
  fi

  # Déjà à jour : rien à faire.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ] && [ "$MODE" = "symlink" ]; then
    echo "  ok       $dest"
    return
  fi

  # Un fichier réel préexistant n'est jamais écrasé sans sauvegarde.
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    if cmp -s "$src" "$dest"; then
      rm "$dest"
    else
      mv "$dest" "$dest.bak-$STAMP"
      echo "  sauvegardé -> $dest.bak-$STAMP"
    fi
  fi

  if [ "$MODE" = "copy" ]; then
    cp "$src" "$dest"; echo "  copié    $dest"
  else
    ln -sfn "$src" "$dest"; echo "  lié      $dest"
  fi
}

echo "Kit TDD — $MODE"
echo "  source : $REPO_DIR"
echo "  cible  : $CLAUDE_DIR"
echo

for f in "$REPO_DIR"/agents/*.md;   do install_one "$f" "$CLAUDE_DIR/agents";   done
for f in "$REPO_DIR"/commands/*.md; do install_one "$f" "$CLAUDE_DIR/commands"; done

echo
if [ "$MODE" = "uninstall" ]; then
  echo "Désinstallé. Relance Claude Code pour que la liste soit à jour."
else
  echo "Installé. Relance Claude Code, puis : /tdd-init dans un projet."
  [ "$MODE" = "symlink" ] && echo "Mise à jour : git -C \"$REPO_DIR\" pull (les symlinks suivent)."
fi
