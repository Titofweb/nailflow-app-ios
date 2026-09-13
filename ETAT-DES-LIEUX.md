# Appli iPhone — état des lieux au 13/09/2026

Comparaison fichier par fichier avec l'appli Android, qui est en service.

---

## Ce qui a été corrigé le 13/09/2026

L'audit ci-dessous a été fait AVANT correction ; il est conservé tel quel,
parce qu'il dit pourquoi chaque changement a eu lieu. Depuis :

- ✅ **L'écran noir** — `AppDelegate` crée la fenêtre et l'écran de départ, et
  le manifeste de scène a été retiré d'`Info.plist`.
- ✅ **La ligne qui ne compilait pas** — parenthèses rétablies autour du
  `as? String`.
- ✅ **`role=po`** — l'appel qui ne pouvait pas aboutir a été supprimé ; reste
  l'enregistrement par JavaScript, celui qui porte la session, comme Android.
- ✅ **`armv7`** — devenu `arm64`.
- ✅ **Les liens externes** — `tel:`, `mailto:`, Waze et les domaines
  extérieurs sortent maintenant de l'appli, avec le même repli web que
  l'Android quand Waze n'est pas installé. Les liens `target="_blank"`, qui
  n'ouvraient rien du tout, sont chargés dans la fenêtre courante.
- ✅ **Les deux marques ont été réunies** : le code vit dans `Shared/`, compilé
  tel quel par les deux. Seul `Info.plist` les distingue.
- ✅ **Le projet Xcode existe**, sous forme de `project.yml` (XcodeGen), avec
  un workflow GitHub qui compile les deux applis **sans Mac et sans compte
  Apple** — de quoi vérifier le code avant de payer quoi que ce soit.
- ✅ **Les icônes 1024×1024** sont en place, agrandies depuis l'aperçu Android.

**Rien de tout cela n'a été compilé** : il n'y a ni Mac ni Xcode sur le poste
où ces corrections ont été écrites. La première compilation GitHub est donc
l'étape qui tranche — c'est précisément à ça qu'elle sert.

Ce qui reste : le compte Apple Developer, la page de confidentialité, les
captures d'écran, et la soumission.

---

## En un mot

*(Constat du 13/09/2026, avant correction.)*

**L'appli iPhone ne compilait pas et ne s'affichait pas.** Ce n'était pas un
détail de finition : il manquait le projet Xcode lui-même, et le code contenait
quatre défauts dont deux empêchaient l'appli de fonctionner.

Le dossier contient 13 fichiers : deux jeux de sources Swift (SL Nails et
Olympique Nails), un `Info.plist`, un écran de lancement et un catalogue
d'icônes VIDE par marque. Aucun `.xcodeproj`.

---

## Ce que fait l'Android, et ce qu'en fait l'iPhone

| Fonction | Android | iPhone | |
|---|---|---|---|
| Ouvre « Mon compte » dans une fenêtre intégrée | oui | oui | ✅ |
| Reste connectée entre deux ouvertures (cookies) | oui | oui | ✅ |
| Barre de progression du chargement | oui | oui | ✅ |
| Tirer vers le bas pour rafraîchir | oui | oui | ✅ |
| Écran « connexion impossible » + Réessayer | oui | oui | ✅ |
| Retour arrière dans l'historique | bouton retour | geste de balayage | ✅ |
| Notifications push (OneSignal) | oui | oui, mais voir défaut ③ | ⚠️ |
| **Liens externes** : `tel:`, `mailto:`, Waze, réseaux sociaux | ouverts dans l'appli du système | **rien ne se passe** | ❌ |
| **Affichage de l'écran principal** | automatique | **jamais créé** — écran noir | ❌ |
| Mise à jour hors store | oui (canal « direct ») | impossible sur iOS, et c'est normal | — |

---

## Les quatre défauts du code

### ① L'écran principal n'est jamais affiché → écran noir

`AppDelegate.swift` ne crée aucune fenêtre et ne désigne aucun écran de
départ. Il n'y a pas non plus de `Main.storyboard`, ni de `SceneDelegate`.
Résultat : `ViewController.swift` — tout le contenu de l'appli — n'est
instancié par personne. L'appli se lance sur un écran noir.

C'est le défaut le plus important : tout le reste du code est correct mais
n'est jamais exécuté.

### ② L'URL de démarrage ne compile pas

Dans `ViewController.swift` :

```swift
Bundle.main.object(forInfoDictionaryKey: "URL_DEMARRAGE") as? String
    .flatMap { URL(string: $0) }
```

En Swift, `as?` s'applique après le `.flatMap` : la ligne est lue comme une
conversion vers un type `String.flatMap`, qui n'existe pas. Il manque
simplement une paire de parenthèses autour du `as? String`.

### ③ L'enregistrement des notifications envoie `role=po`

`enregistrerDeviceOneSignal()` poste `player_id` **et `role=po`** vers
`onesignal_register.php`. Or ce paramètre a été supprimé côté serveur
(migration 076) : l'appli est réservée aux clientes, et c'est le serveur qui
décide si un téléphone est celui du salon, à partir de la session et du
numéro du compte.

Cet appel ne peut de toute façon pas fonctionner : il part par `URLSession`,
donc **sans le cookie de session** du site. Le serveur ne sait pas qui
appelle et refuse. L'appli Android ne fait pas cet appel du tout.

La seconde méthode, `enregistrerDeviceClient()`, est la bonne : elle injecte
du JavaScript dans la page, qui utilise la session déjà ouverte. C'est
exactement ce que fait Android.

### ④ `armv7` dans `Info.plist`

`UIRequiredDeviceCapabilities` réclame `armv7`, c'est-à-dire des iPhone
32 bits — abandonnés depuis longtemps. La valeur attendue aujourd'hui est
`arm64`. L'App Store refuse les envois qui déclarent `armv7`.

---

## Trois autres manques, moins graves

- **Aucune icône.** `Assets.xcassets/AppIcon.appiconset/` ne contient que son
  descripteur ; le PNG 1024×1024 n'y est pas. Apple refuse un envoi sans icône.
- **Les deux marques ont déjà divergé.** `ViewController.swift` d'Olympique
  Nails est une version plus ancienne : pas de gestion des gestes de retour,
  commentaires absents. Elles devraient être identiques, seules les valeurs
  de `Info.plist` changeant d'une marque à l'autre.
- **`ITSAppUsesNonExemptEncryption` absent** d'`Info.plist` : sans lui, Apple
  pose la question du chiffrement à chaque envoi. Une ligne évite d'y répondre
  à la main à chaque fois.

---

## Ce qui bloque, en dehors du code

**Il faut un Mac.** Compiler, archiver et envoyer une appli iOS passe par
Xcode, qui n'existe que sur macOS. L'APK Android, lui, est compilé par
GitHub Actions sans rien installer — c'est ce que fait déjà
`.github/workflows/build-apk.yml`.

Trois voies possibles, par ordre de coût :

1. **GitHub Actions, runner macOS.** Même principe qu'Android : on pousse le
   code, GitHub compile sur un Mac et rend le fichier à envoyer. Demande un
   projet Xcode versionné dans le dépôt, et les certificats Apple stockés en
   secrets. Les minutes macOS sont facturées plus cher que les minutes Linux
   sur un dépôt privé — à vérifier selon le forfait.
2. **Un Mac d'occasion** (Mac mini) — le plus confortable si l'appli doit
   vivre plusieurs années.
3. **Un Mac loué à l'heure** (MacStadium, MacinCloud et équivalents) pour la
   mise en place, puis GitHub Actions pour la suite.

**Et un compte Apple Developer**, payant à l'année (de l'ordre de 99 €).
L'inscription en tant que **personne physique** (entreprise individuelle,
auto-entrepreneur) ne demande pas de numéro D-U-N-S ; en tant que **société**,
si. Le `README.md` actuel affirme que « le même DUNS qu'Android marche » —
à vérifier au moment de l'inscription, les deux plateformes n'ont pas les
mêmes règles.

---

## Combien ça coûte, et à quel nom

**99 € par an et par COMPTE, pas par appli.** Une adhésion au programme Apple
Developer permet de publier autant d'applis qu'on veut. SL Nails et Olympique
Nails tiendraient dans la même.

Deux formes d'adhésion, au même prix :

| | Nom affiché sur l'App Store | D-U-N-S |
|---|---|---|
| Personne physique | ton nom | non |
| Organisation | le nom de la société | oui |

*(L'adhésion « Enterprise » à 299 € existe, mais elle ne donne PAS accès à
l'App Store : elle sert à diffuser en interne dans une entreprise. Ce n'est
pas ce qu'il nous faut.)*

### Le point qui change le calcul

#### Le texte de la règle

> **4.2.6** — Les applications créées à partir d'un modèle commercialisé ou
> d'un service de génération d'applications seront rejetées, sauf si elles sont
> soumises directement par le fournisseur du contenu de l'application. Ces
> services ne doivent pas soumettre d'applications au nom de leurs clients et
> devraient offrir des outils qui permettent à leurs clients de créer des
> applications personnalisées et innovantes qui offrent une expérience client
> unique. Une autre option acceptable pour les fournisseurs de modèles est de
> créer **un seul binaire pour héberger tout le contenu client dans un modèle
> agrégé ou « picker »**, par exemple en tant qu'application de recherche de
> restaurant avec des entrées ou des pages personnalisées distinctes pour
> chaque restaurant client, ou comme une application d'événement avec des
> entrées distinctes pour chaque événement client.

NailFlow tombe pleinement dans la description : une appli par salon, toutes
bâties sur le même modèle. La règle laisse **deux issues praticables**.

#### Voie A — un compte Apple par salon

C'est la première phrase : « soumises directement par le fournisseur du
contenu ». Le compte appartient au salon, qui paie l'adhésion ; NailFlow est
invité dans son équipe et fait le travail technique. C'est l'usage courant, et
ce qui compte pour Apple, c'est à qui appartient le compte.

- **99 € par an et par salon**, payés par le salon.
- **Aucun changement de code** : ce qui est dans ce dossier fonctionne tel quel.
- Le salon est l'éditeur : **son nom**, **son icône** sur l'App Store. Une
  cliente qui cherche « SL Nails » trouve « SL Nails ».
- Une soumission et une relecture **par salon**, avec le risque de refus à
  chaque fois.
- Friction : chaque prothésiste doit s'inscrire elle-même (identifiant Apple,
  double authentification, contrats, moyen de paiement) et renouveler
  chaque année.

#### Voie B — une seule appli NailFlow, avec sélecteur de salon

C'est la dernière phrase de la règle, explicitement autorisée. Une appli
« NailFlow » unique : la cliente l'installe, cherche son salon, et se retrouve
dans son espace.

- **99 € par an au total**, quel que soit le nombre de salons.
- **Un nouveau salon est en ligne sans aucune soumission** : c'est une entrée
  de plus dans le sélecteur. Le jour où une prothésiste signe, l'iPhone suit.
- Une seule relecture Apple, une seule fois. Le risque de refus ne se répète
  pas.
- **Mais l'appli s'appelle NailFlow.** Une cliente qui cherche « SL Nails »
  sur l'App Store ne trouve rien. C'est exactement ce que l'offre promet
  aujourd'hui — « votre propre application » — et il faudrait le réécrire.

**Et elle coûte du travail, surtout là où on ne l'attend pas :**

1. *Un écran de choix du salon*, avec mémorisation et moyen d'en changer.
   Modeste.
2. *Les notifications, et c'est le gros morceau.* Aujourd'hui chaque salon a
   SON compte OneSignal : `ONE_SIGNAL_APP_ID` et `ONE_SIGNAL_REST_API_KEY`
   vivent dans son `po/<salon>/config.php`, et sa gestion envoie avec sa propre
   clé (`onesignal_lib.php`). Avec un binaire unique, tous les iPhone
   s'enregistrent dans **un seul** compte OneSignal — celui de NailFlow. La
   gestion d'un salon, qui envoie avec sa clé à elle, ne les atteindrait plus.

   Deux façons d'en sortir, et une seule est acceptable :

   - mettre la clé NailFlow dans le `config.php` de chaque salon — **non** :
     chaque salon pourrait alors notifier les clientes de tous les autres ;
   - faire passer les envois iOS par **un relais central NailFlow** qui, seul,
     détient la clé. C'est la bonne réponse, mais c'est un service à écrire,
     à héberger et à surveiller.

#### Voie A + Voie B — les deux, et c'est une offre

Rien n'oblige à choisir. Les deux applis peuvent exister en même temps :

- **l'appli NailFlow**, gratuite pour le salon : la cliente l'installe, choisit
  son salon dans la liste, et se retrouve dans son espace ;
- **l'appli au nom du salon**, pour celle qui la veut : 99 € par an, son nom,
  son icône, sa fiche sur l'App Store.

Apple ne s'y oppose pas : la règle 4.2.6 décrit précisément ces deux formes, et
ne dit nulle part qu'elles s'excluent. Les comptes sont différents, les
identifiants d'appli aussi.

Une cliente peut donc avoir les deux installées. Elle aura alors deux icônes
pour le même salon — pas gênant, mais à savoir.

> **À écrire dans les « Notes for Review » de l'appli du salon** : préciser
> qu'elle est publiée par le salon lui-même, et que l'entrée du même nom dans
> l'appli NailFlow est le service mutualisé du prestataire. Un relecteur qui
> découvre les deux sans explication peut y voir un doublon.

#### Le vrai point d'attention : d'où part la notification

C'est là que ça se joue, et pas du côté d'Apple.

Aujourd'hui, `sl_onesignal_device` garde **une ligne par téléphone**
(`player_id`), reliée à la cliente. Quand le salon envoie un rappel,
`slOneSignalEnvoyerAuClient()` prend TOUS les `player_id` de cette cliente et
les envoie **avec la clé OneSignal du salon**.

Or un `player_id` appartient au compte OneSignal qui l'a créé :

- l'appli **du salon** produit un identifiant dans le compte OneSignal **du
  salon** — joignable avec sa clé ;
- l'appli **NailFlow** produit un identifiant dans le compte OneSignal **de
  NailFlow** — que la clé du salon ne peut pas atteindre.

Les deux atterrissent dans la même table, sous la même cliente, sans rien qui
les distingue. Le salon enverrait alors à une liste dont une partie lui est
étrangère : ces envois-là échouent **en silence**.

**Ce qu'il faudra donc ajouter le jour où l'appli NailFlow existe :** une
colonne d'origine sur `sl_onesignal_device` (« salon » ou « nailflow »), et un
aiguillage — les appareils du salon partent directement comme aujourd'hui, ceux
de NailFlow passent par le relais central.

**Mais rien ne presse, et rien n'est perdu si on ne le fait pas maintenant.**
Tant que l'appli NailFlow n'existe pas, tous les appareils enregistrés
viennent de l'appli du salon : la colonne pourra être ajoutée plus tard et
remplie à « salon » pour tout l'existant, sans rien perdre. C'est une décision
à prendre au moment de construire, pas avant.
#### Ce qui décide, et ce n'est pas technique

**Par quoi commencer ?** Les deux voies demandent le même premier pas — une
adhésion, une appli publiée, une réponse d'Apple — mais elles n'ont pas le même
coût de mise en route :

- la **voie A** ne demande **aucun code** : ce qui est dans ce dossier suffit ;
- la **voie B** demande l'écran de choix du salon et, surtout, le relais de
  notifications.

D'où l'ordre naturel : publier d'abord SL Nails sous la voie A, qui ne coûte
que les 99 €, et ne construire l'appli agrégée que si le coût par salon devient
un obstacle à la vente. La première soumission ne ferme aucune porte.

À noter : **Android n'a pas cette règle.** Rien n'oblige à trancher pareil des
deux côtés — on peut garder une appli par salon sur Android, qui marche déjà,
et une appli agrégée sur iPhone. C'est deux discours à tenir, mais chacun est
le meilleur dans sa boutique.

### Qui paie, et qui fait le travail

Deux mots à ne pas confondre :

- **un identifiant Apple** est gratuit. Il ne permet de publier RIEN : tout
  juste d'installer sur son propre iPhone pendant 7 jours, sans notifications ;
- **l'adhésion au programme** est le paiement annuel. C'est elle qui donne
  l'App Store, TestFlight et les notifications.

**On peut travailler sur le compte payant de quelqu'un d'autre sans payer.**
Le salon prend l'adhésion, puis invite NailFlow dans son équipe avec un rôle
(« App Manager » suffit) : on téléverse les versions, on gère la fiche, on
envoie sur TestFlight. Il faut seulement un identifiant Apple gratuit pour
recevoir l'invitation.

**Ce que le salon doit faire lui-même**, et ce n'est pas rien : créer son
identifiant avec la double authentification (obligatoire), s'inscrire,
vérifier son identité, accepter les contrats, entrer un moyen de paiement.
Pour quelqu'un qui n'est pas à l'aise avec ça, compter une petite heure à
deux. C'est un coût de l'offre, au même titre que les 99 €.

**Mais une adhésion à nous reste nécessaire, au moins au début.** Sans elle,
pas de TestFlight, pas d'essai des notifications — donc aucun moyen de savoir
si l'appli tient debout AVANT de demander à une cliente de sortir sa carte.

**Et ce n'est pas un aller sans retour** : Apple permet de **transférer une
appli d'un compte à un autre**. On peut donc publier SL Nails sous le compte
NailFlow, apprendre le chemin, puis la transférer au salon le jour où on passe
au modèle « un compte par salon ». Le transfert a ses conditions (pas de
version en cours de relecture, entre autres) — à vérifier le moment venu.
### Ce que ça suggère comme ordre

1. **NailFlow** prend une adhésion — 99 €. C'est un outil de travail, pas un
   coût par client.
2. **SL Nails** est publiée dessous : le site et l'Android sont déjà à nous,
   c'est le dossier le plus simple. Une soumission, une réponse. C'est là
   qu'on saura si la règle 4.2.6 mord ou non.
3. Selon la réponse, on choisit : rester sous le compte NailFlow tant que ça
   passe, basculer vers **un compte par salon** (voie A, en transférant
   SL Nails), ou construire **l'appli agrégée** (voie B). La première
   soumission ne ferme aucune de ces portes.

On l'aura donc appris pour 99 €, et non pour autant de fois qu'il y a de
salons.

## Marche à suivre

### Avant tout — ce qui prend du temps administratif

1. **Inscription au programme Apple Developer** sur `developer.apple.com`.
   Compter quelques jours de validation. Rien ne peut être publié avant.
2. **Page de politique de confidentialité** accessible publiquement sur le
   site. Apple la refuse absente, et elle doit dire ce que l'appli collecte
   (ici : rien de plus que le site, plus l'identifiant de notification).

### Ensuite — mettre le code en état

3. ✅ ~~Corriger les quatre défauts.~~ **Fait**, mais non compilé.
4. ✅ ~~Créer le projet Xcode et le versionner.~~ **Fait** : `project.yml` par
   marque, engendré par XcodeGen.
5. ✅ ~~Ajouter le SDK OneSignal.~~ **Fait** : déclaré dans `project.yml`,
   Xcode le télécharge seul.
6. ✅ ~~Poser l'icône 1024×1024.~~ **Fait**, agrandie depuis l'aperçu Android —
   à regénérer depuis l'original quand il sera sous la main.

6bis. **Pousser le dossier sur un dépôt GitHub et regarder l'onglet Actions.**
   C'est l'étape qui dit si tout ce qui précède tient debout. Elle ne demande
   ni Mac ni compte Apple.

### Puis — les clés et les identifiants

7. **Bundle ID** : `fr.slnails.app` et `fr.olympiquenails.app`, les mêmes
   qu'Android. À déclarer dans le compte développeur.
8. **Clé APNs** (`developer.apple.com` → Keys → Apple Push Notifications
   service) : un fichier `.p8` à téléverser dans OneSignal, onglet Apple iOS.
   Les App ID OneSignal sont les mêmes que sur Android, rien à recréer :
   - SL Nails `307a06ab-4f27-42f8-b8f0-0f1fe77c5c6f`
   - Olympique Nails `fcaa64f1-7315-4506-b14e-44ed4ee48669`

### Essayer sur un vrai iPhone, avant toute soumission

Oui, c'est possible, et à trois niveaux. Apple n'entre dans la boucle qu'au
troisième — et encore, sans relecture complète.

#### Niveau 0 — gratuit, tout de suite, sans rien installer

- **Le site lui-même** : ouvre `https://www.slnails.fr/mon-compte/` dans
  Safari sur un iPhone. L'appli n'est qu'une fenêtre autour de cette page :
  l'affichage, la connexion, le compte, les rendez-vous se testent là,
  exactement tels qu'ils apparaîtront.
  Ce que ça ne teste PAS : les notifications, l'ouverture des liens `tel:` et
  Waze hors de l'appli, le tirer-pour-rafraîchir, l'écran d'erreur.
- **La compilation** : pousse le dossier sur GitHub, onglet Actions. Ça ne met
  rien sur un téléphone, mais ça répond à la seule question qu'on ne peut pas
  trancher autrement — est-ce que le code est juste.

#### Niveau 1 — un Mac, sans payer les 99 €

Avec un simple identifiant Apple (gratuit), Xcode sait installer l'appli sur
**ton propre iPhone**, branché en USB. Trois limites, et la dernière compte :

- le certificat expire au bout de **7 jours** : passé ce délai, l'appli ne
  s'ouvre plus tant qu'on ne la réinstalle pas depuis Xcode ;
- trois applis installées de cette façon au maximum ;
- **les notifications push ne fonctionnent pas** : cette capacité est réservée
  aux comptes payants.

C'est donc bien pour vérifier l'affichage, la navigation, les liens externes
et l'écran d'erreur. Pas pour les notifications, qui sont justement le cœur
de l'argument face à Apple.

> Après installation : Réglages → Général → VPN et gestion de l'appareil →
> faire confiance au certificat, sinon l'appli refuse de s'ouvrir.

#### Niveau 2 — TestFlight, avec le compte payant

C'est la vraie réponse. TestFlight est l'outil d'Apple pour faire essayer une
appli avant publication :

- jusqu'à **100 testeurs internes** (les comptes de ton équipe App Store
  Connect) — et **ces envois ne passent PAS par la relecture d'Apple** : la
  version est disponible en quelques minutes ;
- des testeurs **externes** (jusqu'à 10 000, sur simple e-mail) sont possibles
  aussi, mais demandent une « Beta App Review », plus rapide et plus souple
  que la relecture complète ;
- **les notifications fonctionnent**, avec la vraie clé APNs ;
- chaque version reste installable 90 jours.

Concrètement : on envoie une version, les testeurs reçoivent une invitation,
installent l'appli TestFlight et la version apparaît dedans. On corrige, on
renvoie, sans jamais toucher à l'App Store.

**Et sans Mac ?** Possible : le workflow GitHub peut être étendu pour signer
l'appli et l'envoyer sur TestFlight tout seul. Il faut alors y déposer le
certificat et le profil de provisionnement en secrets — donc le compte payant
d'abord. Le Mac n'est pas indispensable ; le compte, si.

#### En résumé

| | Mac | Compte payant | Notifications | Durée |
|---|---|---|---|---|
| Safari sur iPhone | non | non | non | — |
| Compilation GitHub | non | non | — | — |
| Xcode + identifiant gratuit | **oui** | non | **non** | 7 jours |
| TestFlight interne | non* | **oui** | oui | 90 jours |

\* sans Mac, à condition d'étendre le workflow GitHub.
### Enfin — la publication

9. **Premier build sur un iPhone réel**, par câble, pour vérifier que la page
   « Mon compte » s'affiche, que la connexion tient, et qu'une notification
   arrive.
10. **Créer la fiche** sur `appstoreconnect.apple.com`. Le contenu est le même
    que Google Play : reprendre `nailflow App Android/store/fiche-store.md`.
11. **Captures d'écran** aux tailles imposées (6,7″ et 6,5″). Le simulateur
    Xcode suffit et donne les bonnes dimensions.
12. **Archive → App Store Connect → soumission.** La relecture Apple prend
    généralement un à trois jours, et elle est faite par une personne : un
    refus arrive avec un motif, auquel on répond.

---

## Où poser la question à Apple

Trois endroits, et ils ne répondent pas à la même chose.

| Où | Pour quoi | Adhésion requise |
|---|---|---|
| **App Review** — `developer.apple.com/contact/app-store/` | Questions sur les règles, dont la 4.2.6. C'est le bon endroit. | oui |
| **Support du programme** — `developer.apple.com/support/` | Inscription, facturation, rôles d'équipe, transfert d'appli. Téléphone en français. | non, avant inscription |
| **Forums développeurs** — `developer.apple.com/forums/` | Avis d'autres développeurs, parfois d'ingénieurs Apple. Gratuit. | non |

Et les règles elles-mêmes : `developer.apple.com/app-store/review/guidelines/`,
section 4.2.6.

### Avant de payer quoi que ce soit

**Créer l'identifiant Apple gratuit, maintenant.** Il ne coûte rien, prend dix
minutes, et il sert de toute façon : c'est lui qui deviendra le titulaire de
l'adhésion, ou qui recevra l'invitation sur le compte d'un salon.

Ce qu'il ouvre déjà, sans payer :

- **les forums développeurs** — on peut y poser la question publiquement ;
- **la documentation et les règles** dans leur version officielle ;
- **le support du programme** pour les questions d'inscription (personne
  physique ou société, D-U-N-S, transfert d'appli) ;
- l'installation sur son propre iPhone depuis Xcode, 7 jours, sans
  notifications — à condition d'avoir un Mac.

Ce qu'il n'ouvre **pas** : App Store Connect, TestFlight, et le guichet App
Review — celui qui répond justement aux questions sur la règle 4.2.6.

> **Attendre une réponse tranchée avant de payer serait une impasse.** Le seul
> guichet qui traite les règles demande l'adhésion. Le support pré-inscription
> renverra vers lui. Les forums donneront l'expérience d'autres développeurs —
> souvent plus utile en pratique, beaucoup de services de ce type ont croisé
> la 4.2.6 — mais rien qui engage Apple.

### Le choix qu'on fait sans y penser

**Quel identifiant Apple ?** Il deviendra le titulaire du compte développeur.
Deux règles :

- une adresse **de l'entreprise**, pas une adresse personnelle — un compte
  attaché à une boîte perso devient un problème le jour où l'activité grandit
  ou change de mains ;
- la **double authentification** sur un téléphone qui restera accessible :
  c'est elle qui ouvrira le compte pendant des années.

Changer l'identifiant titulaire après coup se fait mal. Dix minutes de
réflexion maintenant valent mieux qu'un transfert de compte plus tard.
### Ce qu'ils répondront, et ce qu'ils ne répondront pas

Apple ne donne **pas** d'accord préalable. On n'obtiendra jamais « oui, votre
appli sera acceptée » avant de l'avoir soumise. En revanche App Review répond
aux questions d'interprétation, et c'est déjà beaucoup : savoir si le modèle
« une appli par salon » doit passer par un compte par salon est exactement ce
genre de question.

La formulation compte. Plutôt que « est-ce que mon appli sera acceptée ? »,
demander quelque chose comme :

> Je développe pour des salons de manucure indépendants une application liée
> à leur site : espace client, prise de rendez-vous, notifications de rappel.
> Chaque salon a son propre contenu, sa marque et son établissement.
> Au regard de la règle 4.2.6, ces applications doivent-elles être publiées
> depuis le compte Apple Developer de chaque salon, ou puis-je les publier
> depuis le mien en tant que prestataire ?

### Le champ qu'il ne faut pas laisser vide

Au moment de soumettre, App Store Connect propose **« Notes for Review »**.
C'est là qu'on explique son cas au relecteur — une personne, pas un automate.
Y écrire : le salon existe, voici son adresse et son site, l'appli sert à ses
clientes, et les notifications de rappel de rendez-vous sont ce qu'un site web
ne sait pas faire sur iPhone. Beaucoup de refus 4.2 tombent faute de ce
paragraphe.

---
## Le point à surveiller à la relecture Apple

Apple refuse régulièrement les applis qui ne sont **qu'un site web emballé**,
au motif qu'elles n'apportent rien qu'un navigateur ne fasse (règle 4.2,
« minimum functionality »). C'est exactement ce que sont ces deux applis.

Ce qui joue en leur faveur, et qu'il faut mettre en avant dans la fiche et
dans la note à la relecture :

- les **notifications push** — un rappel de rendez-vous ne peut pas arriver
  par un site web sur iPhone ;
- un **compte client** avec réservation, historique, fidélité ;
- une appli **liée à un commerce réel et identifié**, pas un site générique.

Android n'a pas cette règle. C'est la principale inconnue du dossier, et elle
ne se lève qu'en soumettant.
