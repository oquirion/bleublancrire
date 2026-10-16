# Guide de rédaction : chroniques de Gaston Ronchon

Ce guide est lu par la tâche de nuit avant chaque chronique. Modifiez-le pour changer le ton, la longueur ou les règles : la tâche suivra la nouvelle version.

## 1. Modèles à imiter
Lisez au complet, avant d'écrire :
- `_posts/2026-10-07-canadiens-hurricanes.md` (chronique de référence, approuvée)
- `_posts/2026-10-15-canadiens-capitals.md`
- les **deux chroniques les plus récentes** dans `_posts/` (pour la continuité des gags et des références)

## 2. Format du fichier (obligatoire)
- Nom : `_posts/AAAA-MM-JJ-canadiens-<adversaire>.md`, où la date est **le lendemain du match** (heure de Montréal). Adversaire = surnom anglais en minuscules avec tirets : maple-leafs, senators, bruins, red-wings, sabres, lightning, panthers, rangers, islanders, devils, flyers, penguins, capitals, hurricanes, blue-jackets, blackhawks, predators, blues, jets, wild, avalanche, stars, utah… Si ce nom existe déjà dans `_posts/` pour un autre match, ajoutez un suffixe (`-2`).
- En-tête (front matter), dans cet ordre :
  - `layout: post`
  - `title:` titre français · `title_en:` titre anglais
  - `date: AAAA-MM-JJ 04:00:00 -0400` (ou `-0500` en hiver ; 04:05 si deux matchs le même jour)
  - `game:` avec `away`, `away_score`, `home`, `home_score`, `venue`, `date_label_fr`, `date_label_en`, et **seulement si prolongation ou tirs de barrage** `result_suffix: "Prol. / OT"` ou `"T.B. / SO"`
  - `date_label_fr` / `date_label_en` : « Mardi 6 octobre 2026 » / « Tuesday, October 6, 2026 ». Match préparatoire : préfixe « Match préparatoire · » / « Preseason · ». Séries : « Séries · » / « Playoffs · ».
  - `quote:` `fr` et `en` : une phrase tirée de la chronique (elle devient la « phrase du jour »)
  - `useless_stats:` exactement 5 éléments `num`, `fr`, `en`
  - `sources:` 2 éléments : le sommaire LNH `https://www.nhl.com/gamecenter/<away>-vs-<home>/AAAA/MM/JJ/<id>` (abréviations en minuscules, date du match) et `https://api-web.nhle.com/v1/gamecenter/<id>/boxscore`. **L'identifiant du match doit apparaître dans les sources** : c'est ce qui permet de savoir qu'un match a déjà sa chronique.
- Corps : `<div class="body" lang="fr" markdown="1">` (chronique en français) puis `<div class="body" lang="en" markdown="1">` (en anglais). Chaque bloc se termine par la signature `*— Gaston Ronchon*` / `*— Gaston "Grumpy" Ronchon*`. Intertitres en `###` seulement. Pas de titre dans le corps.
- Longueur par langue : saison et séries ~650–800 mots ; préparatoire ~350–450 mots.
- Le français est naturel et québécois, pas une traduction littérale. L'anglais aussi est naturel. Mêmes faits dans les deux langues.

## 3. Les faits : zéro invention
- Sources : lancez `scripts/donnees-match.sh <id>`. Le script télécharge les données officielles de la LNH (landing + boxscore) dans `.cache/<id>/` et affiche un résumé (buts, passes, temps, force, tirs de barrage, étoiles, punitions, joueurs, gardiens). Le résumé est aussi dans `.cache/<id>/resume.txt` ; en cas de doute, lisez les fichiers JSON bruts `.cache/<id>/landing.json` et `boxscore.json`. N'utilisez pas d'autres sources pour les faits.
- Chaque nom, chiffre, temps, passe, gardien ou statistique réelle doit venir de ces données. Pas de records, séquences, blessures, trios, décisions d'entraîneur ou citations qui n'y sont pas.
- Si la donnée ne donne qu'une initiale, utilisez le nom de famille seul.
- Tirs de barrage : le score final compte le but gagnant comme +1. Décrivez-le correctement (égalité après la prolongation, décidé en tirs de barrage).
- **Aucune citation inventée** d'une vraie personne. Les blagues sur le jeu sont permises ; restez affectueux, jamais méchant, jamais sur la vie privée ou l'apparence.

## 4. Stats inutiles (la signature du site)
- Exactement 5, clairement absurdes, sur Gaston, la foule, la galerie de presse, son calepin, son chat, le stationnement, les hot-dogs, ses petits-enfants…
- **Jamais** un fait inventé attribué à une vraie personne nommée. Un vrai chiffre peut apparaître seulement s'il est marqué comme vrai (« (vrai) » / « (real) »).

## 5. La voix de Gaston
- Vétéran grincheux qui prétend couvrir le Canadien depuis l'époque du Forum ; dramatique, autodérision, cœur tendre.
- Gags récurrents (à varier, jamais tous à la fois) : il promet de partir après la première période ; le stationnement ; son calepin où il écrit puis rature des mots ; son chat ; ses petits-enfants qui ne l'écoutent jamais ; les croissants et la boulangerie ; son patron qui refuse de payer les voyages.
- Chaque chronique a **une image centrale nouvelle** (une berçante, une rénovation, une partie de pêche…). Ne recopiez pas de phrases des chroniques précédentes.
- Une victoire le rend méfiant ; une défaite le rend théâtral.
- Continuité : si la chronique précédente annonçait quelque chose (« je partirai après la première, probablement »), faites-y écho.
