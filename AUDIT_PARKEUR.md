# RAPPORT D'AUDIT — Module Parkeur (N'DJIGI)

**Date:** 2026-05-22  
**État:** PHASE 1 - AUDIT COMPLET  
**Spécification de référence:** `GESTIONNAIRE.MD` (PARKER_INTERFACE_ANALYSIS.md)

---

## A. État du Frontend existant

### A.1 Écrans actuellement implémentés

| Écran | Fichier | État | Conform. Spec | Notes |
|-------|---------|------|---------------|-------|
| **HomeParkeur** | `web/n-djigi/src/pages/parkeur/ParkeurDashboard.tsx` | ✅ Existe | ⚠️ Partiel | Implémenté pour web (tableau). Spec demande 4 écrans distincts, actuellement tout en 1 page. |
| **ParkeurFlux** | ❌ N'existe pas | ❌ Manquant | ❌ Non conforme | À créer : Tabs (Entrée/Sortie/Historique) avec formulaires. |
| **ParkeurMaintenance** | ❌ N'existe pas | ❌ Manquant | ❌ Non conforme | À créer : Liste avec ExpansionTile/Accordion, Timeline, FAB. |
| **ParkeurVehicules** | ❌ N'existe pas | ❌ Manquant | ❌ Non conforme | À créer : Table/Grille complète avec recherche. |

### A.2 Composants réutilisables détectés

**Existants et à réutiliser :**
- `KpiCard.tsx` — Carte KPI avec icône (✅ Réutilisable pour dashboard)
- `StatusBadge.tsx` — Badge de statut (✅ Réutilisable pour états)
- `AppLayout.tsx` — Layout principal (✅ À réutiliser)
- `Toaster.tsx` / `useToast.tsx` — Système de notifications (✅ À utiliser)
- `AppSidebar.tsx` — Navigation (✅ Existant)

**À créer (non existants) :**
- `NdjButton` avec variantes (primary, secondary, outline, danger) + `isLoading`
- `NdjTextField` avec label flottant et bordure focus primaire
- `NotifBadge` avec animation elasticOut
- `TimelineStep` pour l'historique de maintenance
- `MaintenanceTile` / `ExpansionTile` pour l'accordion
- `SelectionCard` pour les états (Bon/Panne/Grave)
- `ProgressBar` avec changement couleur à 90%

### A.3 Services et Types

**Services existants :**
```
parkeurService: {
  monParking(parkingId)
  vehiculesPresents(parkingId)
  mouvements(parkingId, params?)
  receptionVehicule(parkingId, payload)
  sortieVehicule(parkingId, payload)
  updateVehicule(vehiculeId, payload)
  declencherMaintenance(parkingId, vehiculeId, motif)
}
```

**Types existants :**
- `Parking` (id_parking, nom, adresse, ville, capacite_totale, capacite_occupee, horaires, actif, latitude, longitude)
- `VehiculeParking` (id_vehicule, immatriculation, marque, modele, categorie, proprietaire_nom, statut, etat)
- `MouvementParking` (id_log, id_vehicule, immatriculation, id_parking, parking_nom, parkeur_nom, type_mouvement, etat_vehicule, date_mouvement, commentaire)

**Types manquants (à créer) :**
- `MaintenanceRequest` (plaque, type, statut, urgence, description, historique)
- `MaintenanceHistoryStep` (date, commentaire, statut_ancien, statut_nouveau)
- `EntryFluxPayload` (nom, tel, role, plaque, marque, etat, commentaire, photos)

### A.4 Routage & Navigation

**État actuel :**
- Route `/parkeur` existe (affiche `ParkeurDashboard`)
- Pas de routes pour `/parkeur/flux`, `/parkeur/maintenance`, `/parkeur/vehicules`
- Pas de navigation entre les écrans Parkeur

**À créer :**
- Routes pour les 4 écrans Parkeur
- Navigation en Sidebar/Tabs vers ces écrans

---

## B. État du Schéma Prisma

### B.1 Modèles existants pertinents

```
✅ parking (id_parking, nom, adresse, ville, capacite_totale, capacite_occupee, latitude, longitude, horaires)
✅ vehicule (id_vehicule, id_proprietaire, id_parking, immatriculation, marque, modele, annee, nb_places, couleur, statut, photos, ...)
✅ journal_parking (id_log, id_vehicule, id_parking, id_utilisateur, type_mouvement*, etat_vehicule*, besoin_maintenance, date_mouvement)
✅ utilisateur (id_utilisateur, nom, prenom, email, numero_telephone, ...)
✅ gestionnaire_parking (id_gestionnaire, id_parking, date_prise_poste)
✅ notification (id_notification, id_utilisateur, type, titre, contenu, lu, date_creation)
❌ maintenance** (n'existe PAS — à créer)
```

*`type_mouvement` enum : entree, sortie, reprise, maintenance  
**Maintenance model manquant — impacte spec section H

### B.2 Analyse détaillée des données (section H de la spec)

#### **Données Dashboard Parking**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| `nb_places_total` | ✅ `parking.capacite_totale` | ✅ Oui | |
| `nb_places_dispo` | ✅ Calculé `capacite_totale - capacite_occupee` | ✅ Oui | |
| `gares` (calculé) | ✅ `capacite_occupee` | ✅ Oui | |
| `bonEtat` (véhicules sans maintenance) | ⚠️ Partiellement | ❌ Non | Nécessite jointure avec maintenance model (absent). |

#### **Données Formulaire Entrée**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| `plaque` | ✅ `vehicule.immatriculation` | ✅ Oui | |
| `marque` | ✅ `vehicule.marque` | ✅ Oui | |
| `personne` (nom) | ❌ N/A | ❌ Non | Pas de champ pour le **nom de la personne** (chauffeur/prop/passager). Actuellement stocké sur `utilisateur` mais pas lié au véhicule. |
| `tel` | ❌ N/A | ❌ Non | Pas de champ pour le **téléphone** de l'entrée. Actuellement sur `utilisateur.numero_telephone` mais pas associé au mouvement. |
| `role` | ❌ N/A | ❌ Non | Pas de champ pour **Chauffeur/Propriétaire/Passager**. Enum `type_mouvement` n'inclut pas ces rôles. |
| `etat` | ✅ `journal_parking.etat_vehicule` | ⚠️ Partiel | Enum existe (`bon`, `a_verifier`, `dommage`) mais spec veut (`Bon`, `En panne`, `Grave`). Aligned mais labels différents. |
| `commentaire` | ⚠️ `journal_parking.commentaire` → Champ inexistant, stocké autrement | ❌ Non | Pas de champ `commentaire` direct sur `journal_parking`. Besoin_maintenance est booléen. |
| `photos` | ❌ N/A | ❌ Non | **Aucun champ photo sur journal_parking**. À créer. |

#### **Données Formulaire Sortie**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| Recherche par `plaque` | ✅ `vehicule.immatriculation` | ✅ Oui | |
| Récap : Plaque, Marque | ✅ `vehicule.*` | ✅ Oui | |
| Temps passé (ex: '2h 15min') | ❌ N/A | ❌ Non | Besoin de calculer `now() - journal_parking.date_mouvement` (entrée précédente). |
| État de sortie | ✅ `journal_parking.etat_vehicule` | ✅ Oui | |

#### **Données Historique Flux**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| `type` ('entree'/'sortie') | ✅ `journal_parking.type_mouvement` | ✅ Oui | |
| `plaque` | ✅ `vehicule.immatriculation` | ✅ Oui | |
| `role` | ❌ N/A | ❌ Non | Pas stocké actuellement. Besoin dans formulaire entrée. |
| `personne` (nom) | ❌ N/A | ❌ Non | Pas stocké actuellement. Besoin dans formulaire entrée. |
| `date` (ISO DateTime) | ✅ `journal_parking.date_mouvement` | ✅ Oui | |
| `etat` | ✅ `journal_parking.etat_vehicule` | ✅ Oui | |

#### **Données Maintenance**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| `plaque` | ✅ `vehicule.immatriculation` | ✅ Oui | |
| `type` (Mécanique/Élec/Carrosserie) | ❌ Model maintenance n'existe pas | ❌ Non | **À créer : enum type_maintenance** |
| `statut` (en_attente/confirmé/en_reparation/terminé/bon_etat) | ❌ Model maintenance n'existe pas | ❌ Non | **À créer : enum maintenance_statut** |
| `urgence` (basse/normale/haute) | ❌ Model maintenance n'existe pas | ❌ Non | **À créer : enum maintenance_urgence** |
| `description` | ❌ Model maintenance n'existe pas | ❌ Non | **À créer : champ texte** |
| `historique` (Array : date, commentaire) | ❌ Model maintenance n'existe pas | ❌ Non | **À créer : model maintenance_step** |

#### **Données Véhicules Garés**

| Donnée | Existante | Suffisante | Notes |
|--------|-----------|-----------|-------|
| `plaque` | ✅ `vehicule.immatriculation` | ✅ Oui | |
| `marque` | ✅ `vehicule.marque` | ✅ Oui | |
| `etat` | ✅ `journal_parking.etat_vehicule` | ✅ Oui | |

### B.3 Modifications Prisma nécessaires

#### **Enums à ajouter :**

```prisma
// État du véhicule (harmoniser)
enum etat_vehicule {
  bon
  en_panne    // au lieu de "a_verifier" — BREAKING CHANGE
  grave       // au lieu de "dommage" — BREAKING CHANGE
}

// Type de maintenance
enum type_maintenance {
  mecanique
  electricite
  carrosserie
}

// Statut de maintenance
enum maintenance_statut {
  en_attente
  confirmee
  en_reparation
  terminee
  bon_etat
}

// Urgence
enum maintenance_urgence {
  basse
  normale
  haute
}

// Rôle dans un mouvement parking
enum role_mouvement {
  chauffeur
  proprietaire
  passager
}
```

#### **Modèles à créer :**

```prisma
// Demande de maintenance
model maintenance_request {
  id_maintenance          String                    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  id_vehicule             String                    @db.Uuid
  id_parking              String                    @db.Uuid
  id_gestionnaire         String                    @db.Uuid
  type                    type_maintenance
  statut                  maintenance_statut        @default(en_attente)
  urgence                 maintenance_urgence       @default(normale)
  description             String
  date_creation           DateTime                  @default(now()) @db.Timestamp(6)
  date_resolution         DateTime?                 @db.Timestamp(6)
  
  vehicule                vehicule                  @relation(fields: [id_vehicule], references: [id_vehicule], onDelete: NoAction, onUpdate: NoAction)
  parking                 parking                   @relation(fields: [id_parking], references: [id_parking], onDelete: NoAction, onUpdate: NoAction)
  gestionnaire            utilisateur               @relation(fields: [id_gestionnaire], references: [id_utilisateur], onDelete: NoAction, onUpdate: NoAction)
  historique              maintenance_step[]
  
  @@index([id_vehicule], map: "idx_maintenance_vehicule")
  @@index([id_parking], map: "idx_maintenance_parking")
  @@index([statut], map: "idx_maintenance_statut")
}

// Historique des étapes de maintenance
model maintenance_step {
  id_step                 String                    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  id_maintenance          String                    @db.Uuid
  statut_ancien           maintenance_statut?
  statut_nouveau          maintenance_statut
  commentaire             String?
  date_transition         DateTime                  @default(now()) @db.Timestamp(6)
  
  maintenance_request     maintenance_request       @relation(fields: [id_maintenance], references: [id_maintenance], onDelete: Cascade, onUpdate: NoAction)
  
  @@index([id_maintenance], map: "idx_maintenance_step_maintenance")
}

// Document photo pour la maintenance / mouvements
model mouvement_photo {
  id_photo                String                    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  id_mouvement            String?                   @db.Uuid // Si lié à un mouvement entrée/sortie
  id_maintenance          String?                   @db.Uuid // Si lié à une maintenance
  url_fichier             String
  fileKey                 String?                   @unique // YYYY-MM/{parkingId}/{uuid}{ext}
  date_ajout              DateTime                  @default(now()) @db.Timestamp(6)
  
  journal_parking         journal_parking?          @relation(fields: [id_mouvement], references: [id_log], onDelete: Cascade, onUpdate: NoAction)
  maintenance_request     maintenance_request?      @relation(fields: [id_maintenance], references: [id_maintenance], onDelete: Cascade, onUpdate: NoAction)
  
  @@index([id_mouvement], map: "idx_mouvement_photo_mouvement")
  @@index([id_maintenance], map: "idx_mouvement_photo_maintenance")
}
```

#### **Champs à ajouter aux modèles existants :**

```prisma
// Sur journal_parking :
model journal_parking {
  // ... existing
  commentaire             String?                   @db.Text        // Ajouter
  role_personne           role_mouvement?                           // Ajouter
  nom_personne            String?                   @db.VarChar(100) // Ajouter
  tel_personne            String?                   @db.VarChar(20)  // Ajouter
  mouvementPhotos         mouvement_photo[]                         // Relation
}

// Sur vehicule :
model vehicule {
  // ... existing
  maintenance_requests    maintenance_request[]     // Relation
}

// Sur parking :
model parking {
  // ... existing
  maintenance_requests    maintenance_request[]     // Relation
  mouvementPhotos         mouvement_photo[]         // Relation (optionnel)
}
```

### B.4 Résumé des modifications Prisma

| Action | Enums | Models | Champs ajoutés | Relations | Breaking Change |
|--------|-------|--------|----------------|-----------|-----------------|
| ✅ À faire | +4 (etat_vehicule✓, type_maintenance, maintenance_statut, maintenance_urgence, role_mouvement) | +3 (maintenance_request, maintenance_step, mouvement_photo) | journal_parking +3, vehicule +1, parking +1 | +6 | OUI (etat_vehicule: `a_verifier`→`en_panne`, `dommage`→`grave`) |

**⚠️ ATTENTION BREAKING CHANGE :**  
L'enum `etat_vehicule` actuellement = (bon, a_verifier, dommage)  
Spec demande = (bon, en_panne, grave)  
Solution : Migration avec mapping `a_verifier` → `en_panne`, `dommage` → `grave`

---

## C. État du Backend (API)

### C.1 Endpoints existants

| Endpoint | Méthode | État | Rôle requis | Notifier |
|----------|---------|------|-------------|----------|
| `GET /parkings` | GET | ✅ Existe | admin | |
| `GET /parkings/:id` | GET | ✅ Existe | admin | |
| `POST /parkings` | POST | ✅ Existe | admin | |
| `PATCH /parkings/:id` | PATCH | ✅ Existe | admin | |
| `GET /parkings/mouvements` | GET | ✅ Existe (global) | admin | ⚠️ Retourne mouvements globaux, pas par parking spécifique |
| `POST /parkings/:id/mouvement` | POST | ✅ Existe | parking:gerer | ⚠️ Prend `id_vehicule` mais pas le formulaire complet (nom, tel, role) |
| Gestionnaire routes | — | ✅ Existe | admin | |
| Incident routes | — | ✅ Existe | admin | |

### C.2 Endpoints manquants nécessaires

#### **Pour le Dashboard Parkeur**

```
❌ GET /parkings/:id/detail-parkeur
   Description: Retourne parking + stats (places, bon état)
   Payload: none
   Réponse: { parking, capacite_dispo, vehicules_bon_etat }
   
❌ GET /parkings/:id/vehicules
   Description: Liste des véhicules garés dans le parking
   Payload: none
   Réponse: VehiculeParking[]
   Permissions: parking:lire, gestionnaire
```

#### **Pour le Flux (Entrée/Sortie)**

```
❌ POST /parkings/:id/entree
   Description: Enregistrer une entrée avec formulaire complet
   Payload: {
     id_vehicule: string,
     nom_personne: string,
     tel_personne: string,
     role: role_mouvement (chauffeur|proprietaire|passager),
     etat_vehicule: etat_vehicule,
     commentaire?: string,
     photos?: File[] (multipart/form-data)
   }
   Réponse: { id_log, success }
   Permissions: parking:gerer
   
❌ POST /parkings/:id/sortie
   Description: Enregistrer une sortie avec formulaire
   Payload: {
     id_vehicule: string,
     etat_vehicule: etat_vehicule,
     commentaire?: string,
     photos?: File[]
   }
   Réponse: { id_log, temps_stationnement (secondes) }
   Permissions: parking:gerer
   
❌ GET /parkings/:id/mouvements
   Description: Historique des mouvements pour ce parking (avec pagination)
   Payload: { page?, limit?, search? }
   Réponse: { data: MouvementParking[], total, page, limit }
   Permissions: parking:lire
```

#### **Pour la Maintenance**

```
❌ POST /parkings/:id/maintenance
   Description: Créer une demande de maintenance
   Payload: {
     id_vehicule: string,
     type: type_maintenance,
     urgence: maintenance_urgence,
     description: string
   }
   Réponse: { id_maintenance, success }
   Permissions: parking:gerer
   
❌ GET /parkings/:id/maintenance
   Description: Lister les demandes de maintenance pour ce parking
   Payload: { statut?, page?, limit? }
   Réponse: { data: MaintenanceRequest[], total, page, limit }
   Permissions: parking:lire
   
❌ GET /parkings/:id/maintenance/:id_maint
   Description: Détails d'une demande + historique
   Payload: none
   Réponse: MaintenanceRequest + MaintenanceStep[]
   Permissions: parking:lire
   
❌ PATCH /parkings/:id/maintenance/:id_maint
   Description: Mettre à jour le statut d'une maintenance
   Payload: { statut: maintenance_statut, commentaire?: string }
   Réponse: { success }
   Permissions: parking:gerer
```

#### **Pour les Photos**

```
❌ POST /mouvements/:id/photos
   Description: Upload photo pour un mouvement
   Payload: multipart/form-data { file }
   Réponse: { id_photo, url_fichier }
   Permissions: parking:gerer
   
❌ POST /maintenance/:id/photos
   Description: Upload photo pour une maintenance
   Payload: multipart/form-data { file }
   Réponse: { id_photo, url_fichier }
   Permissions: parking:gerer
```

### C.3 Validations à créer/adapter

```javascript
// À créer ou adapter :
- parkingValidation.js : Ajouter schémas pour entree, sortie, maintenance
- maintenanceValidation.js : Créer nouveau
```

---

## D. Plan de refonte proposé

### **Phase 2.1 — Backend (Priorité HAUTE)**

1. **Prisma Migration**
   - Créer migration avec: enums (etat_vehicule✓, type_maintenance, maintenance_statut, maintenance_urgence, role_mouvement)
   - Créer models: maintenance_request, maintenance_step, mouvement_photo
   - Ajouter champs: journal_parking (commentaire, role_personne, nom_personne, tel_personne)
   - Mapper anciens enums vers nouveaux (a_verifier → en_panne, dommage → grave)
   - `prisma migrate dev --name "feat_parkeur_maintenance_photos"`

2. **Controllers & Routes — Parking**
   - Créer `parkeurController.js` avec méthodes:
     - `detailParking()` — GET /parkings/:id/detail-parkeur
     - `vehiculesGares()` — GET /parkings/:id/vehicules
     - `mouvementsParkeur()` — GET /parkings/:id/mouvements (filtré par parking)
     - `enregistrerEntree()` — POST /parkings/:id/entree (formulaire complet + photos)
     - `enregistrerSortie()` — POST /parkings/:id/sortie (+ calcul temps)
   - Adapter `parkingRoute.js` pour intégrer les nouveaux endpoints

3. **Controllers & Routes — Maintenance**
   - Créer `maintenanceController.js` avec méthodes:
     - `creerDemande()` — POST /parkings/:id/maintenance
     - `listerDemandes()` — GET /parkings/:id/maintenance
     - `obtenirDemande()` — GET /parkings/:id/maintenance/:id_maint
     - `mettreAJourStatut()` — PATCH /parkings/:id/maintenance/:id_maint
   - Créer `maintenanceRoute.js` et intégrer

4. **Gestion des Photos**
   - Implémente upload dans `documentService` ou créer `photoService`
   - Endpoints: `POST /mouvements/:id/photos`, `POST /maintenance/:id/photos`
   - Stocker FileKey au format `parking/{parkingId}/{date}/{uuid}{ext}`

5. **Validations**
   - Créer `maintenanceValidation.js`
   - Adapter `parkingValidation.js` pour entree, sortie, maintenance

6. **Tests**
   - Tester endpoints avec Postman/test suite
   - Vérifier migrations DB

---

### **Phase 2.2 — Frontend (Priorité HAUTE)**

#### **Étape 1 : Créer composants UI réutilisables**

```
web/n-djigi/src/components/
├── NdjButton.tsx          (primary, secondary, outline, danger + isLoading)
├── NdjTextField.tsx       (label flottant, focus primaire)
├── SelectionCard.tsx      (pour choix état : Bon/Panne/Grave)
├── TimelineStep.tsx       (pour historique maintenance)
├── ProgressBar.tsx        (avec changement couleur à 90%)
└── MaintenanceTile.tsx    (ExpansionTile avec icônes)
```

#### **Étape 2 : Typage + Services**

- Ajouter types `MaintenanceRequest`, `MaintenanceHistoryStep`, `EntryFluxPayload` dans `types/index.ts`
- Étendre `parkeurService` avec méthodes manquantes:
  - `detailParking()`, `vehiculesGares()`, `mouvementsParkeur()`
  - `creerMaintenance()`, `listerMaintenance()`, `obtenirMaintenance()`, `mettreAJourMaintenance()`
  - `uploadPhoto()`

#### **Étape 3 : Écrans Parkeur**

```
web/n-djigi/src/pages/parkeur/
├── ParkeurHome.tsx        (refonte du Dashboard actuel)
│   └── Cartes KPI + liste véhicules + action buttons
├── ParkeurFlux.tsx        (NEW - Tabs: Entrée/Sortie/Historique)
│   ├── FluxEntryForm.tsx     (formulaire entrée)
│   ├── FluxExitForm.tsx      (formulaire sortie)
│   └── FluxHistory.tsx       (liste historique)
├── ParkeurMaintenance.tsx  (NEW - Liste + Timeline)
│   ├── MaintenanceList.tsx   (liste avec expansion)
│   ├── MaintenanceDetail.tsx (détails + timeline)
│   └── MaintenanceForm.tsx   (formulaire création)
└── ParkeurVehicules.tsx    (NEW - Table complète)
    └── VehiculeGrid.tsx    (grille/table avec recherche)
```

#### **Étape 4 : Modale conditionnelle (Spec E)**

- Après entrée réussie avec état ≠ 'Bon' → Modale "Créer demande maintenance?"
- "Plus tard" → Fermer modale
- "Oui" → Rediriger vers ParkeurMaintenance (form pré-remplie)

#### **Étape 5 : Styling & Responsive**

- Appliquer palette de couleurs (section C spec): primary #FF6B35, secondary #1A1A2E, success #4CAF50, danger #F44336, warning #FF9800
- Typo Poppins, Radius 12-24px, Bordures divider
- Responsive: Desktop (Sidebar) → Mobile (Tabs/Stack)

#### **Étape 6 : États Loading/Empty/Error**

- Skeletons pour chargement dashboard
- EmptyState pour listes vides
- Toasts pour erreurs/succès

---

### **Phase 2.3 — Branchement Données Réelles**

- Chaque écran = appels API réels, **zéro données mockées**
- Gestion de cache/invalidation (React Query ou SWR si applicable)
- Pull-to-refresh sur dashboard (mock pour web, adapté à React)
- Filtrage temps réel sur recherches

---

## E. Estimation des Risques

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|-----------|
| Breaking change enum `etat_vehicule` | Haute | Moyen | Migration Prisma avec mapping clair. Tester anciens mouvements. |
| Endpoints manquants retardent frontend | Haute | Élevé | Implémenter backend d'abord (Phase 2.1). Utiliser mocks temporaires en dev. |
| Photos upload non implémenté | Haute | Moyen | Utiliser service existant (`documentService`) ou créer simple avec S3/local. |
| Permissions roles non alignés | Moyen | Moyen | Vérifier `can('parking:gerer')` sur tous endpoints nouveaux. Ajouter permission `parking:entree`, `parking:sortie` si nécessaire. |
| Spec vs Implémentation UI | Moyen | Moyen | Tester chaque écran contre 4 critères: layout spec, couleurs, interactions, responsive. |

---

## F. Points nécessitant validation utilisateur

1. **Enum `etat_vehicule` breaking change :** Accepter migration `a_verifier → en_panne`, `dommage → grave`? (Affecte historique)
2. **Qui crée demande maintenance ?** Le gestionnaire seul ou aussi le chauffeur/propriétaire?
3. **Photos obligatoires ou optionnelles?** Spec suggère optionnel ("optionnel" dans formulaire).
4. **Modale conditionnelle automatique :** Toujours pop après entrée état ≠ "Bon", ou configurable?
5. **Permissions :** Gestionnaire peut-il voir ALL parkings ou seulement le sien? (Actuellement: user.parking_id)

---

## G. Checklist Pré-Implémentation

- [ ] Validation de ce rapport d'audit
- [ ] Clarification des 5 points utilisateur (F)
- [ ] Approbation du plan Phase 2 (D)
- [ ] Setup environnement: Node, Prisma, npm packages si nécessaire
- [ ] Branche de travail créée (`feat/parkeur-refactoring`)
- [ ] Backup BD prod (si applicable)

---

## H. Prochaines étapes

1. **Utilisateur valide ce rapport** ← ⏸️ EN ATTENTE
2. Débuter Phase 2.1 (Backend)
3. Débuter Phase 2.2 (Frontend) en parallèle si possible
4. Tests E2E pour chaque écran vs spec
5. Performance & UX review

---

**FIN DU RAPPORT D'AUDIT**
