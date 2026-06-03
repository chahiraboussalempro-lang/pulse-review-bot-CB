# pipeline-seed — mini-monorepo Pulse (seed partagé du lab J9)

> Seed **commun aux deux blocs** (`../matin/` et `../apres-midi/`). Vue d'ensemble : `../README.md`.

Base de départ du lab J9. Trois petits services Python + une **CI GitHub de base**
(`.github/workflows/ci.yml` : `lint → test → build`, **sans** agent). Vous allez y
greffer l'**étape agent IA** (revue + sécurité + changelog) puis le **deploy staging**
+ la **gate d'approbation humaine**.

```
pipeline-seed/
├── services/                api.py (SQLite paramétré) · scorer.py · notifier.py
├── tests/                   un test par service (vert au départ)
├── CHANGELOG.md             toute PR qui change un comportement public doit l'enrichir
├── pyproject.toml           ruff (E,F,I,B — PAS de sécurité) + pytest
├── .github/workflows/ci.yml CI de BASE (lint/test/build)
└── make-prs.sh              génère le repo + 5 PR de test
```
*(Les énoncés et les solutions sont dans `../matin/` et `../apres-midi/`.)*

> **Le lint ne fait pas la sécurité** (`select = E,F,I,B`, pas de `S`/bandit) : un
> secret en dur ou une injection SQL **passent le lint**. C'est voulu — c'est
> l'étape **agentique** qui les attrape. « CI verte » ≠ « sûr à merger ».

## Vérifier en local (l'état de départ est vert)

```bash
pip install ruff pytest
ruff check .       # 0 erreur (E,F,I,B)
pytest -q          # tous verts
```

## Les 5 PR de test (`make-prs.sh`)

```bash
bash make-prs.sh ../pulse-prs      # repo git : main + 5 branches pr1..pr5
```

| Branche | Défaut | Verdict agent attendu |
|---|---|---|
| `pr1-clean` | aucun | rien (juge de paix) |
| `pr2-secret` | token en dur | critical |
| `pr3-debug-log` | `print()` de debug | warning |
| `pr4-deleted-test` | test supprimé pour passer | critical |
| `pr5-sqli` | injection SQL | critical |

**Toutes ont une CI verte** : seul l'agent fait la différence.

## Ce que vous construisez

- **Matin** : `review-pr.sh` (un diff → revue + sécurité + changelog → JSON
  `{file,line,severity,category,message}`), testé en local sur les 5 PR.
- **Après-midi** : le workflow GitHub Actions `ai-review.yml` (déclenché sur PR,
  poste les commentaires inline, **bloque sur `critical`**), + branch protection
  (check requis + approbation humaine) + deploy staging.

Énoncés : `../matin/ENONCE-matin.md` + `../apres-midi/ENONCE-apres-midi.md`.
Références formateur : `../matin/SOLUTION/` + `../apres-midi/SOLUTION/`.
