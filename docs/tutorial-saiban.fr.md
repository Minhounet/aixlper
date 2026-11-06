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
| `tantei-inspector` | Inspecteur : lit l'usage des skills, propose des changements | Lecture seule, et ne doit pas connaître les raisons de la session de travail ; sa longue lecture reste hors de la session principale | `saiban-orchestrator`, mode improve | Non |

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
  hot reload. Un écran à la fois, avec une pause entre les écrans. Pas de
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
- **Mode direct** (tout le reste) : une question, une petite modif, une
  commande. Il le fait, sans cérémonie, donc plus besoin de `claude` tout
  court.

Il propose le mode, tu confirmes. Options à ajouter dans ce premier
message :

| Dire | Effet |
|---|---|
| `pre-approve TDD plans` | Pas d'approbation par plan de CA. |
| `no pauses` | Pas d'arrêt après chaque CA. |
| `no review` | Pas d'`kenji-reviewer` après chaque CA (mode build). |
| `no tester` | En mode UI, l'orchestrateur écrit et lance les checks lui-même au lieu de `mokugeki-tester` (activé par défaut ; coût pas encore mesuré). |
| `with review` | En mode fix, une revue `kenji-reviewer` du correctif (désactivée par défaut ; environ 0,30 $). |
| `with dev` / `no dev` | Force `shonin-dev` activé ou désactivé. Sans l'un ni l'autre, l'orchestrateur décide pour chaque exécution TDD : activé pour un ticket build à deux CA ou plus, ou un plan de quatre tests ou plus, désactivé sinon, et il l'annonce dans le plan que vous approuvez. Activé, le code est écrit par un seul agent par exécution, qui ne voit que les tests en échec, pas le plan ; environ 2,7× le coût sur les katas, bénéfice pas encore mesuré. |

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
   `docs/ticket/<id>/acceptance.md`, puis commité.
5. **Une pause** : *« AC1 done. Continue, or /clear and resume? »*

Il ne te demande ton avis que pour une action difficile à annuler, un vrai
choix, un écart par rapport à un plan approuvé, du hors-périmètre ou une CA
floue. Le reste, il le décide et l'écrit.

### 4. Le suivre et économiser

- `docs/decisions/<sujet>.md` : chaque décision, pourquoi, et ce qui a été
  écarté. Son bloc `Resume` dit toujours où en est le travail.
- `docs/ticket/<id>/` : conception, CA avec leurs preuves, difficultés
  rencontrées.
- Le contexte coûte de plus en plus cher en grossissant. À une pause, tape
  `/clear`, puis `claude --agent saiban-orchestrator` et *« resume PROJ-8 »* : il
  reprend depuis le bloc `Resume` au lieu de tout relire.
- Sujet oublié ? Lancez `ci` sans sujet (ou demandez *« où en étions-nous ? »*) :
  il liste les journaux de décision ouverts, une ligne chacun avec le mode et
  la prochaine étape, et demande lequel reprendre. Un journal marqué
  `Status: done` à la fin n'est plus listé.

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

