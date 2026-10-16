#!/usr/bin/env bash
# =============================================================================
#  publier.sh : publie le site Bleu Blanc Rire sur GitHub (GitHub Pages)
# -----------------------------------------------------------------------------
#  Ce script vit dans  <dossier du site>/scripts/publier.sh  et travaille sur
#  le dossier parent (ex. ~/Projects/bleu-blanc-rire), qui est le dépôt git.
#  Il utilise VOTRE accès GitHub déjà configuré sur ce Mac (gh ou trousseau).
#  Il ne stocke aucun mot de passe ni jeton.
#
#  Commandes (à lancer depuis n'importe où) :
#    scripts/publier.sh pousser
#        Publie tout ce qui a changé dans le dossier (1re mise en ligne,
#        retouches au design, etc.).
#
#    scripts/publier.sh post chemin/AAAA-MM-JJ-slug.md
#        Vérifie une chronique, la place dans _posts/ (si elle n'y est pas
#        déjà) et la publie.
#
#    scripts/publier.sh statut
#        État du dépôt local et 5 derniers commits.
#
#  Option : --essai  montre ce qui serait publié, sans rien envoyer.
#
#  Réglages facultatifs (variables d'environnement) :
#    BBR_REMOTE  (défaut : https://github.com/oquirion/bleublancrire.git)
#    BBR_BRANCH  (défaut : main)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="${BBR_REPO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
REMOTE="${BBR_REMOTE:-https://github.com/oquirion/bleublancrire.git}"
BRANCH="${BBR_BRANCH:-main}"
LOG_DIR="${BBR_LOG_DIR:-$REPO_DIR/.logs}"
DRY_RUN=0

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/publier.log"

log()  { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"; }
fail() { log "ERREUR : $*"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || fail "« $1 » est introuvable. Installez-le puis réessayez."; }

ensure_repo() {
  need git
  cd "$REPO_DIR"
  [ -f _config.yml ] || fail "Pas de _config.yml dans $REPO_DIR : ce n'est pas le dossier du site."
  if [ ! -d .git ]; then
    log "Création du dépôt git local dans $REPO_DIR"
    git init -q
    git checkout -q -b "$BRANCH" 2>/dev/null || git symbolic-ref HEAD "refs/heads/$BRANCH"
  fi
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "$REMOTE"
  fi
  if ! git config user.name >/dev/null 2>&1; then
    fail "Git ne connaît pas votre nom. Lancez : git config --global user.name \"Votre nom\" et git config --global user.email \"vous@exemple.com\""
  fi
}

sync_with_remote() {
  # Récupère ce qui a pu changer sur GitHub avant de publier.
  if ! git fetch -q origin 2>>"$LOG_FILE"; then
    fail "Impossible de joindre GitHub. Vérifiez votre accès (voir la fin du script)."
  fi
  if git rev-parse --verify -q "origin/$BRANCH" >/dev/null; then
    if git rev-parse --verify -q HEAD >/dev/null; then
      git stash -q --include-untracked || true
      git pull -q --rebase origin "$BRANCH" || fail "Conflit avec GitHub. Ouvrez $REPO_DIR pour régler la situation."
      git stash pop -q 2>/dev/null || true
    else
      # Premier envoi alors que GitHub contient déjà des fichiers (ex. README) :
      # on se place sur l'historique de GitHub sans toucher aux fichiers locaux.
      git reset -q "origin/$BRANCH"
    fi
  fi
}

commit_and_push() {
  local msg="$1"
  git add -A
  if git diff --cached --quiet && [ "$(git rev-list --count "origin/$BRANCH..HEAD" 2>/dev/null || echo 1)" = "0" ]; then
    log "Rien de nouveau à publier."
    return 0
  fi
  if ! git diff --cached --quiet; then
    log "Fichiers modifiés :"
    git diff --cached --name-status | tee -a "$LOG_FILE"
    if [ "$DRY_RUN" -eq 1 ]; then
      git reset -q
      log "[essai] Rien n'a été envoyé."
      return 0
    fi
    git commit -q -m "$msg"
  fi
  [ "$DRY_RUN" -eq 1 ] && { log "[essai] git push origin $BRANCH"; return 0; }
  local err
  if ! err="$(git push -q -u origin "$BRANCH" 2>&1)"; then
    echo "$err" >> "$LOG_FILE"
    if echo "$err" | grep -qiE "403|denied|authentication|could not read Username"; then
      fail "GitHub refuse l'accès : $(echo "$err" | grep -iE 'denied|403|authentication' | head -n 1). Voir « Accès GitHub » à la fin du script."
    fi
    if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
      log "Push refusé ; nouvelle synchronisation puis 2e essai."
      git pull -q --rebase origin "$BRANCH" || fail "Synchronisation impossible."
      git push -q -u origin "$BRANCH" 2>>"$LOG_FILE" || fail "Push refusé. Détails dans $LOG_FILE"
    else
      fail "Push refusé : $(echo "$err" | tail -n 1)"
    fi
  fi
  log "Publié sur GitHub : $(git rev-parse --short HEAD) · $msg"
}

check_post() {
  local f="$1" name fm key
  name="$(basename "$f")"
  [ -f "$f" ] || fail "Fichier introuvable : $f"
  echo "$name" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9-]+\.md$' \
    || fail "Nom invalide : $name (attendu : AAAA-MM-JJ-mots-en-minuscules.md)"
  head -n 1 "$f" | grep -q '^---$' || fail "$name : l'en-tête doit commencer par ---"
  fm="$(awk 'NR==1 && /^---$/ {inside=1; next} inside && /^---$/ {exit} inside {print}' "$f")"
  for key in 'layout: post' 'title:' 'title_en:' 'game:' 'away:' 'away_score:' 'home:' 'home_score:' 'useless_stats:'; do
    echo "$fm" | grep -q "^[[:space:]]*$key" || fail "$name : champ manquant dans l'en-tête : « $key »"
  done
  grep -q 'lang="fr"' "$f" || fail "$name : bloc français manquant (<div class=\"body\" lang=\"fr\" markdown=\"1\">)"
  grep -q 'lang="en"' "$f" || fail "$name : bloc anglais manquant (<div class=\"body\" lang=\"en\" markdown=\"1\">)"
  # Vérifie que l'en-tête est du YAML valide (python3 + PyYAML, sinon ruby)
  if printf '%s\n' "$fm" | python3 -c 'import sys,yaml; yaml.safe_load(sys.stdin)' 2>/dev/null; then :
  elif python3 -c 'import yaml' 2>/dev/null; then fail "$name : l'en-tête n'est pas du YAML valide (guillemets ou indentation ?)"
  elif command -v ruby >/dev/null 2>&1; then
    printf '%s\n' "$fm" | ruby -ryaml -e 'YAML.safe_load(STDIN.read, permitted_classes: [Date, Time]) rescue (warn $!; exit 1)' 2>>"$LOG_FILE" \
      || fail "$name : l'en-tête n'est pas du YAML valide (guillemets ou indentation ?)"
  else log "Avertissement : impossible de vérifier le YAML (ni PyYAML ni ruby)."
  fi
  log "Chronique valide : $name"
}

cmd_pousser() {
  ensure_repo
  sync_with_remote
  local first=0
  git rev-parse --verify -q HEAD >/dev/null || first=1
  if [ "$first" -eq 1 ]; then commit_and_push "Mise en ligne du site Bleu Blanc Rire"
  else commit_and_push "Mise à jour du site"; fi
  if [ "$first" -eq 1 ] && [ "$DRY_RUN" -eq 0 ]; then
    log "Dernière étape (une seule fois) : sur GitHub, Settings → Pages → « Deploy from a branch », branche « $BRANCH », dossier « / (root) »."
  fi
}

cmd_post() {
  local f="${1:-}" name abs dest
  [ -n "$f" ] || fail "Usage : scripts/publier.sh post chemin/AAAA-MM-JJ-slug.md"
  abs="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  check_post "$abs"
  ensure_repo
  sync_with_remote
  name="$(basename "$abs")"
  dest="$REPO_DIR/_posts/$name"
  mkdir -p "$REPO_DIR/_posts"
  if [ "$abs" != "$dest" ]; then
    [ -f "$dest" ] && log "Mise à jour d'une chronique existante : $name"
    cp "$abs" "$dest"
  fi
  commit_and_push "Chronique : ${name%.md}"
}

cmd_statut() {
  ensure_repo
  git fetch -q origin 2>/dev/null || echo "(GitHub injoignable pour le moment)"
  echo "Dossier du site : $REPO_DIR"
  git status -sb
  echo "Derniers commits :"
  git log --oneline -n 5 2>/dev/null || echo "(aucun commit)"
  echo "Chroniques : $(ls "$REPO_DIR/_posts" 2>/dev/null | grep -c '\.md$' || true)"
}

cmd="${1:-}"; shift || true
args=()
for a in "$@"; do
  if [ "$a" = "--essai" ]; then DRY_RUN=1; else args+=("$a"); fi
done
set -- "${args[@]+"${args[@]}"}"

case "$cmd" in
  pousser|init) cmd_pousser ;;
  post)         cmd_post "$@" ;;
  statut)       cmd_statut ;;
  *) sed -n '2,27p' "$0"; exit 1 ;;
esac

# ----------------------------------------------------------------------------
#  Accès GitHub, à faire une seule fois sur le Mac.
#  Si votre Mac est déjà connecté à un AUTRE compte GitHub (ex. compte de
#  travail), forcez ce dépôt à utiliser votre compte personnel :
#    git remote set-url origin https://oquirion@github.com/oquirion/bleublancrire.git
#  Au prochain push, entrez comme mot de passe un jeton « fine-grained » du
#  compte oquirion (Repository access : bleublancrire seulement ; Contents :
#  Read and write). Le trousseau macOS le garde pour ce compte seulement.
#  Sinon (au choix) :
#    • GitHub CLI :  brew install gh  →  gh auth login  →  gh auth setup-git
#    • ou git + trousseau : au premier push, entrez votre nom d'utilisateur
#      GitHub et un jeton « fine-grained » limité au dépôt bleublancrire
#      (Contents : Read and write). macOS le garde dans le trousseau.
# ----------------------------------------------------------------------------
