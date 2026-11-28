# Tutoriel : l'agent `saiban-orchestrator`

*English version: [tutorial-saiban.md](tutorial-saiban.md).*

`saiban-orchestrator` est un **agent Claude Code** (pas portable sur Gemini CLI) qui
enchaîne les [skills aixlper](../README.md#skills) à ta place, dans le bon ordre, et ne s'arrête
que quand une décision t'appartient vraiment. Il garde une trace écrite de
chaque décision : tu peux suivre le travail de partout, y compris depuis ton
téléphone.

Les noms suivent ceux des skills : un mot d'Ace Attorney, puis le rôle. Les
mots viennent d'un procès : *saiban* (le procès) mène l'affaire, *kenji* (le
procureur) relit chaque CA sans jamais corriger, *shonin* (le témoin) écrit le
code sans avoir entendu le plan de tests, *mokugeki* (le témoin oculaire)
vérifie un écran sans savoir ce qui a changé, et *tantei* (le détective) enquête
sur l'usage des skills. Ils s'appelaient `iterate`, `iterate-reviewer` et
`iterate-dev` avant ; les scripts d'installation nettoient les anciens noms.

| Nom | But | Pourquoi un agent à part | Lancé par | Peut modifier |
|---|---|---|---|---|
| `saiban-orchestrator` | Orchestrateur : choisit le mode et les skills, mène la boucle, te demande aux points de décision | Il te remplace pour un process connu, donc il tourne en session principale pour pouvoir te poser des questions | Toi (`ci`, ou `/saiban-orchestrator`) | Oui |
| `kenji-reviewer` | Relecteur : vérifie chaque CA par rapport aux skills, rapporte, ne corrige jamais | Un regard neuf et aucun droit d'écriture : il ne peut pas corriger ce qu'il relit | `saiban-orchestrator`, après chaque CA | Non |
| `shonin-dev` | Implémenteur : écrit un GREEN sans voir le plan de tests ni les CA | Il ne doit pas savoir quels tests arrivent, pour que son code ne soit pas biaisé par eux | `saiban-orchestrator`, les GREEN d'une grosse exécution TDD, un dev par exécution (fix, build) | Oui |
| `mokugeki-tester` | Testeur UI : écrit et lance le check Playwright de chaque CA, rapporte ce qu'il a vu | Il ne doit pas connaître le changement (diff, source de l'app, conception), pour que son check suive la CA et non le code | `saiban-orchestrator`, mode UI, un testeur par écran | Fichiers de check seulement |
| `tantei-inspector` | Inspecteur : lit l'usage des skills, propose des changements | Lecture seule, et ne doit pas connaître les raisons de la session de travail ; sa longue lecture reste hors de la session principale | `saiban-orchestrator`, modes improve et contribute | Non |

Les quatre agents d'aide tournent sur Sonnet quel que soit le modèle de la
session principale (`model: sonnet` dans leur frontmatter) : leur travail
consiste à suivre des règles écrites, où Sonnet a été mesuré au niveau
d'Opus. L'orchestrateur utilise le modèle de ta session ; choisis Opus avec
`/model` quand la planification le demande.

### 1. Installer

```bash
./scripts/install-global.sh   # copie global/agents/*.md dans ~/.claude/agents/
./scripts/install.sh          # les skills eux-mêmes
```

`install-global.sh` ajoute aussi l'alias `ci` à `~/.bashrc`, dans un bloc
marqué `# >>> aixlper >>>`. Le relancer remplace ce bloc, ne le duplique
jamais et ne touche à rien d'autre (`--no-shell` pour l'éviter). Ouvre un
nouveau terminal ensuite.

Pour n'installer que les agents : `cp global/agents/*.md ~/.claude/agents/`
(puis ajoute l'alias à la main). Rien ne change dans tes projets tant que tu
ne demandes pas l'agent.

### 2. Le lancer

Depuis le dossier de ton projet :

| Tu veux | Tu tapes |
|---|---|
| Le mode agent (`saiban-orchestrator`) | `ci` |
| L'assistant normal | `claude` |

`ci` vaut `claude --agent saiban-orchestrator --permission-mode acceptEdits` : il modifie
les fichiers sans demander à chaque fois ; les commandes et les push
demandent toujours. Il ajoute aussi
`--append-system-prompt-file ~/.claude/skills/saiban-orchestrator/SKILL.md`
quand ce fichier existe, pour que le skill soit dans le contexte dès le
départ : le préchargement `skills:` de l'agent est ignoré quand l'agent est
la session principale (vérifié).

Deux réglages de coût, optionnels, lus par `ci` lui-même :

- `AIXLPER_CI_EFFORT=high` (ou un autre niveau) ajoute `--effort` à chaque
  session `ci`. Sans cette variable, le défaut du client s'applique. Pas une
  économie mesurée : sur deux exécutions d'éval avec Sonnet, `high` a coûté
  plus, pas moins.
- `~/.claude/ci-mcp.json`, s'il existe, limite les sessions `ci` aux serveurs
  MCP qu'il liste (`--strict-mcp-config`). Les outils de chaque serveur sont
  renvoyés à chaque appel : n'y mettez que ceux dont l'orchestrateur se sert
  (un IDE, un gestionnaire de tickets). `claude` tout court les garde tous.

Pour voir où est passé l'argent d'un vrai ticket, lancez
`~/.claude/cycle-cost.py` dans le projet après la session (ou `--all` pour
toute la session).

Ça ne vaut que pour cette session : `claude` tout court reste l'assistant
normal, même si son mode direct couvre aussi les questions et petites modifs. Astuce : `alias
ci='claude --agent saiban-orchestrator --permission-mode acceptEdits'` le laisse
modifier les fichiers sans demander à chaque fois (les commandes et les push
demandent toujours). Le mode doit être sur la ligne de commande :
`permissionMode` dans le fichier de l'agent est ignoré quand l'agent est la
session principale (vérifié). Évite `"agent": "saiban-orchestrator"` dans un fichier de
settings, sauf si tu veux que chaque session y démarre en `saiban-orchestrator`, car il
remplace le prompt système par défaut.

Puis décris le travail dans ton premier message. Deux exemples :

- **Mode fix** (un changement clair sur du code existant) :
  *« Bug : un compte créé en `alice` ne peut pas se connecter en `Alice`.
  Les identifiants doivent être insensibles à la casse. »*
  Il utilise `igiari-tdd` + `kanpeki-fp` (+ `kaizen-refactor`), rien d'autre.
- **Mode build** (quelque chose de nouveau) :
  *« Ticket PROJ-8 : bloquer un compte après trois échecs de connexion.
  CA1 : ... CA2 : ... »* Il passe d'abord par `chottomatte-archi`, puis
  `objection-conception` pour le ticket et ses critères d'acceptation (CA),
  puis le TDD.
- **Mode ui** (un front web, par exemple Nuxeo) : chaque CA reçoit un
  contrôle Playwright (`shoko-playwright`), lancé sur l'application
  redéployée avec Podman. Déjà vert : la CA est remplie. En échec : il
  modifie le code jusqu'à ce qu'il passe, ou, pour un changement que toi
  seul peux faire (Nuxeo Studio Modeler), te dit quoi changer et attend ton
  hot reload. Un écran à la fois, chaque écran fini étant un point de sauvegarde. Pas de
  TDD unitaire ici.
  Deux onglets peuvent travailler deux écrans différents en même temps, dans
  le même dossier (pas un worktree : le serveur ne voit que le dossier que son
  volume synchronise). Chaque onglet ne touche et ne commite que les fichiers
  de son écran, et te demande avant de redémarrer le serveur, car cela casse
  les contrôles de l'autre onglet.
- **Mode think** (réflexion et analyse seules) : `objection-conception`
  seul ; `chottomatte-archi` seulement si tu le demandes (ou acceptes quand
  il le propose). Il lit le code dont il a besoin, n'écrit que les fichiers
  de conception, jamais de code.
- **Mode improve** (les skills et agents eux-mêmes) : *« améliore les skills
  à partir de mes derniers runs »*. `tantei-inspector`, en lecture seule et sans
  contexte, lit tes journaux de décisions, retros, notes de process et
  transcripts de session, et propose des changements de formulation exacts,
  preuves à l'appui. Tu acceptes ou refuses chacun ; ceux acceptés sont
  appliqués et commités dans ton clone aixlper, jamais dans le projet. Il faut
  les skills installés avec `./scripts/install.sh --link`, sinon il affiche
  seulement le patch.
  Il peut aussi apprendre des skills d'une autre équipe (*« compare le skill
  de revue de l'équipe avec le mien »*) : seulement ce qui vaut au-delà de
  cette équipe, réécrit, jamais copié.
- **Mode contribute** (donner un skill au dépôt de skills d'une autre
  équipe) : *« contribue tantei-debug aux skills de l'équipe dans
  ~/work/team-skills »*. Il cherche d'abord un skill qui recoupe le tien dans
  la cible, fait trier chaque règle par `tantei-inspector` (pratique partagée
  ou ton opinion), te demande de valider ce tri, puis écrit une version
  neutre (sans thème, conventions du projet d'abord, opinions seulement en
  option) sur une branche de la cible, dans son format. Ne pousse jamais.
- **Skills externes** (tous les modes) : liste les skills d'une équipe dans
  `~/.claude/external-skills.md` (privé, jamais dans ce dépôt), chacun avec
  à quoi il sert, quand il s'applique et son rôle (renforce un skill aixlper,
  comble un manque, ou en remplace un dans un projet donné) ; l'orchestrateur
  le charge à cette étape. Format :
  `skills/saiban-orchestrator/references/external-skills.md`.
- **Mode direct** (tout le reste) : une question, une petite modif, une
  commande. Il le fait, sans cérémonie, donc plus besoin de `claude` tout
  court.

Il propose le mode, tu confirmes. Options à ajouter dans ce premier
message :

| Dire | Effet |
|---|---|
| `pre-approve TDD plans` | Pas d'approbation par plan de CA. |
| `yolo` | L'orchestrateur prend les décisions lui-même (plans, choix, déviations, corrections de revue) avec les mêmes skills et agents, journalise chacune, pousse sur une branche de fonctionnalité (jamais la branche par défaut, jamais en force, pas de pull request) garde le résultat lançable en une commande à chaque push (application mobile comprise, avec une section `Run` dans le README) et vous les liste à la fin. Les autres push, supprimer et toute action difficile à défaire restent demandés, tous ensemble à la fin. Comme tous les modes, il ne s'arrête pas aux points de sauvegarde sauf avec `with pauses`. `yolo off` l'arrête. |
| `with pauses` | Arrêt après chaque CA, écran et changement de mode (par défaut il continue et marque seulement les points de sauvegarde). |
| `no review` | Pas d'`kenji-reviewer` après chaque CA (mode build). |
| `no tester` | En mode UI, l'orchestrateur écrit et lance les checks lui-même au lieu de `mokugeki-tester` (activé par défaut ; environ 1,6× le coût sur un petit écran, bénéfice pas encore démontré). |
| `with review` | En mode fix, une revue `kenji-reviewer` du correctif (désactivée par défaut ; environ 0,30 $). |
| `with dev` / `no dev` | Force `shonin-dev` activé ou désactivé. Sans l'un ni l'autre, l'orchestrateur l'active de lui-même : pour un ticket build à deux CA ou plus, ou un plan de quatre tests ou plus (annoncé dans le plan que vous approuvez), et pour tous les green suivants dès qu'un de ses propres green est pris à coder en avance sur son test (un test prévu qui passe dès son écriture, le compteur `ahead` de l'audit, ou le reviewer). Désactivé sinon. Activé, le code est écrit par un seul agent par exécution, qui ne voit que les tests en échec, pas le plan ; environ 1,9× le coût sur les katas, bénéfice pas encore mesuré. |

### Quel mode ?

Choisis-le avant d'écrire le premier message, en te posant ces questions
dans l'ordre ; le premier « oui » donne le mode. Nomme-le en tête du message
(« fix: ... », « build: ... ») ou laisse-le en proposer un et confirme.

1. **Ça porte sur les skills ou agents aixlper eux-mêmes ?** → improve.
2. **Tu veux une analyse ou une conception, pas encore de code ?** → think.
3. **Ça se prouve dans un navigateur (un écran, un front web) ?** → ui.
4. **Il faut une nouvelle structure : nouvelle classe, interface,
   collaborateur ou frontière ?** Ou un ticket dont les CA doivent être
   tracées et prouvées ? → build.
5. **Ça tient dans les classes existantes** (un bug, une branche manquante,
   un petit changement de comportement) ? → fix. Si tu ne sais pas encore
   *où* est le bug, dis-le : le mode fix commence par `tantei-debug` pour le
   trouver.
6. **Tout le reste** (une question, une modif d'une ligne, une commande) →
   direct.

Ce n'est pas bug ou fonctionnalité qui décide entre fix et build, c'est la
structure. Un comportement manquant qui est une branche de plus dans une
méthode existante est un fix ; un bug dont le vrai remède est un nouveau
composant de retry est un build. Règle simple : s'il faut dessiner une
nouvelle boîte sur l'architecture, c'est build.

Mauvais choix ? Dis le nouveau mode à tout moment (« now build it »,
« think mode ») : il bascule tout de suite, le note dans le bloc `Resume` et
charge les skills du nouveau mode. S'il voit lui-même que le mode est faux
(un fix qui demande du nouveau), il s'arrête et propose de basculer ; il ne
bascule jamais en silence.

### Agent ou session normale ?

- **Tu connais le processus** (un ticket, un fix, une modif UI, une
  conception) : démarre directement avec l'agent, `ci`. Il est autonome dès
  le premier message.
- **Pas encore** (exploration, cas isolé) : `claude` tout court.
- **On ne peut pas basculer une session** entre les deux : le prompt est
  fixé au démarrage de la conversation et le reste à la reprise (vérifié).
  On passe de l'un à l'autre par les fichiers : une nouvelle session `ci` et
  *« resume PROJ-8 »* reprend depuis le bloc `Resume` du journal de
  décisions.
- **Déjà dans une session normale** et le processus s'avère connu ? Tape
  `/saiban-orchestrator` : le même processus se charge comme un skill, avec l'assistant
  par défaut autour. L'agent et le skill partagent un seul texte, donc rien
  ne diverge.

### 3. Ce qui se passe

1. **Une seule approbation au départ** (mode build) : le plan de structure,
   la vérification des CA et toute contradiction du ticket, citée des deux
   côtés.
2. **Un cycle TDD par CA**, du vrai TDD et pas du « test first » : un test
   à la fois, vu en échec, puis le minimum de code qui le fait passer, puis
   un refactoring ; jamais une série de tests écrits à l'avance. Le cycle se
   termine par le build complet et un audit de l'historique git qui prouve
   que chaque test a d'abord été rouge.
3. **Une revue par CA** par `kenji-reviewer`, qui lit mais ne modifie
   jamais : la CA est-elle vraiment prouvée, la structure tient-elle, rien
   de plus que demandé ?
4. **Le suivi de la CA est mis à jour** dans
   `docs/ticket/<id>/acceptance.md` (dès trois CA, un index plus un
   `ac/AC<n>.md` par CA), puis commité.
5. **Un point de sauvegarde** : il continue, mais tu peux faire `/clear` là.

Il ne te demande ton avis que pour une action difficile à annuler, un vrai
choix, un écart par rapport à un plan approuvé, du hors-périmètre ou une CA
floue. Le reste, il le décide et l'écrit.

### 4. Le suivre et économiser

- `docs/decisions/<sujet>.md` : chaque décision, pourquoi, et ce qui a été
  écarté. Son bloc `Resume` dit toujours où en est le travail.
- `docs/ticket/<id>/` : conception, CA avec leurs preuves, difficultés
  rencontrées.
- Le contexte coûte de plus en plus cher en grossissant. Chaque tour finit
  par *« 💾 Save point: /clear is safe »* ou *« ⛔ Don't /clear now: <pourquoi> »*.
  Les points de sauvegarde sont fréquents (chaque étape TDD commitée, chaque
  CA, chaque écran, même une question ouverte une fois écrite), et demander
  *« je peux clear ? »* en crée un tout de suite quand c'est possible.
  Interromps, tape `/clear`, puis `claude --agent saiban-orchestrator` et *« resume PROJ-8 »* : il
  reprend depuis le bloc `Resume` au lieu de tout relire.
- Sujet oublié ? Lancez `ci` sans sujet (ou demandez *« où en étions-nous ? »*) :
  il liste les journaux de décision ouverts, une ligne chacun avec le mode et
  la prochaine étape, et demande lequel reprendre. Un journal marqué
  `Status: done` à la fin n'est plus listé.
- Deux tâches en même temps ? Le serveur local ne fait tourner qu'une
  version du code à la fois. Garde la première tâche dans le dossier que
  sert le serveur ; donne à la seconde sa propre branche (et, hors mode UI,
  un worktree git) pour le code et les tests unitaires. Chaque CA terminée
  loin du serveur est listée en `Not on server` dans son bloc `Resume` et
  comptée dans le récapitulatif : impossible de l'oublier. Pour la vérifier,
  l'orchestrateur prête le serveur à la seconde tâche (redéploie ses jars,
  ou extrait sa branche dans le dossier servi pour Studio Designer), lance
  les vérifications, puis remet la première, en disant à chaque fois quelle
  branche tourne sur le serveur.
  Pour tester les deux ensemble, il les fusionne sur une branche jetable et
  lance les vérifications des deux tâches ; les corrections vont sur la
  branche de la tâche, jamais là. Pour baser l'une sur l'autre (rebase), il
  demande d'abord si la branche a été poussée, note `Based on` dans le bloc
  `Resume`, et relance les vérifications de cette tâche.

Il commite en local, ne pousse jamais, et n'écrit jamais dans Jira sans
qu'on le lui demande.

**Coût mesuré** sur un ticket à deux CA : environ 2,60 $ avec Sonnet,
6,30 $ avec Opus sans `shonin-dev` ; avec (un lancement par GREEN, avant le passage à un par exécution) environ la
moitié en plus, environ 4 $ avec Sonnet. Un petit bug en mode fix : environ
0,30 $ sans lui, mesuré avant qu'il soit le défaut.

### 5. L'améliorer

Le rapport final se termine toujours par **Improvements** : les frictions
rencontrées et la formulation exacte qu'il changerait, dans l'agent ou un
skill. Il ne les applique jamais lui-même. Modifie
`global/agents/saiban-orchestrator.md` (ou le skill) et réinstalle, ou crée un lien
symbolique de `~/.claude/agents/saiban-orchestrator.md` vers le fichier du repo pour que
les modifications s'appliquent tout de suite.

