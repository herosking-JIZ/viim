# 🔍 AUDIT BACKEND - ENDPOINTS GESTIONNAIRE

## 📊 RÉSUMÉ
- **Endpoints existants** : 9/10
- **Endpoints avec réponses conformes** : 5/10
- **Endpoints à corriger** : 4/10
- **Problème majeur** : `/auth/verify-sms` n'ajoute pas `parking_id`, `parking_nom`, `parking_adresse`

---

## ✅ ENDPOINTS EXISTANTS & STATUS

### **1. POST /auth/verify-sms** ❌ À CORRIGER
**Fichier** : `backend/src/controllers/authController.js` (ligne ~130)

**Problème** : Ne retourne PAS `parking_id`, `parking_nom`, `parking_adresse`

**Response actuelle** :
```json
{
  "user": {
    "id_utilisateur": "uuid",
    "keycloak_id": "uuid",
    "email": "...",
    "nom": "...",
    "prenom": "...",
    "numero_telephone": "...",
    "photo_profil": null,
    "roles": ["gestionnaire"],
    "auth_provider": "keycloak"
    // ❌ MANQUENT: parking_id, parking_nom, parking_adresse
  }
}
```

**Action requis** : Modifier authController pour ajouter les infos parking au user

---

### **2. GET /parkings/:parkingId/detail-parkeur** ⚠️ À ADAPTER
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 8)

**Status** : Endpoint existe mais réponse ne correspond pas au contrat

**Response actuelle** :
```json
{
  "success": true,
  "data": {
    "parking": { ...parking_object... },
    "capacite_dispo": 20,
    "vehicules_bon_etat": 15
  }
}
```

**Réponse attendue** (selon contrat) :
```json
{
  "success": true,
  "data": {
    "id_parking": "uuid",
    "nom": "BWT",
    "adresse": "CITE AZIMO",
    "capacite_totale": 50,
    "capacite_occupee": 12,
    "latitude": "12.4036681",
    "longitude": "-1.3696289",
    "ville": "Ouagadougou",
    "horaires": "24h/24 - 7j/7",
    "actif": true,
    "gestionnaire_info": { ... },
    "stats_jour": { ... }
  }
}
```

**Action requis** : Reformater la réponse pour correspondre au contrat

---

### **3. GET /parkings/:parkingId/vehicules** ⚠️ À ADAPTER
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 56)

**Status** : Endpoint existe mais structure légèrement différente

**Response actuelle** :
```json
{
  "success": true,
  "data": [
    {
      "id_vehicule": "uuid",
      "immatriculation": "AA-001-BF",
      "marque": "Toyota",
      "modele": "Corolla",
      "categorie": "SUV",
      "proprietaire_nom": "Jean Dupont",
      "statut": "actif",
      "etat": "bon_etat"
      // ❌ MANQUENT: couleur, date_arrivee, proprietaire object, besoin_maintenance
    }
  ]
}
```

**Action requis** : Ajouter les champs manquants et restructurer

---

### **4. GET /parkings/:parkingId/mouvements-parkeur** ⚠️ À ADAPTER
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 98)

**Status** : Endpoint existe, réponse très proche du contrat

**Response actuelle** :
```json
{
  "success": true,
  "data": [
    {
      "id_log": "uuid",
      "id_vehicule": "uuid",
      "immatriculation": "AA-001-BF",
      "id_parking": "uuid",
      "parkeur_nom": "Zacharie Compaoré",  // ⚠️ MAUVAIS NOM
      "type_mouvement": "entree",
      "etat_vehicule": "bon_etat",
      "date_mouvement": "...",
      "commentaire": "..."
      // ❌ MANQUENT: id_utilisateur, besoin_maintenance, gestionnaire object
    }
  ],
  "meta": { total, page, limit }
}
```

**Action requis** : 
- Renommer `parkeur_nom` → `gestionnaire.nom/prenom` (séparé)
- Ajouter `id_utilisateur`
- Ajouter `besoin_maintenance`
- Retourner `totalPages` au lieu de seulement `meta`

---

### **5. POST /parkings/:parkingId/entree** ✅ OK
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 152)

**Status** : ✅ Implémenté et conforme

**Response** : Conforme au contrat

---

### **6. POST /parkings/:parkingId/sortie** ✅ OK
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 213)

**Status** : ✅ Implémenté et conforme

**Response** : Conforme au contrat

---

### **7. GET /parkings/:parkingId/maintenance** ⚠️ À ADAPTER
**Fichier** : `backend/src/controllers/maintenanceController.js` (ligne 91)

**Status** : Endpoint existe, à vérifier la structure exacte

**Action requis** : Vérifier que la réponse retourne:
- `photos` array
- `gestionnaire` object
- `technicien` object ou null
- Structure paginée correcte

---

### **8. POST /parkings/:parkingId/maintenance** ⚠️ À ADAPTER
**Fichier** : `backend/src/controllers/maintenanceController.js` (ligne 8)

**Status** : Endpoint existe

**Response actuelle** :
```json
{
  "success": true,
  "message": "Demande de maintenance créée.",
  "data": {
    "id_maintenance": "uuid",
    "immatriculation": "AA-001-BF",
    "statut": "en_attente",
    "urgence": "normale"
  }
}
```

**Réponse attendue** (selon contrat) : Identique ✅

---

### **9. GET /parkings/:parkingId/maintenance/:maintenanceId** ✅ EXISTE
**Fichier** : `backend/src/controllers/maintenanceController.js`

**Status** : À vérifier la structure

---

### **10. PATCH /parkings/:parkingId/maintenance/:maintenanceId** ✅ EXISTE
**Fichier** : `backend/src/controllers/maintenanceController.js`

**Status** : À vérifier la structure

---

## 🎯 PRIORITÉS DE CORRECTION

### **PRIORITÉ 1 - CRITIQUE** (Bloque le fonctionnement)
1. ❌ **POST /auth/verify-sms** - Ajouter `parking_id`, `parking_nom`, `parking_adresse` au user
   - Impact : Sans ça, le gestionnaire voit "Aucun parking assigné"
   - Fichier : `backend/src/controllers/authController.js`
   - Effort : 15 minutes

2. ⚠️ **GET /parkings/:parkingId/detail-parkeur** - Reformater réponse
   - Impact : Dashboard vide
   - Fichier : `backend/src/controllers/parkeurController.js`
   - Effort : 30 minutes

---

### **PRIORITÉ 2 - HAUTE** (Affecte l'UX)
3. ⚠️ **GET /parkings/:parkingId/vehicules** - Ajouter champs manquants
   - Impact : Page Véhicules incomplète
   - Effort : 20 minutes

4. ⚠️ **GET /parkings/:parkingId/mouvements-parkeur** - Restructurer réponse
   - Impact : Historique pas conformes
   - Effort : 20 minutes

---

### **PRIORITÉ 3 - MOYENNE** (Polissage)
5. ⚠️ **GET /parkings/:parkingId/maintenance** - Vérifier structure complète
6. ⚠️ **GET /parkings/:parkingId/maintenance/:maintenanceId** - Vérifier structure
7. ⚠️ **PATCH /parkings/:parkingId/maintenance/:maintenanceId** - Vérifier structure

---

## 📝 VALIDATIONS À AJOUTER

Tous les endpoints doivent valider les payloads avec Zod. Vérifier les validations existantes dans:
`backend/src/validators/parkingValidation.js`

---

## ✨ ORDRE IMPLÉMENTATION RECOMMANDÉ

1. **POST /auth/verify-sms** ← Commencer ici (bloquant)
2. **GET /parkings/:parkingId/detail-parkeur**
3. **GET /parkings/:parkingId/vehicules**
4. **GET /parkings/:parkingId/mouvements-parkeur**
5. Vérifier les endpoints maintenance
6. Tester au complet

**Temps estimé** : 2-3 heures pour tout corriger proprement

---

## 🔐 SÉCURITÉ À VÉRIFIER

- [ ] Tous les endpoints gestionnaire vérifient `can('parking:lire')` ou `can('parking:gerer')`
- [ ] Vérifier que le gestionnaire n'a accès qu'à SON parking
- [ ] Vérifier qu'un gestionnaire ne peut pas modifier un parking auquel il n'est pas assigné
- [ ] Vérifier les permissions sur maintenance

---

## 📋 CHECKLIST FINALE

- [ ] AuthController : Ajouter parking_id au user
- [ ] ParkeurController.detailParking : Reformater réponse
- [ ] ParkeurController.vehiculesGares : Ajouter champs manquants
- [ ] ParkeurController.mouvementsParkeur : Restructurer réponse
- [ ] MaintenanceController : Vérifier structure complète
- [ ] Zod validations : Ajouter pour tous les payloads
- [ ] Tests : Tester chaque endpoint avec un gestionnaire
- [ ] Frontend : Tester que les pages s'affichent correctement
