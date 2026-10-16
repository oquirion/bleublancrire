#!/usr/bin/env bash
# Télécharge les données officielles d'un match (landing + boxscore) et en fait un résumé lisible.
# Usage : scripts/donnees-match.sh <id_du_match>
# Fichiers : .cache/<id>/landing.json, boxscore.json, resume.txt
set -euo pipefail
ID="${1:?Usage : scripts/donnees-match.sh <id_du_match>}"
echo "$ID" | grep -Eq '^[0-9]{10}$' || { echo "ERREUR : identifiant invalide : $ID"; exit 1; }
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIR="$REPO_DIR/.cache/$ID"; mkdir -p "$DIR"
B="https://api-web.nhle.com/v1/gamecenter/$ID"
if [ "${BBR_NO_FETCH:-0}" != "1" ]; then
  curl -fsS "$B/landing" -o "$DIR/landing.json" || { echo "ERREUR : landing injoignable"; exit 1; }
  if ! grep -q '"gameState":"\(OFF\|FINAL\)"' "$DIR/landing.json"; then
    curl -fsS "$B/landing?lang=en" -o "$DIR/landing.json" || true
  fi
  curl -fsS "$B/boxscore" -o "$DIR/boxscore.json" || { echo "ERREUR : boxscore injoignable"; exit 1; }
fi
python3 - "$DIR" <<'PY'
import json, sys, os
D = sys.argv[1]
L = json.load(open(os.path.join(D, "landing.json")))
B = json.load(open(os.path.join(D, "boxscore.json")))
def n(x):
    if isinstance(x, dict): return x.get("default", "")
    return x or ""
def full(p):
    fn, ln = n(p.get("firstName")), n(p.get("lastName"))
    return (fn + " " + ln).strip() or n(p.get("name"))
o = []
a, h = L.get("awayTeam", {}), L.get("homeTeam", {})
o.append(f'MATCH {L.get("id")}  {L.get("gameDate")}  type {L.get("gameType")}  état {L.get("gameState")}')
o.append(f'{n(a.get("placeName"))} {n(a.get("commonName"))} ({a.get("abbrev")}) {a.get("score")}  @  {n(h.get("placeName"))} {n(h.get("commonName"))} ({h.get("abbrev")}) {h.get("score")}')
o.append(f'Lieu : {n(L.get("venue"))}   Dernière période : {(L.get("gameOutcome") or {}).get("lastPeriodType")}')
o.append(f'Tirs au but : {a.get("abbrev")} {a.get("sog")} · {h.get("abbrev")} {h.get("sog")}')
if L.get("gameState") not in ("OFF", "FINAL"):
    o.append("ATTENTION : le match n'est pas indiqué comme terminé. Ne pas écrire de chronique.")
S = L.get("summary", {}) or {}
o.append("\nBUTS")
for per in S.get("scoring", []) or []:
    pd = per.get("periodDescriptor", {}) or {}
    for g in per.get("goals", []) or []:
        ast = ", ".join(full(x) for x in g.get("assists", []) or []) or "sans aide"
        mod = g.get("goalModifier") or ""
        o.append(f'  P{pd.get("number")} {pd.get("periodType","")} {g.get("timeInPeriod")}  {n(g.get("teamAbbrev"))}  {full(g)}  (passes : {ast})  force={g.get("strength")} situation={g.get("situationCode")} tir={g.get("shotType")} {mod}  → {g.get("awayScore")}-{g.get("homeScore")}')
so = S.get("shootout") or []
if so:
    o.append("\nTIRS DE BARRAGE")
    for s in so:
        o.append(f'  #{s.get("sequence")} {n(s.get("teamAbbrev"))} {full(s)} : {s.get("result")}{" (but gagnant)" if s.get("gameWinner") else ""}')
st = S.get("threeStars") or []
if st:
    o.append("\nTROIS ÉTOILES")
    for s in st:
        o.append(f'  {s.get("star")}. {n(s.get("name"))} ({n(s.get("teamAbbrev"))}) {s.get("goals","")}B {s.get("assists","")}A')
pens = S.get("penalties") or []
if pens:
    o.append("\nPUNITIONS")
    for per in pens:
        pd = per.get("periodDescriptor", {}) or {}
        for p in per.get("penalties", []) or []:
            who = n(p.get("committedByPlayer")) if not isinstance(p.get("committedByPlayer"), dict) else full(p.get("committedByPlayer"))
            o.append(f'  P{pd.get("number")} {p.get("timeInPeriod")} {n(p.get("teamAbbrev"))} {who} : {p.get("descKey")} {p.get("duration")} min')
PB = B.get("playerByGameStats", {}) or {}
for side in ("awayTeam", "homeTeam"):
    T = PB.get(side, {}) or {}
    ab = (B.get(side) or {}).get("abbrev", side)
    o.append(f"\nJOUEURS {ab}  (B A +/- PUN tirs MÉ bloqués revirements récup. TG)")
    for grp in ("forwards", "defense"):
        for p in T.get(grp, []) or []:
            o.append(f'  {n(p.get("name")):<22} {p.get("position","")} {p.get("goals",0)} {p.get("assists",0)} {p.get("plusMinus",0)} {p.get("pim",0)} {p.get("sog",0)} {p.get("hits",0)} {p.get("blockedShots",0)} {p.get("giveaways",0)} {p.get("takeaways",0)} {p.get("toi","")}')
    for p in T.get("goalies", []) or []:
        o.append(f'  GARDIEN {n(p.get("name"))} : arrêts/tirs {p.get("saveShotsAgainst")}  TG {p.get("toi")}  décision {p.get("decision","")}')
o.append("\nNote : quand un prénom n'est donné qu'en initiale, utiliser le nom de famille seul.")
txt = "\n".join(str(x) for x in o)
open(os.path.join(D, "resume.txt"), "w", encoding="utf-8").write(txt + "\n")
print(txt)
PY
