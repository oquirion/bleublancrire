#!/usr/bin/env bash
# Contexte officiel de la saison après un match : classement, fiche, séquence, meneurs, prochain match.
# Usage : scripts/contexte-saison.sh <date_du_match AAAA-MM-JJ>
# Affiche des faits vérifiables + les blocs YAML « context: » et les infos pour « prediction: ».
set -euo pipefail
GD="${1:?Usage : scripts/contexte-saison.sh <date_du_match AAAA-MM-JJ>}"
echo "$GD" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || { echo "ERREUR : date invalide : $GD"; exit 1; }
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
C="$REPO_DIR/.cache"; mkdir -p "$C"
TEAM="${BBR_TEAM:-MTL}"
NEXT=$(python3 -c "import datetime,sys; print(datetime.date.fromisoformat('$GD')+datetime.timedelta(days=1))")
Y=${GD:0:4}; M=${GD:5:2}
if [ "$((10#$M))" -ge 7 ]; then SEASON="${Y}$((Y+1))"; else SEASON="$((Y-1))${Y}"; fi
if [ "${BBR_NO_FETCH:-0}" != "1" ]; then
  curl -fsS "https://api-web.nhle.com/v1/standings/$NEXT" -o "$C/standings-$NEXT.json" || echo "AVERTISSEMENT : classement injoignable"
  curl -fsS "https://api-web.nhle.com/v1/club-schedule-season/$TEAM/$SEASON" -o "$C/schedule.json" || echo "AVERTISSEMENT : calendrier injoignable"
  curl -fsS "https://api-web.nhle.com/v1/club-stats/$TEAM/$SEASON/2" -o "$C/club-stats-$SEASON.json" || echo "AVERTISSEMENT : statistiques du club injoignables"
fi
python3 - "$C" "$GD" "$NEXT" "$SEASON" "$TEAM" <<'PY'
import json, os, sys
C, GD, NEXT, SEASON, TEAM = sys.argv[1:]
def load(p):
    try: return json.load(open(os.path.join(C, p)))
    except Exception: return None
def n(x): return x.get("default", "") if isinstance(x, dict) else (x or "")
out = []
st = load(f"standings-{NEXT}.json")
me = None
if st:
    rows = st.get("standings", [])
    me = next((r for r in rows if n(r.get("teamAbbrev")) == TEAM), None)
if me and me.get("gamesPlayed"):
    rec = f'{me.get("wins")}-{me.get("losses")}-{me.get("otLosses")}'
    sc, sn = me.get("streakCode"), me.get("streakCount")
    word_fr = {"W": ("victoire", "victoires"), "L": ("défaite", "défaites"), "OT": ("défaite en prolongation", "défaites en prolongation")}.get(sc, ("", ""))
    word_en = {"W": ("win", "wins"), "L": ("loss", "losses"), "OT": ("overtime loss", "overtime losses")}.get(sc, ("", ""))
    sfr = f'{sn} {word_fr[0] if sn == 1 else word_fr[1]}'.strip()
    sen = f'{sn} {word_en[0] if sn == 1 else word_en[1]}'.strip()
    out.append(f"CLASSEMENT (au {NEXT}, saison régulière)")
    out.append(f'  Fiche {rec} · {me.get("points")} pts en {me.get("gamesPlayed")} matchs · buts pour {me.get("goalFor")} / contre {me.get("goalAgainst")}')
    out.append(f'  {me.get("divisionSequence")}e dans la division {n(me.get("divisionName")) or me.get("divisionName")} · {me.get("conferenceSequence")}e dans l\'Association · {me.get("leagueSequence")}e dans la LNH')
    out.append(f'  Séquence : {sfr} · 10 derniers : {me.get("l10Wins")}-{me.get("l10Losses")}-{me.get("l10OtLosses")}')
    out.append(f'  Domicile {me.get("homeWins")}-{me.get("homeLosses")}-{me.get("homeOtLosses")} · Étranger {me.get("roadWins")}-{me.get("roadLosses")}-{me.get("roadOtLosses")}')
    div = sorted([r for r in rows if r.get("divisionName") == me.get("divisionName")], key=lambda r: r.get("divisionSequence", 99))
    out.append("  Division : " + " · ".join(f'{r.get("divisionSequence")}. {n(r.get("teamAbbrev"))} {r.get("points")} pts ({r.get("gamesPlayed")} PJ)' for r in div))
    out.append("\nBLOC YAML POUR L'EN-TÊTE (à copier tel quel) :")
    out.append("context:")
    out.append(f'  record: "{rec}"')
    out.append(f'  points: {me.get("points")}')
    out.append(f'  division_rank: {me.get("divisionSequence")}')
    out.append(f'  streak_fr: "{sfr}"')
    out.append(f'  streak_en: "{sen}"')
else:
    out.append("CLASSEMENT : aucun match de saison régulière joué (ou classement indisponible). Pas de bloc context: pour cette chronique.")
cs = load(f"club-stats-{SEASON}.json")
if cs and cs.get("skaters"):
    sk = sorted(cs["skaters"], key=lambda p: (-(p.get("points") or 0), -(p.get("goals") or 0)))[:6]
    out.append("\nMENEURS DU CANADIEN (saison, à jour au moment de l'exécution)")
    for p in sk:
        out.append(f'  {n(p.get("firstName"))} {n(p.get("lastName"))} : {p.get("goals")} B, {p.get("assists")} A, {p.get("points")} pts en {p.get("gamesPlayed")} PJ')
    for g in cs.get("goalies", []) or []:
        sv = g.get("savePercentage"); gaa = g.get("goalsAgainstAverage")
        out.append(f'  Gardien {n(g.get("firstName"))} {n(g.get("lastName"))} : {g.get("gamesPlayed")} PJ, {g.get("wins")}-{g.get("losses")}-{g.get("overtimeLosses")}, % arrêts {sv if sv is None else round(sv,3)}, moyenne {gaa if gaa is None else round(gaa,2)}')
    out.append("  (Attention : ces totaux peuvent inclure des matchs joués après celui de la chronique si on rattrape un vieux match.)")
sch = load("schedule.json")
if sch:
    nxt = [g for g in sch.get("games", []) if g.get("gameDate", "") > GD and g.get("gameType") in (1, 2, 3)]
    nxt.sort(key=lambda g: g.get("gameDate"))
    if nxt:
        g = nxt[0]; a, h = g.get("awayTeam", {}), g.get("homeTeam", {})
        out.append("\nPROCHAIN MATCH (pour le bloc prediction:)")
        out.append(f'  game_id: {g.get("id")}  date: {g.get("gameDate")}  {a.get("abbrev")} @ {h.get("abbrev")}  lieu: {n(g.get("venue"))}  type: {g.get("gameType")}')
print("\n".join(out))
PY
