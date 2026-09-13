import UIKit
import OneSignalFramework

/**
 * Point d'entrée de l'appli.
 *
 * PARTAGÉ PAR LES DEUX MARQUES : ce fichier est compilé tel quel dans SL Nails
 * et dans Olympique Nails. Tout ce qui change d'une marque à l'autre — le nom,
 * l'adresse du site, l'identifiant OneSignal — vit dans son `Info.plist`.
 * Les deux avaient chacune leur copie du code, et elles avaient déjà divergé.
 *
 * IL CRÉE LA FENÊTRE ET L'ÉCRAN DE DÉPART, et c'est nouveau : la version
 * précédente ne le faisait pas, et il n'y avait ni Main.storyboard ni
 * SceneDelegate. ViewController — c'est-à-dire tout le contenu de l'appli —
 * n'était donc instancié par personne : l'appli s'ouvrait sur un écran noir.
 *
 * On reste sur le cycle de vie « app delegate » plutôt que d'ajouter un
 * SceneDelegate : cette appli n'a qu'une seule fenêtre et n'en aura jamais
 * deux. Une pièce de moins à tenir. C'est pour cela que `Info.plist` ne
 * déclare PAS de UIApplicationSceneManifest — l'y remettre sans écrire le
 * SceneDelegate qui va avec ramènerait l'écran noir.
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Notifications push. L'App ID est propre à la marque : sans lui,
        // l'appli fonctionne normalement, simplement sans notifications —
        // même comportement que sur Android.
        if let appId = Bundle.main.object(forInfoDictionaryKey: "OneSignal_AppId") as? String,
           !appId.isEmpty {
            OneSignal.initialize(appId, withLaunchOptions: launchOptions)

            // fallbackToSettings: true — si la cliente a déjà refusé une fois,
            // iOS ne repose plus la question ; on l'emmène alors dans les
            // réglages plutôt que de ne rien faire du tout.
            OneSignal.Notifications.requestPermission({ _ in }, fallbackToSettings: true)
        }

        let fenetre = UIWindow(frame: UIScreen.main.bounds)
        fenetre.rootViewController = ViewController()
        fenetre.makeKeyAndVisible()
        window = fenetre

        return true
    }
}
