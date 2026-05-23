# PARKER_INTERFACE_ANALYSIS.md

## A. Vue d’ensemble de l’interface

L’interface "Parkeur" (Gestionnaire de parking) de la plateforme N'DJIGI est un outil métier opérationnel. Son but est de permettre aux agents sur le terrain de gérer efficacement les flux (entrées/sorties) des véhicules, de surveiller la capacité du parking en temps réel, et de signaler rapidement les besoins en maintenance.

*   **Rôle métier :** Opération logistique et gestion de parc de véhicules.
*   **Utilisateur cible :** Parkeurs (agents de sécurité, gestionnaires de parc), souvent sur le terrain, nécessitant une saisie rapide et une lisibilité maximale en extérieur.
*   **Objectifs UX :** Rapidité d'action (flux d'entrée/sortie fluides), clarté des indicateurs (places disponibles, états), réduction des erreurs de saisie.
*   **Flux principal :** Accueil -> Dashboard de capacité -> Saisie d'une entrée/sortie -> (Optionnel) Signalement de maintenance.
*   **Cas d'usage :**
    *   Enregistrer l'entrée d'un chauffeur/propriétaire/passager avec l'état du véhicule.
    *   Enregistrer la sortie d'un véhicule.
    *   Vérifier le nombre de places disponibles.
    *   Rechercher un véhicule garé par sa plaque.
    *   Signaler un véhicule en panne ou nécessitant une intervention.

---

## B. Architecture des écrans

### 1. HomeParkeurScreen (Tableau de bord)
*   **Fonction métier :** Vue d'ensemble de la situation du parking et point d'accès rapide aux actions.
*   **Layout :**
    *   **AppBar :** Nom du parking centré, bouton de switch de rôle, badge de notifications (cliquable).
    *   **Body :** `RefreshIndicator` englobant un `SingleChildScrollView`.
    *   **Dashboard Capacité (`_ParkingDashboard`) :** Carte stylisée contenant 3 métriques (Capacité totale, Garés, Bon État) et une jauge de progression (`LinearProgressIndicator`) colorée dynamiquement (primaire si <90% rempli, rouge/danger si >90%).
    *   **Bouton d'action principal :** Bouton pleine largeur `NdjButton.primary` avec icône (sync_alt) pour "Enregistrer un Flux".
    *   **Section Véhicules garés :** Header avec titre et lien "Voir tout". Liste de `_VehiculeStatusTile` (limité à 5) ou un EmptyState (`_EmptyGares`).

### 2. ParkeurFluxScreen (Gestion des entrées/sorties)
*   **Fonction métier :** Saisie des mouvements de véhicules et consultation de l'historique récent.
*   **Layout :**
    *   **AppBar :** Titre, `TabBar` à 3 onglets (Entrée, Sortie, Historique).
    *   **Onglet Entrée :** Formulaire complexe.
        *   Section "Identité" : Nom (Text), Téléphone (Text, clavier phone), Rôle (Dropdown: Chauffeur, Propriétaire, Passager).
        *   Section "Véhicule" : Plaque (Text), Marque (Text).
        *   Section "État" : Sélecteur visuel sous forme de boutons radio personnalisés (Bon, En panne, Grave). Commentaire (TextArea).
        *   Section "Photos" : Liste horizontale (`ListView`) pour ajouter des preuves (Empty state = bouton d'ajout).
        *   Bouton de soumission `NdjButton.primary`.
        *   **Modale induite :** Si état != 'Bon', une `AlertDialog` propose de créer une demande de maintenance ("Plus tard" / "Oui, créer" -> redirection).
    *   **Onglet Sortie :**
        *   Recherche par plaque (`NdjTextField` avec icône loupe).
        *   État vide initial. Si plaque trouvée : Carte de récapitulatif `_buildRecapSortie` avec informations alignées à droite/gauche.
        *   Bouton de confirmation `NdjButton.primary`.
    *   **Onglet Historique :**
        *   Liste `ListView.separated`. Chaque item a une icône de direction (login vert/logout rouge), Plaque + Rôle, Personne + Date, et un badge d'état.

### 3. ParkeurMaintenanceScreen (Suivi et demande de maintenance)
*   **Fonction métier :** Consulter l'état des réparations en cours et signaler de nouvelles pannes.
*   **Layout :**
    *   **AppBar :** Titre "Suivi Maintenance".
    *   **Body :** Liste `ListView.builder` de `_MaintenanceTile` (ExpansionTile).
        *   *Tile :* Icone dynamique (couleur selon statut), Titre (plaque), Sous-titre (Type + Badge d'urgence). Badge de statut aligné à droite.
        *   *Tile Expanded :* Description complète + Timeline d'historique (`_HistoryStep` avec barre verticale de connexion).
    *   **FAB (Floating Action Button) :** Étendu, couleur primaire, pour "Nouvelle demande".
    *   **Modale (Bottom Sheet) `_NewMaintenanceForm` :** Formulaire de saisie qui remonte depuis le bas.
        *   Champs : Plaque, Type (Dropdown: Mécanique, Électricité, Carrosserie), Urgence (Dropdown: basse, normale, haute), Description (TextArea). Bouton "Envoyer".

### 4. ParkeurVehiculesScreen (Liste complète des véhicules)
*   **Fonction métier :** Recherche et liste exhaustive des véhicules actuellement dans le parking.
*   **Layout :**
    *   **AppBar :** Titre "Mes Véhicules".
    *   **Body :** Column.
        *   En-tête fixe : Barre de recherche (`NdjTextField`).
        *   Contenu : `ListView.builder` de `_VehiculeSearchTile`.
        *   *Tile :* Icone voiture, Plaque + Marque, Badge d'état + "Voir détails".
        *   Empty state si aucun résultat `_NoResults`.

---

## C. Analyse UI extrêmement précise

### Typographie
*   **Famille :** Google Fonts `Poppins`.
*   **Hiérarchie :**
    *   Titres AppBar : 17px, w700 (Bold), textPrimary.
    *   Métriques Dashboard : 20px, w800 (ExtraBold), textPrimary.
    *   Titres de section / Titres de Tile : 14-15px, w700/w800.
    *   Labels de formulaires : 14px, w500/w600, textSecondary (devient primary au focus).
    *   Texte standard / Sous-titres : 12-13px, régulier, textSecondary.
    *   Badges / Micro-copies : 9-11px, w700/w800.

### Couleurs
Déduites de `AppColors` (`lib/core/constants/colors.dart`) et de l'usage en inline :
*   **Primaire (primary) :** `#FFFF6B35` (Orange africain chaud). Utilisé pour les boutons principaux, les tabs actifs, la jauge < 90%.
*   **Secondaire (secondary) :** `#FF1A1A2E` (Bleu nuit profond). Utilisé pour l'AppBar de certains écrans (Flux).
*   **Accent (accent) :** `#FFFFD700` (Or). Utilisé pour l'indicateur d'onglet sur l'AppBar secondaire.
*   **Succès (success) :** `#FF4CAF50`. Utilisé pour les états "Bon", les icônes d'entrée.
*   **Danger / Erreur (danger) :** `#FFF44336` (Rouge). Utilisé pour la jauge > 90%, l'état "Grave", les urgences "haute", les icônes de sortie, les badges de notification.
*   **Warning (warning) :** `#FFFF9800` (Orange standard). Utilisé pour l'état "En panne", l'urgence "normale".
*   **Background (background) :** `#FFF5F5F5` (Gris très clair). Couleur de fond principale (`Scaffold`).
*   **Surface (surface) :** `#FFFFFFFF` (Blanc). Couleur de fond des cartes, des modales, de l'AppBar standard, des champs texte.
*   **TextPrimary :** `#FF1A1A2E` (Bleu nuit profond). Texte principal.
*   **TextSecondary :** `#FF757575` (Gris moyen). Texte secondaire, placeholders, labels non focus.
*   **Divider :** `#FFE0E0E0` (Gris clair). Bordures des champs, séparateurs, fond des placeholders vides.

*Note technique sur l'opacité :* De nombreux backgrounds d'icônes ou de badges utilisent la couleur de statut avec une opacité de 10% (`color.withValues(alpha: 0.1)`).

### Espacements
*   **Padding global de page :** 16px ou 20px (`EdgeInsets.all(16)` ou `20`).
*   **Gaps entre composants verticaux :** Généralement 12px, 20px ou 24px (via `SizedBox(height: X)`).
*   **Gaps horizontaux :** 8px ou 12px.
*   **Padding intérieur des cartes/tiles :** 12px ou 16px.
*   **Padding des boutons :** Hauteur fixe de 56px (`NdjButton`).

### Radius & ombres
*   **Border Radius Global :** Tendance très arrondie.
    *   Cartes principales (Dashboard) : `24px`.
    *   Boutons, TextFields, Tiles : `12px` ou `16px`.
    *   Badges : `4px`, `8px` ou `10px` (totalement arrondis `20px` pour certains états).
    *   Bottom Sheet : Top Left/Right `24px`.
*   **Ombres (Elevation) :**
    *   Utilisation subtile. Le Dashboard a un `BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: Offset(0, 8))`.
    *   Les boutons primaires ont une ombre colorée (couleur de fond à 35% d'opacité, blur 8, Y offset 4).
    *   Les listes utilisent souvent des bordures (`Border.all(color: AppColors.divider)`) au lieu d'ombres, donnant un aspect plus "flat/border" très moderne.

### Composants réutilisables clés
*   **`NdjButton` :** Bouton lourd, h=56px, arrondi 12px. Gère un état de chargement (`CircularProgressIndicator`). Variantes: primary, secondary, outline, danger.
*   **`NdjTextField` :** Champ texte rempli (Surface/Blanc), bordure grise, bordure primaire au focus. Le label "flotte" et devient primaire au focus.
*   **`NotifBadge` :** Icône de cloche avec une pastille rouge en haut à droite avec une animation d'apparition `elasticOut`.
*   **Tuiles de statut (Tiles) :** Pattern récurrent où une icône carrée avec des bords arrondis (background 10% opacité) est à gauche, le texte au milieu, et un badge de statut (background plein, texte blanc, ou background 10% + texte coloré) à droite.

---

## D. Responsive & adaptation web

La conception mobile est une liste de cartes empilées. Pour le web, il faut maximiser l'espace écran et adopter un layout de "Dashboard de gestion".

### Stratégie Layout Global
*   **Desktop ( > 1024px ) :**
    *   Remplacer le menu "Role Switcher" et la navigation par une **Sidebar latérale fixe** à gauche.
    *   La zone de contenu principale (droite) affiche les vues.
*   **Tablette ( 768px - 1024px ) :**
    *   Sidebar rétractable ou Bottom/Top Navigation compacte.
    *   Grille à 2 colonnes pour les formulaires.
*   **Mobile Web ( < 768px ) :**
    *   Garder la structure Flutter (1 colonne, empilement vertical).

### Recommandations par écran (Desktop)

*   **Home (Dashboard) :**
    *   Les 3 métriques (Capacité, Garés, Bon État) doivent être 3 cartes distinctes en ligne (`grid-cols-3`), au lieu d'une seule carte groupée.
    *   La jauge de capacité peut prendre la largeur totale sous les 3 cartes.
    *   La liste des véhicules garés peut occuper une grande colonne centrale, tandis que les actions rapides ("Enregistrer Flux") peuvent être des tuiles d'action dans une colonne latérale droite.
*   **Flux (Entrées/Sorties) :**
    *   L'interface à onglets (Tabs) fonctionne bien sur le web.
    *   Le formulaire d'entrée doit utiliser une grille. Ex: `Nom` et `Téléphone` sur la même ligne (50/50). `Plaque` et `Marque` sur une autre ligne.
    *   Les boutons radio d'état (Bon, Panne, Grave) peuvent être des cartes de sélection (Selectable Cards) horizontales.
*   **Maintenance :**
    *   Liste sur la gauche, avec les détails qui s'affichent dans un panneau de prévisualisation (Split pane) sur la droite au clic, au lieu d'un `ExpansionTile` qui pousse le contenu vers le bas.
    *   La création de demande (Bottom Sheet en mobile) doit devenir une **Modale (Dialog)** centrée sur Desktop, ou un tiroir latéral (Right Drawer).
*   **Véhicules :**
    *   Transformer la liste en un **Tableau de données (Data Grid / Table)**.
    *   Colonnes : Plaque, Marque, État, Actions.
    *   La barre de recherche reste en haut avec des filtres supplémentaires (par statut).

---

## E. Interactions & comportements dynamiques

*   **Rafraîchissement :** Sur le Dashboard, pull-to-refresh (`RefreshIndicator`). En web, cela peut être géré par un rafraîchissement automatique (SWR/React Query) ou un bouton d'actualisation explicite.
*   **États de chargement :**
    *   Squelettes (`_DashboardSkeleton`) au chargement initial du dashboard.
    *   Loaders circulaires (spinners) dans les boutons lors des soumissions (`isLoading` sur `NdjButton`).
    *   Indicateurs de progression centraux lors du chargement des listes.
*   **Flux d'entrée (Modale conditionnelle) :** Si l'agent enregistre une entrée et choisit un état autre que "Bon", une modale s'ouvre **immédiatement après le succès** pour lui demander s'il veut créer un ticket de maintenance, l'orientant vers l'onglet/écran maintenance s'il accepte.
*   **Filtrage :** Sur l'écran véhicules, filtrage local en temps réel au fur et à mesure de la frappe (`onChanged` du TextField).
*   **Animations :** Micro-interactions sur le bouton Notification (elasticOut) et le `NdjCard` (Scale down au clic). Transitions fluides de couleur sur les bordures des inputs au focus.

---

## F. Mapping Flutter → Web

| Flutter Composant / Concept | Équivalent React / Web Recommandé |
| :--- | :--- |
| `TabBar` / `TabBarView` | Composant de Tabs (ex: Radix UI Tabs, MUI Tabs) |
| `SingleChildScrollView` | Défilement CSS natif (`overflow-y: auto`) |
| `RefreshIndicator` | SWR, React Query (revalidation) + indicateur loading |
| `showModalBottomSheet` | `Dialog` ou `Drawer` (Radix UI, Shadcn UI) |
| `FutureBuilder` / `Riverpod`| Hooks React (`useQuery`, `useEffect` + State) |
| `ExpansionTile` | Composant `Accordion` (Radix UI) |
| `LinearProgressIndicator` | Composant `Progress` (HTML5 `<progress>` stylisé) |
| Snackbar (`ScaffoldMessenger`)| Système de Toast (ex: react-hot-toast, Sonner) |
| `BoxDecoration` avec alpha | `rgba()` ou `hsla()` ou Tailwind `bg-opacity-10` |

---

## G. Design System implicite

L'application suit une charte très moderne, "Flat Design 2.0" avec des touches de Soft UI.

*   **Philosophie UX :** Mobile-first, orienté "terrain". L'interface privilégie les gros boutons tactiles (56px) et les contrastes forts pour une lecture en extérieur (soleil).
*   **Cohérence visuelle :**
    *   **Bordures subtiles :** Très forte utilisation de bordures grises (`AppColors.divider`) pour délimiter les cartes, plutôt que des ombres, ce qui donne un rendu très net.
    *   **Système de Badges :** Chaque statut (Bon, Panne, Grave, Urgence) est toujours représenté par un duo "Background 10% opacité + Texte couleur pleine". Cela crée une signature visuelle douce mais claire.
    *   **Bords très arrondis :** Les radius de 12px à 24px dominent. Aucun angle vif.
*   **Densité UI :** Faible à moyenne. Les éléments respirent avec des paddings généreux (16-20px). L'information n'est pas surchargée.

---

## H. Données affichées

*   **Dashboard Parking :**
    *   `nb_places_total` (int)
    *   `nb_places_dispo` (int)
    *   `gares` (calculé : total - dispo)
    *   `bonEtat` (calculé ou API : véhicules sans maintenance)
*   **Formulaire Entrée :** `plaque`, `marque`, `personne` (nom), `tel`, `role` (Chauffeur/Prop/Passager), `etat` (Bon/Panne/Grave), `commentaire`, `photos` (Array).
*   **Formulaire Sortie :** Recherche par `plaque` -> Retourne récapitulatif (Plaque, Marque, Temps passé (ex: '2h 15min'), État de sortie).
*   **Historique Flux :** Liste d'objets : `type` ('entree'/'sortie'), `plaque`, `role`, `personne`, `date` (ISO DateTime), `etat`.
*   **Maintenance :** Liste d'objets : `plaque`, `type` (Mécanique/Élec/Carrosserie), `statut` (en_attente/confirmé/en_reparation/terminé/bon_etat), `urgence` (basse/normale/haute), `description`, `historique` (Array d'étapes : `date`, `commentaire`).
*   **Véhicules Garés :** Liste d'objets : `plaque`, `marque`, `etat`.

---

## I. Instructions de reconstruction Web (Pour Claude Code)

### Architecture Frontend Recommandée
*   **Framework :** Next.js (App Router) ou React (Vite).
*   **Stylisation :** Tailwind CSS. Le mapping des couleurs Flutter vers `tailwind.config.js` est crucial (utiliser la palette de la section C).
*   **Bibliothèque de composants :** Utiliser **Shadcn UI** ou **Radix UI** primitives pour implémenter rapidement les Accords (Maintenance), les Tabs (Flux), les Dialogs/Sheets (Nouvelle demande) et les Toasts.
*   **Gestion d'état / Fetching :** Utiliser **React Query** (ou SWR) pour répliquer le comportement du `FutureBuilder` et `RefreshIndicator` avec cache et revalidation.

### Découpage des Composants
1.  **Layout/Navigation :** Créer un `ParkeurLayout` avec une Sidebar (Desktop) et BottomNav (Mobile).
2.  **UI Core (`/components/ui/`) :**
    *   `Button` (reproduire les variantes primary, outline, avec le prop `isLoading`).
    *   `Input` (reproduire le label flottant ou un design équivalent propre, bordures focus primaires).
    *   `StatusBadge` : Composant essentiel qui prend un `status` et une `colorTheme` et gère le "bg à 10% d'opacité" avec Tailwind (ex: `bg-green-500/10 text-green-700`).
    *   `Card` : reproduire le border radius important (rounded-2xl) et les bordures grises.
3.  **Features (`/features/parkeur/`) :**
    *   `CapacityDashboard` : Le bloc des 3 métriques et la jauge.
    *   `FluxForm` : Le formulaire complexe d'entrée, gérant son état local.
    *   `MaintenanceList` : Tableau ou liste des interventions.

### Stratégie Responsive
*   Appliquer la classe `max-w-md mx-auto` sur les formulaires de création pour éviter qu'ils ne soient trop larges sur écran desktop.
*   Transformer les listes en tables CSS Grid sur les écrans `md:` et supérieurs.

---

## J. Prompts exploitables

### 1. Prompt Global pour Claude Code

> "Agis en tant qu'architecte Frontend et Expert React/Next.js avec TailwindCSS. Ton objectif est de reconstruire l'interface Web 'Parkeur' (Gestionnaire de parking) issue d'une application Flutter.
> 
> **Instructions :**
> 1. Initialise le projet ou le module avec la configuration Tailwind suivante :
>    - Primary: `#FFFF6B35`
>    - Secondary: `#FF1A1A2E`
>    - Success: `#FF4CAF50`
>    - Danger: `#FFF44336`
>    - Warning: `#FFFF9800`
>    - Background: `#FFF5F5F5`
>    - Surface: `#FFFFFFFF`
>    - Divider: `#FFE0E0E0`
> 2. Le style global doit être 'Flat 2.0', avec des angles très arrondis (`rounded-xl` à `rounded-3xl`), des bordures grises subtiles (`border-divider`) plutôt que des ombres profondes.
> 3. Implémente un composant `StatusBadge` générique qui utilise l'opacité à 10% pour le fond et la couleur pleine pour le texte (ex: `bg-green-500/10 text-green-500 font-bold`).
> 4. Crée 4 pages/vues principales :
>    - **Dashboard (`/parkeur`)** : Affiche 3 métriques clés (Capacité totale, Véhicules Garés, Véhicules en bon état), une barre de progression de la capacité (rouge si > 90%), et une liste des 5 derniers véhicules garés.
>    - **Flux (`/parkeur/flux`)** : Une vue avec 3 onglets (Tabs). L'onglet Entrée contient un formulaire (Plaque, Marque, Nom, Tél, Rôle, État via des tuiles sélectionnables). L'onglet Sortie permet de rechercher par plaque pour valider une sortie. L'onglet Historique liste les événements. Gère une logique modale : si une entrée est enregistrée avec un état autre que 'Bon', propose de créer un ticket de maintenance.
>    - **Maintenance (`/parkeur/maintenance`)** : Une liste accordéon des tickets. Inclut un bouton flottant ou principal pour ouvrir une Dialog de création de nouvelle demande.
>    - **Véhicules (`/parkeur/vehicules`)** : Une table ou grille avec recherche en temps réel listant tous les véhicules du parking.
> 
> Assure-toi que l'application est responsive : layout type Sidebar sur Desktop, layout type empilé sur Mobile. Utilise des icônes Lucide-react."

### 2. Prompt pour l'écran Dashboard (Spécifique)

> "Construis le composant `ParkeurDashboard` en React + Tailwind.
> Ce dashboard doit avoir une zone d'en-tête affichant le nom du parking.
> En dessous, crée un bloc 'Capacité' sous forme de carte (`rounded-2xl`, fond blanc, légère ombre). À l'intérieur, affiche 3 colonnes avec des icônes : Capacité (gris), Garés (orange), Bon état (vert).
> Sous ces chiffres, intègre une `ProgressBar`. Sa couleur de fond est grise. Sa valeur de remplissage est orange (`#FFFF6B35`), sauf si le ratio Garés/Capacité dépasse 90%, auquel cas elle devient rouge (`#FFF44336`).
> Ajoute un bouton pleine largeur 'Enregistrer un Flux' en dessous.
> Enfin, crée une section 'Véhicules récents' qui liste des lignes d'information (Plaque, Marque, et un badge d'état stylisé).
> Gère l'état de chargement (skeleton loaders)."
