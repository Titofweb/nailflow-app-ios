# Nailflow — applis iPhone

Deux applis « coquille » : elles affichent l'espace « Mon compte » du site
dans une fenêtre intégrée. Elles n'ont aucune logique propre — toute la
connexion, le compte et les rendez-vous viennent du site, comme dans un
navigateur. Une évolution du site se répercute donc ici sans retoucher
l'appli. Même principe que l'appli Android.

> **L'appli n'a encore jamais été compilée ni publiée.** Ce qui reste à faire,
> étape par étape, et les points à surveiller : **[ETAT-DES-LIEUX.md](ETAT-DES-LIEUX.md)**.

---

## Comment c'est rangé

```
Shared/              le code, compilé TEL QUEL par les deux marques
  AppDelegate.swift
  ViewController.swift

SLNails/
  project.yml        la description du projet Xcode
  SLNails/
    Info.plist       nom, adresse du site, App ID OneSignal — ce qui change
    LaunchScreen.storyboard
    Assets.xcassets/ l'icône 1024×1024

OlympiqueNails/      la même chose, avec ses valeurs

.github/workflows/build-ios.yml   compile les deux sur GitHub, sans Mac
```

**Le code n'existe qu'en un exemplaire.** Chaque marque avait sa copie
d'`AppDelegate.swift` et de `ViewController.swift`, et elles avaient déjà
divergé — celle d'Olympique Nails était restée en arrière. Tout ce qui
distingue une marque de l'autre tient désormais dans son `Info.plist`.

---

## Vérifier que ça compile — sans Mac, sans compte Apple

C'est la première chose à faire, et elle ne coûte rien.

1. Crée un dépôt sur [github.com](https://github.com), par exemple
   `nailflow-app-ios`.
2. Mets-y tout le contenu de ce dossier.
3. Onglet **Actions** : la compilation démarre toute seule. Coche verte = le
   code est bon. Croix rouge = le message nomme le fichier et la ligne.

**Pas à pas, avec les pièges** (le dossier `.github` invisible sous Windows,
le contenu à envoyer plutôt que le dossier) : **[GUIDE-GITHUB.md](GUIDE-GITHUB.md)**.

La compilation vise le simulateur, ce qui ne demande **aucune signature** :
pas besoin du programme développeur pour cette étape. Même principe que
`build-apk.yml` côté Android.

> Sur un dépôt privé, les minutes macOS sont facturées plus cher que les
> minutes Linux. À surveiller si les compilations s'enchaînent.

---

## Travailler sur un Mac

Le projet Xcode n'est pas versionné : il est **engendré** à partir de
`project.yml`. Un `.xcodeproj` est un dossier au format interne d'Xcode,
illisible en diff et qui entre en conflit au moindre travail à deux.

```bash
brew install xcodegen          # une fois
cd "nailflow App Apple/SLNails"
xcodegen generate              # fabrique SLNails.xcodeproj
open SLNails.xcodeproj
```

Xcode télécharge tout seul le SDK OneSignal (déclaré dans `project.yml`).

Pour lancer sur un iPhone : branche-le, choisis-le dans la barre d'outils,
**Cmd + R**. Il faudra un compte Apple Developer pour signer.

---

## Changer quelque chose

| Quoi | Où |
|---|---|
| Nom affiché | `<marque>/<marque>/Info.plist` → `CFBundleDisplayName` |
| Adresse de démarrage | `Info.plist` → `URL_DEMARRAGE` |
| App ID OneSignal | `Info.plist` → `OneSignal_AppId` |
| Numéro de version | `project.yml` → `MARKETING_VERSION` et `CURRENT_PROJECT_VERSION` |
| Icône | `Assets.xcassets/AppIcon.appiconset/icone-1024.png` |
| Comportement de l'appli | `Shared/ViewController.swift` — **pour les deux marques à la fois** |

L'icône actuelle est agrandie depuis l'aperçu Android en 512×512 : elle est
donc un peu douce. Il vaudra mieux la regénérer en 1024 depuis l'original le
jour où il est sous la main. Apple veut un carré **plein** — ni transparence,
ni coins arrondis : il les arrondit lui-même.

---

## Ce que fait l'appli

- Ouvre `https://<site>/mon-compte/` au démarrage.
- Garde la cliente connectée d'une ouverture à l'autre (cookies persistés).
- Balayage vers la droite = retour en arrière dans l'historique du site.
- Tirer vers le bas = rafraîchir.
- Écran « connexion impossible » avec bouton **Réessayer**.
- Liens `tel:`, `mailto:`, Waze, réseaux sociaux : ouverts hors de l'appli,
  dans l'appli du système. Sans cela ils ne feraient rien du tout.
- Notifications push : le téléphone est enregistré auprès du salon quand la
  page « Mon compte » est chargée, donc quand la cliente est connectée.

---

## Deux choses à savoir

**Pas de mise à jour hors store.** Contrairement à Android, iOS n'autorise
rien en dehors de l'App Store. Le canal « direct » de l'Android n'a pas
d'équivalent ici, et c'est normal.

**Apple peut refuser une appli qui n'est qu'un site emballé** (sa règle 4.2).
C'est la principale inconnue de ce dossier. Ce qui plaide en notre faveur —
les notifications push, le compte client, un commerce identifié — est détaillé
dans [ETAT-DES-LIEUX.md](ETAT-DES-LIEUX.md).
