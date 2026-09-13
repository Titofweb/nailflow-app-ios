# Faire compiler l'appli sur GitHub — pas à pas

**Objectif :** savoir si le code iPhone est juste. Ni Mac, ni compte Apple, ni
carte bancaire. Une dizaine de minutes.

GitHub prête une machine macOS le temps de la compilation. Même principe que
l'APK Android, qui est déjà fabriqué comme ça.

---

## Ce que ça prouve, et ce que ça ne prouve pas

- ✅ **Le Swift compile**, le projet est cohérent, le SDK OneSignal s'installe.
- ❌ Ça ne dit **pas** que l'appli s'affiche correctement sur un iPhone, ni que
  les notifications arrivent. Ça, seul un vrai téléphone le dira.

C'est quand même l'étape décisive : le code n'a jamais été compilé, et c'est la
seule inconnue qu'on peut lever gratuitement.

---

## Étape 1 — Le dépôt

1. Va sur **github.com** et connecte-toi (le compte qui sert déjà pour l'appli
   Android fait l'affaire).
2. En haut à droite : **+** → **New repository**.
3. **Repository name** : `nailflow-app-ios`
4. **Public** ou **Private** — voir l'encadré ci-dessous.
5. Ne coche **rien** d'autre (pas de README, pas de .gitignore : on a les
   nôtres).
6. **Create repository**.

> ### Public ou privé ?
>
> **Sur un dépôt public, les compilations macOS sont gratuites et illimitées.**
> Sur un dépôt privé, elles sont décomptées du forfait mensuel avec un
> **coefficient 10** : une compilation de 5 minutes en consomme 50. Avec les
> 2 000 minutes gratuites, ça laisse une quarantaine de compilations par mois —
> suffisant, mais ça se surveille.
>
> **Ce dossier ne contient aucun secret.** Je l'ai vérifié : pas de mot de
> passe, pas de clé d'API. Le seul identifiant présent, `OneSignal_AppId`, est
> public par nature — il est embarqué dans chaque appli publiée sur l'App
> Store. La clé qui doit rester secrète, elle (`ONE_SIGNAL_REST_API_KEY`), vit
> dans `po/<salon>/config.php`, côté site, et n'est pas ici.
>
> Public est donc sans danger, et gratuit. Privé marche aussi.

---

## Étape 2 — Envoyer les fichiers

⚠️ **Le piège numéro un : envoyer le CONTENU du dossier, pas le dossier.**

À la racine du dépôt, on doit voir `Shared`, `SLNails`, `OlympiqueNails`,
`README.md`… et **pas** un dossier `nailflow App Apple` qui contiendrait tout.
Le workflow cherche `SLNails/project.yml` à la racine : d'un cran trop bas, il
ne trouve rien.

1. Sur la page du dépôt vide : **uploading an existing file**.
2. Ouvre le dossier `nailflow App Apple` dans l'explorateur Windows.
3. **Sélectionne tout ce qu'il y a DEDANS** (Ctrl+A) et fais-le glisser dans la
   page GitHub.
4. En bas : **Commit changes**.

⚠️ **Le piège numéro deux : le dossier `.github` est invisible sous Windows.**
Il commence par un point, l'explorateur le cache par défaut, et il ne partira
pas dans le glisser-déposer. C'est justement lui qui contient la compilation.

**Le plus simple est de le recréer directement sur GitHub :**

1. Dans le dépôt : **Add file** → **Create new file**.
2. Dans le champ du nom, tape exactement :
   `.github/workflows/build-ios.yml`
   *(les barres obliques créent les dossiers toutes seules)*
3. Colle le contenu du fichier `build-ios.yml` — ouvre-le avec le Bloc-notes
   depuis `nailflow App Apple\.github\workflows\`.
   *(Pour le voir dans l'explorateur : onglet Affichage → cocher « Éléments
   masqués ».)*
4. **Commit changes**.

---

## Étape 3 — Regarder

Dès le dépôt du workflow, la compilation démarre.

1. Onglet **Actions**.
2. Une ligne « Build iOS » apparaît, avec un point orange : c'est en cours.
   Compter 5 à 10 minutes la première fois — la machine télécharge le SDK
   OneSignal.
3. Clique dessus : deux tâches, **SLNails** et **OlympiqueNails**, compilées
   séparément.

### Coche verte

Le code compile. C'est ce qu'on voulait savoir. La suite : le compte Apple,
puis TestFlight.

### Croix rouge

**C'est une information, pas un échec.** Ce code n'a jamais été compilé : une
erreur au premier essai est normale.

1. Clique sur la tâche en rouge.
2. Déplie l'étape marquée d'une croix — en général **Compilation**.
3. Cherche les lignes contenant `error:`. Elles nomment le fichier et la ligne.
4. **Copie ces lignes et envoie-les-moi.** Avec le nom du fichier et le numéro
   de ligne, la correction est directe.

Inutile de tout copier : les quelques lignes `error:` suffisent.

---

## Relancer sans rien changer

Onglet **Actions** → « Build iOS » dans la colonne de gauche → bouton
**Run workflow**. Utile après une correction, ou pour vérifier que rien n'a
bougé.
