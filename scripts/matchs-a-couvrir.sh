#!/usr/bin/env bash
# Liste les matchs du Canadien terminés depuis 7 jours qui n'ont pas encore de chronique.
# Sortie : une ligne par match  « id date type visiteur score receveur score lieu »,
#          ou « AUCUN » s'il n'y a rien à couvrir.
# Utilisé par la tâche de nuit. N'écrit que dans .cache/ (ignoré par git et par le site).
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CACHE="$REPO_DIR/.cache"; mkdir -p "$CACHE"
TEAM="${BBR_TEAM:-MTL}"
Y=$(TZ=America/Montreal date +%Y); M=$(TZ=America/Montreal date +%m)
if [ "$((10#$M))" -ge 7 ]; then SEASON="${Y}$((Y+1))"; else SEASON="$((Y-1))${Y}"; fi
if [ "${BBR_NO_FETCH:-0}" != "1" ]; then
  curl -fsS "https://api-web.nhle.com/v1/club-schedule-season/$TEAM/$SEASON" -o "$CACHE/schedule.json" \
    || { echo "ERREUR : calendrier LNH injoignable"; exit 1; }
fi
TODAY=$(TZ=America/Montreal date +%Y-%m-%d)
python3 - "$CACHE/schedule.json" "$REPO_DIR/_posts" "$TODAY" <<'PY'
import json, sys, os, datetime
sched, posts, today = sys.argv[1], sys.argv[2], sys.argv[3]
d = json.load(open(sched))
covered = ""
for f in os.listdir(posts):
    if f.endswith(".md"):
        covered += open(os.path.join(posts, f), encoding="utf-8").read()
t = datetime.date.fromisoformat(today)
out = []
for g in d.get("games", []):
    gd = g.get("gameDate", "")
    try: day = datetime.date.fromisoformat(gd)
    except ValueError: continue
    if not (t - datetime.timedelta(days=7) <= day <= t): continue
    if g.get("gameType") not in (1, 2, 3): continue
    if g.get("gameState") not in ("OFF", "FINAL"): continue
    gid = str(g.get("id"))
    if gid in covered: continue
    a, h = g.get("awayTeam", {}), g.get("homeTeam", {})
    out.append(f'{gid} {gd} {g.get("gameType")} {a.get("abbrev")} {a.get("score")} {h.get("abbrev")} {h.get("score")} {g.get("venue",{}).get("default","")}')
print("\n".join(sorted(out, key=lambda l: l.split()[1])) if out else "AUCUN")
PY
