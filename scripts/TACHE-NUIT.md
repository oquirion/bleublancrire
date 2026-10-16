# Tâche de nuit : publier la chronique du lendemain de match

## Mise en place (une seule fois)
1. Dans l'app Claude pour Mac : onglet **Code** → **Routines** → **New routine** → **Local**.
2. **Dossier** : `~/Projects/bleu-blanc-rire`
3. **Horaire** : tous les jours à **3 h 45** (heure de Montréal). Facultatif : une 2e exécution vers 9 h 45 comme filet de sécurité. La tâche ne publie jamais deux fois le même match.
4. **Permissions** : le fichier `.claude/settings.json` du dossier autorise d'avance seulement ce dont la tâche a besoin : les scripts `matchs-a-couvrir.sh`, `donnees-match.sh` et `publier.sh post`, l'écriture dans `_posts/`, et quelques commandes de lecture. Laissez le mode de permission sur **Manual** (ou **Accept edits**) et **Worktree décoché**. Évitez « Bypass permissions ».
5. **Instructions** : collez le texte de la section « Instructions à coller » ci-dessous.
6. Cliquez **Run now** une fois pour tester : sans nouveau match, elle doit répondre « Pas de nouveau match » sans rien modifier.

## Pour que ça tourne la nuit
- Le Mac doit être allumé et l'app Claude ouverte.
- Laissez-le branché, et évitez la suspension complète : Réglages Système → Batterie → Options → « Empêcher la suspension automatique sur adaptateur secteur ».
- Ou programmez un réveil quelques minutes avant, dans le Terminal : `sudo pmset repeat wakeorpoweron MTWRFSU 03:40:00`
- Si le Mac dormait, il suffit de lancer la tâche au réveil (Run now) : elle rattrape les matchs manquants.

## Instructions à coller

```
Tu es la tâche de nuit du site Bleu Blanc Rire (chronique humoristique bilingue sur le Canadien de Montréal, signée par le personnage fictif Gaston « Grumpy » Ronchon). Tu travailles dans ~/Projects/bleu-blanc-rire.

1. Lis au complet scripts/GUIDE-REDACTION.md et suis-le à la lettre. Lis aussi les chroniques qu'il désigne comme modèles et les deux plus récentes dans _posts/.

2. Trouve les matchs à couvrir : lance scripts/matchs-a-couvrir.sh. Le script affiche une ligne par match terminé depuis 7 jours sans chronique (id, date, type, visiteur, score, receveur, score, lieu), ou « AUCUN ».

3. S'il n'y a aucun match à couvrir, arrête-toi : ne modifie aucun fichier et réponds « Pas de nouveau match ».

4. Pour chaque match à couvrir, du plus ancien au plus récent (maximum 3) :
   a. Lance scripts/donnees-match.sh <id> et lis le résumé (et les JSON bruts dans .cache/<id>/ au besoin). Si le match n'est pas indiqué comme terminé ou si les données sont incomplètes, saute-le : il sera repris à la prochaine exécution.
   b. Écris la chronique dans _posts/ selon le guide.
   c. Vérifie-la : relis chaque fait réel (score par période, buts, temps, passes, gardiens, statistiques, jour de la semaine, lieu) contre les données, dans les deux langues. Si un sous-agent est disponible, confie-lui cette vérification de façon indépendante. Corrige toute erreur ; si un fait ne peut pas être confirmé, retire-le.
   d. Publie : scripts/publier.sh post _posts/<fichier>.md (le script vérifie aussi le nom, l'en-tête YAML et les deux langues ; s'il refuse, corrige le fichier et relance).

5. Ne modifie aucun autre fichier du dossier (design, gabarits, script, guide, anciennes chroniques). Pour le shell, utilise seulement les trois scripts du dossier scripts/ et des commandes de lecture (ls, grep, cat, head, wc, date) : pas de curl, de python ni de cd vers d'autres dossiers. Ces commandes sont déjà autorisées ; toute autre commande bloquerait la tâche en attente d'approbation.

6. Termine par un court résumé : matchs couverts, fichiers créés, résultat de la publication (ou l'erreur exacte si elle a échoué : dans ce cas, laisse le fichier en place pour qu'on le publie à la main).
```
