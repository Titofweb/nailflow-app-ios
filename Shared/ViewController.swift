import UIKit
import WebKit
import OneSignalFramework

/**
 * Appli « coquille » : elle affiche l'espace « Mon compte » du site, et rien
 * d'autre. C'est le site qui gère la connexion, le compte, les rendez-vous —
 * toute évolution du site se répercute ici sans retoucher l'appli.
 *
 * PARTAGÉ PAR LES DEUX MARQUES. L'adresse de départ vient d'`Info.plist`.
 *
 * Miroir de MainActivity.kt côté Android : quand l'un des deux change, l'autre
 * doit suivre. Ce qui diffère tient aux plateformes, pas aux intentions :
 * Android a un bouton retour matériel, iOS un geste de balayage.
 */
class ViewController: UIViewController, WKNavigationDelegate {

    private var webView: WKWebView!
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let refreshControl = UIRefreshControl()
    private let errorView = UIView()
    private var observation: NSKeyValueObservation?

    /// L'adresse de départ, propre à la marque (Info.plist → URL_DEMARRAGE).
    ///
    /// Les parenthèses autour du `as? String` ne sont pas décoratives : sans
    /// elles, Swift applique `as?` APRÈS le `.flatMap` et lit la ligne comme
    /// une conversion vers un type « String.flatMap », qui n'existe pas. Le
    /// fichier ne compilait pas.
    private var urlDemarrage: URL? {
        (Bundle.main.object(forInfoDictionaryKey: "URL_DEMARRAGE") as? String)
            .flatMap { URL(string: $0) }
    }

    /// Le domaine du salon, sans « www. » — sert à distinguer un lien interne
    /// (qui reste dans l'appli) d'un lien externe (qui part dehors).
    private var domaineDemarrage: String {
        guard let hote = urlDemarrage?.host?.lowercased() else { return "" }
        return hote.hasPrefix("www.") ? String(hote.dropFirst(4)) : hote
    }

    // MARK: - Cycle de vie

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        configurerWebView()
        configurerBarreProgression()
        configurerRafraichissement()
        configurerVueErreur()
        chargerPageDemarrage()
    }

    // MARK: - Configuration

    private func configurerWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // Persistance des cookies entre deux sessions : la cliente reste
        // connectée au site d'une ouverture à l'autre.
        config.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        // Geste de balayage vers la droite = retour en arrière dans
        // l'historique du site. C'est l'équivalent du bouton retour Android.
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Suivi de la progression de chargement (0.0 → 1.0).
        observation = webView.observe(\.estimatedProgress) { [weak self] _, _ in
            guard let self = self else { return }
            self.progressBar.setProgress(Float(self.webView.estimatedProgress), animated: true)
            self.progressBar.isHidden = self.webView.estimatedProgress >= 1.0
        }
    }

    private func configurerBarreProgression() {
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = UIColor(named: "AccentColor") ?? .systemPink
        progressBar.trackTintColor = .clear
        view.addSubview(progressBar)

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 2)
        ])
    }

    private func configurerRafraichissement() {
        refreshControl.addTarget(self, action: #selector(rafraichir), for: .valueChanged)
        // `scrollView.refreshControl` plutôt qu'un addSubview : c'est la
        // propriété prévue pour ça, et elle place le contrôle correctement
        // quelle que soit la position de défilement.
        webView.scrollView.refreshControl = refreshControl
    }

    private func configurerVueErreur() {
        errorView.backgroundColor = .systemBackground
        errorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(errorView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(stack)

        let titre = UILabel()
        titre.text = "Connexion impossible"
        titre.font = .systemFont(ofSize: 18, weight: .semibold)
        stack.addArrangedSubview(titre)

        let message = UILabel()
        message.text = "Vérifie ta connexion internet, puis réessaie."
        message.textColor = .secondaryLabel
        message.textAlignment = .center
        stack.addArrangedSubview(message)

        let bouton = UIButton(type: .system)
        bouton.setTitle("Réessayer", for: .normal)
        bouton.addTarget(self, action: #selector(chargerPageDemarrage), for: .touchUpInside)
        stack.addArrangedSubview(bouton)

        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor)
        ])

        errorView.isHidden = true
    }

    // MARK: - Actions

    @objc private func chargerPageDemarrage() {
        errorView.isHidden = true
        guard let url = urlDemarrage else { return }
        webView.load(URLRequest(url: url))
    }

    @objc private func rafraichir() {
        webView.reload()
    }

    // MARK: - Où s'ouvre chaque lien

    /**
     * Décide quoi faire de chaque navigation — l'équivalent exact de
     * shouldOverrideUrlLoading() côté Android, qui n'existait pas ici.
     *
     * Sans cette méthode, un lien « tel: », « mailto: » ou « waze:// » ne fait
     * RIEN dans une WKWebView : les boutons « Appeler » et « Itinéraire » du
     * site restaient muets, sans le moindre message.
     *
     *  - lien non-web (tel:, mailto:, waze://…) : confié au système, qui ouvre
     *    l'appli correspondante ;
     *  - lien http(s) hors du domaine du salon : ouvert dans Safari, pour ne
     *    pas enfermer la cliente dans une page dont elle ne peut plus sortir ;
     *  - tout le reste : chargé dans l'appli.
     */
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = (url.scheme ?? "").lowercased()

        if scheme != "http" && scheme != "https" {
            ouvrirDehors(url)
            decisionHandler(.cancel)
            return
        }

        let domaine = domaineDemarrage
        if !domaine.isEmpty {
            var hote = (url.host ?? "").lowercased()
            if hote.hasPrefix("www.") { hote = String(hote.dropFirst(4)) }
            let estInterne = hote == domaine || hote.hasSuffix("." + domaine)
            if !estInterne {
                ouvrirDehors(url)
                decisionHandler(.cancel)
                return
            }
        }

        /*
         * UN LIEN « target="_blank" » N'A PAS DE FENÊTRE OÙ S'OUVRIR dans une
         * WKWebView : sans ces deux lignes il ne se passe rien, et c'est un
         * piège classique — le site fonctionne, l'appli non. On le charge
         * dans la fenêtre courante.
         */
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    /**
     * Ouvre un lien hors de l'appli. Si rien ne sait le gérer (Waze non
     * installé, par exemple), on retombe sur l'équivalent web — même repli
     * que côté Android.
     *
     * Pour que canOpenURL() réponde « oui » sur un schéma tiers, celui-ci doit
     * être déclaré dans Info.plist (LSApplicationQueriesSchemes). C'est fait
     * pour « waze » ; un nouveau schéma utilisé par le site devra y être
     * ajouté, sinon le lien partira silencieusement dans le repli.
     */
    private func ouvrirDehors(_ url: URL) {
        let systeme = UIApplication.shared

        if systeme.canOpenURL(url) {
            systeme.open(url, options: [:], completionHandler: nil)
            return
        }

        // waze://?ll=48.8,2.35&navigate=yes → https://www.waze.com/ul?ll=…
        if (url.scheme ?? "").lowercased() == "waze" {
            var parametres = url.absoluteString
            if let separateur = parametres.firstIndex(of: "?") {
                parametres = String(parametres[parametres.index(after: separateur)...])
            } else {
                parametres = ""
            }
            if let secours = URL(string: "https://www.waze.com/ul?" + parametres) {
                systeme.open(secours, options: [:], completionHandler: nil)
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        errorView.isHidden = true
        progressBar.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressBar.isHidden = true
        refreshControl.endRefreshing()

        // Enregistre le téléphone auprès du salon quand la page « Mon compte »
        // est chargée — donc quand la cliente est connectée.
        if let url = webView.url?.absoluteString, url.contains("mon-compte") {
            enregistrerDeviceClient(urlPage: url)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        afficherErreur()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        afficherErreur()
    }

    private func afficherErreur() {
        progressBar.isHidden = true
        refreshControl.endRefreshing()
        errorView.isHidden = false
    }

    // MARK: - Notifications push

    /**
     * Enregistre le téléphone de la cliente auprès du salon, en injectant du
     * JavaScript dans la page. Le script y lit l'e-mail du compte et l'envoie
     * avec l'identifiant OneSignal du téléphone.
     *
     * POURQUOI PAR JAVASCRIPT ET PAS PAR UNE REQUÊTE DIRECTE : le serveur
     * identifie le compte par la SESSION déjà ouverte (migration 076). Une
     * requête partie d'URLSession ne porte pas le cookie de session : le
     * serveur ne saurait pas qui appelle, et refuserait.
     *
     * La version précédente faisait justement cela, et y ajoutait « role=po » —
     * un paramètre supprimé côté serveur, car l'appli est réservée aux
     * clientes et c'est le serveur qui décide si un téléphone est celui du
     * salon, en comparant le numéro du compte à celui du profil. Cet appel a
     * été retiré : il ne pouvait pas aboutir. Android ne l'a jamais fait.
     *
     * Silencieux et non bloquant : en cas d'échec, l'appli fonctionne
     * normalement, simplement sans notifications.
     */
    private func enregistrerDeviceClient(urlPage: String) {
        guard let playerId = OneSignal.User.pushSubscription.id, !playerId.isEmpty,
              let page = URL(string: urlPage),
              let hote = page.host,
              let scheme = page.scheme
        else { return }

        let registerUrl = "\(scheme)://\(hote)/onesignal_register.php"
        let playerIdEchappe = playerId.replacingOccurrences(of: "'", with: "\\'")

        let js = """
        (function() {
            try {
                var el = document.getElementById('nf-client-email');
                if (!el) return;
                var email = (el.getAttribute('data-email') || '').trim();
                if (!email || email.indexOf('@') === -1) return;

                var xhr = new XMLHttpRequest();
                xhr.open('POST', '\(registerUrl)', true);
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                xhr.send('player_id=\(playerIdEchappe)&email=' + encodeURIComponent(email));
            } catch(e) {}
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
