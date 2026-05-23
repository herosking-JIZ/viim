# 📋 CONTRAT API - ENDPOINTS GESTIONNAIRE

## 🎯 RÉSUMÉ
Le frontend énumère ses besoins. Tous les endpoints doivent retourner la structure exacte définie ici.

---

## ✅ 1. AUTHENTIFICATION & RÉCUPÉRATION USER

### **POST /auth/login**
Connexion + retour parking info

**Request:**
```json
{
  "email": "gestionnaire@example.com",
  "password": "SecurePassword123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Code OTP envoyé par SMS",
  "data": {
    "requires_2fa": true,
    "login_token": "uuid",
    "phone_masked": "+2265***0894",
    "mot_de_passe_temporaire": false
  }
}
```

---

### **POST /auth/verify-sms**
Vérifie OTP + retourne tokens + **user avec parking_id**

**Request:**
```json
{
  "login_token": "uuid",
  "sms_code": "123456"
}
```

**Response (200) - ⭐ CRITIQUEMENT IMPORTANT:**
```json
{
  "success": true,
  "message": "SMS vérifié",
  "data": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_jwt",
    "expires_in": 300,
    "token_type": "Bearer",
    "user": {
      "id_utilisateur": "uuid",
      "keycloak_id": "uuid",
      "email": "gestionnaire@example.com",
      "nom": "Zacharie",
      "prenom": "Compaoré",
      "numero_telephone": "+22657190894",
      "photo_profil": null,
      "roles": ["gestionnaire"],
      "auth_provider": "keycloak",
      "parking_id": "uuid",           // ✅ NOUVEAU - ID du parking assigné
      "parking_nom": "BWT",            // ✅ NOUVEAU - Nom du parking
      "parking_adresse": "CITE AZIMO"  // ✅ NOUVEAU - Adresse du parking
    }
  }
}
```

**Validation Zod:**
```typescript
const GestionnaireUserSchema = z.object({
  id_utilisateur: z.string().uuid(),
  email: z.string().email(),
  nom: z.string().min(1),
  prenom: z.string().min(1),
  numero_telephone: z.string(),
  roles: z.array(z.string()),
  parking_id: z.string().uuid().describe("UUID du parking assigné"),
  parking_nom: z.string().min(1).describe("Nom du parking"),
  parking_adresse: z.string().min(1).describe("Adresse du parking"),
})
```

---

## 🅿️ 2. INFORMATIONS PARKING

### **GET /parkings/:parking_id/detail-parkeur**
Récupère les détails complets du parking pour le gestionnaire

**Query Params:** Aucun

**Response (200):**
```json
{
  "success": true,
  "message": "Détails du parking",
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
    "gestionnaire_info": {
      "id_gestionnaire": "uuid",
      "nom": "Compaoré",
      "prenom": "Zacharie",
      "email": "gestionnaire@example.com",
      "numero_telephone": "+22657190894",
      "date_prise_poste": "2026-05-22T00:00:00.000Z"
    },
    "stats_jour": {
      "mouvements_entree": 5,
      "mouvements_sortie": 3,
      "vehicules_bon_etat": 12,
      "vehicules_besoin_maintenance": 2,
      "vehicules_en_maintenance": 1,
      "vehicules_retires": 0
    }
  }
}
```

**Validation Zod:**
```typescript
const DetailParkeurSchema = z.object({
  id_parking: z.string().uuid(),
  nom: z.string(),
  adresse: z.string(),
  capacite_totale: z.number().int().positive(),
  capacite_occupee: z.number().int().nonnegative(),
  latitude: z.string(),
  longitude: z.string(),
  ville: z.string(),
  horaires: z.string(),
  actif: z.boolean(),
  gestionnaire_info: z.object({
    id_gestionnaire: z.string().uuid(),
    nom: z.string(),
    prenom: z.string(),
    email: z.string().email(),
    numero_telephone: z.string(),
    date_prise_poste: z.string().datetime()
  }),
  stats_jour: z.object({
    mouvements_entree: z.number().int().nonnegative(),
    mouvements_sortie: z.number().int().nonnegative(),
    vehicules_bon_etat: z.number().int().nonnegative(),
    vehicules_besoin_maintenance: z.number().int().nonnegative(),
    vehicules_en_maintenance: z.number().int().nonnegative(),
    vehicules_retires: z.number().int().nonnegative(),
  })
})
```

---

## 🚗 3. VÉHICULES

### **GET /parkings/:parking_id/vehicules**
Liste tous les véhicules garés dans le parking

**Query Params:**
- `etat` (optional): `bon_etat | besoin_maintenance | en_maintenance | retire`
- `search` (optional): Filtre par immatriculation
- `page` (optional): Default 1
- `limit` (optional): Default 50

**Response (200):**
```json
{
  "success": true,
  "message": "Véhicules du parking",
  "data": [
    {
      "id_vehicule": "uuid",
      "immatriculation": "AA-001-BF",
      "marque": "Toyota",
      "modele": "Corolla",
      "couleur": "Blanc",
      "etat_vehicule": "bon_etat",
      "besoin_maintenance": false,
      "date_arrivee": "2026-05-22T10:30:00.000Z",
      "proprietaire": {
        "id_utilisateur": "uuid",
        "nom": "Dupont",
        "prenom": "Jean",
        "email": "jean@example.com"
      }
    }
  ]
}
```

**Validation Zod:**
```typescript
const VehiculeGareSchema = z.object({
  id_vehicule: z.string().uuid(),
  immatriculation: z.string().regex(/^[A-Z]{2}-\d{3}-[A-Z]{2}$/),
  marque: z.string(),
  modele: z.string(),
  couleur: z.string(),
  etat_vehicule: z.enum(['bon_etat', 'besoin_maintenance', 'en_maintenance', 'retire']),
  besoin_maintenance: z.boolean(),
  date_arrivee: z.string().datetime(),
  proprietaire: z.object({
    id_utilisateur: z.string().uuid(),
    nom: z.string(),
    prenom: z.string(),
    email: z.string().email()
  })
})
```

---

## 📝 4. MOUVEMENTS (Entrées/Sorties)

### **GET /parkings/:parking_id/mouvements-parkeur**
Historique des mouvements (entrées/sorties) avec pagination

**Query Params:**
- `page` (optional): Default 1
- `limit` (optional): Default 20
- `search` (optional): Filtre par immatriculation
- `type_mouvement` (optional): `entree | sortie`

**Response (200):**
```json
{
  "success": true,
  "message": "Mouvements récupérés",
  "data": {
    "data": [
      {
        "id_log": "uuid",
        "id_vehicule": "uuid",
        "id_parking": "uuid",
        "id_utilisateur": "uuid",
        "immatriculation": "AA-001-BF",
        "type_mouvement": "entree",
        "etat_vehicule": "bon_etat",
        "besoin_maintenance": false,
        "commentaire": "Entrée normale",
        "date_mouvement": "2026-05-22T10:30:00.000Z",
        "gestionnaire": {
          "nom": "Compaoré",
          "prenom": "Zacharie"
        }
      }
    ],
    "total": 150,
    "page": 1,
    "limit": 20,
    "totalPages": 8
  }
}
```

**Validation Zod:**
```typescript
const MouvementParkeurSchema = z.object({
  id_log: z.string().uuid(),
  id_vehicule: z.string().uuid(),
  id_parking: z.string().uuid(),
  id_utilisateur: z.string().uuid(),
  immatriculation: z.string(),
  type_mouvement: z.enum(['entree', 'sortie']),
  etat_vehicule: z.enum(['bon_etat', 'besoin_maintenance', 'en_maintenance', 'retire']),
  besoin_maintenance: z.boolean(),
  commentaire: z.string().nullable(),
  date_mouvement: z.string().datetime(),
  gestionnaire: z.object({
    nom: z.string(),
    prenom: z.string()
  })
})
```

---

### **POST /parkings/:parking_id/entree**
Enregistre une entrée de véhicule

**Request:**
```json
{
  "id_vehicule": "uuid",
  "id_utilisateur": "uuid",
  "etat_vehicule": "bon_etat",
  "commentaire": "Commentaire optionnel"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Entrée enregistrée",
  "data": {
    "id_log": "uuid",
    "immatriculation": "AA-001-BF",
    "type_mouvement": "entree",
    "date_mouvement": "2026-05-22T10:30:00.000Z"
  }
}
```

**Validation Zod:**
```typescript
const EntreePayloadSchema = z.object({
  id_vehicule: z.string().uuid(),
  id_utilisateur: z.string().uuid(),
  etat_vehicule: z.enum(['bon_etat', 'besoin_maintenance', 'en_maintenance', 'retire']),
  commentaire: z.string().optional()
})
```

---

### **POST /parkings/:parking_id/sortie**
Enregistre une sortie de véhicule

**Request:**
```json
{
  "id_vehicule": "uuid",
  "id_utilisateur": "uuid",
  "etat_vehicule": "bon_etat",
  "commentaire": "Pas de dommage"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Sortie enregistrée",
  "data": {
    "id_log": "uuid",
    "immatriculation": "AA-001-BF",
    "type_mouvement": "sortie",
    "date_mouvement": "2026-05-22T14:45:00.000Z"
  }
}
```

---

## 🔧 5. MAINTENANCE

### **GET /parkings/:parking_id/maintenance**
Liste les demandes de maintenance avec filtres

**Query Params:**
- `page` (optional): Default 1
- `limit` (optional): Default 20
- `statut` (optional): `en_attente | en_cours | resolu | rejete`
- `urgence` (optional): `basse | normale | haute | critique`
- `search` (optional): Filtre par immatriculation

**Response (200):**
```json
{
  "success": true,
  "message": "Demandes de maintenance",
  "data": {
    "data": [
      {
        "id_maintenance": "uuid",
        "id_vehicule": "uuid",
        "immatriculation": "AA-001-BF",
        "type": "mecanique",
        "urgence": "haute",
        "description": "Pneu crevé",
        "statut": "en_cours",
        "date_creation": "2026-05-22T09:00:00.000Z",
        "date_resolution": null,
        "gestionnaire": {
          "nom": "Compaoré",
          "prenom": "Zacharie"
        },
        "technicien": null,
        "photos": []
      }
    ],
    "total": 15,
    "page": 1,
    "limit": 20,
    "totalPages": 1
  }
}
```

**Validation Zod:**
```typescript
const MaintenanceSchema = z.object({
  id_maintenance: z.string().uuid(),
  id_vehicule: z.string().uuid(),
  immatriculation: z.string(),
  type: z.enum(['mecanique', 'electrique', 'carrosserie', 'interieur', 'autre']),
  urgence: z.enum(['basse', 'normale', 'haute', 'critique']),
  description: z.string().min(10),
  statut: z.enum(['en_attente', 'en_cours', 'resolu', 'rejete']),
  date_creation: z.string().datetime(),
  date_resolution: z.string().datetime().nullable(),
  gestionnaire: z.object({
    nom: z.string(),
    prenom: z.string()
  }),
  technicien: z.object({
    nom: z.string(),
    prenom: z.string()
  }).nullable(),
  photos: z.array(z.object({
    id_photo: z.string().uuid(),
    url: z.string().url()
  }))
})
```

---

### **POST /parkings/:parking_id/maintenance**
Crée une nouvelle demande de maintenance

**Request:**
```json
{
  "id_vehicule": "uuid",
  "type": "mecanique",
  "urgence": "haute",
  "description": "Pneu crevé, moteur fait du bruit"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Demande de maintenance créée",
  "data": {
    "id_maintenance": "uuid",
    "immatriculation": "AA-001-BF",
    "statut": "en_attente",
    "date_creation": "2026-05-22T09:00:00.000Z"
  }
}
```

**Validation Zod:**
```typescript
const CreerMaintenancePayloadSchema = z.object({
  id_vehicule: z.string().uuid(),
  type: z.enum(['mecanique', 'electrique', 'carrosserie', 'interieur', 'autre']),
  urgence: z.enum(['basse', 'normale', 'haute', 'critique']).default('normale'),
  description: z.string().min(10).max(1000)
})
```

---

### **PATCH /parkings/:parking_id/maintenance/:maintenance_id**
Met à jour le statut d'une maintenance

**Request:**
```json
{
  "statut": "en_cours",
  "commentaire": "Réparation commencée"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Maintenance mise à jour",
  "data": {
    "id_maintenance": "uuid",
    "statut": "en_cours",
    "date_maj": "2026-05-22T10:00:00.000Z"
  }
}
```

---

## 📊 RÉSUMÉ DES ENDPOINTS

| Méthode | Endpoint | Auth | Rôle | Implémenté? |
|---------|----------|------|------|-------------|
| POST | `/auth/login` | Non | Public | ✅ |
| POST | `/auth/verify-sms` | Non | Public | ✅ |
| GET | `/parkings/:id/detail-parkeur` | Oui | gestionnaire | ❌ **À FAIRE** |
| GET | `/parkings/:id/vehicules` | Oui | gestionnaire | ❌ **À FAIRE** |
| GET | `/parkings/:id/mouvements-parkeur` | Oui | gestionnaire | ❌ **À FAIRE** |
| POST | `/parkings/:id/entree` | Oui | gestionnaire | ❌ **À FAIRE** |
| POST | `/parkings/:id/sortie` | Oui | gestionnaire | ❌ **À FAIRE** |
| GET | `/parkings/:id/maintenance` | Oui | gestionnaire | ❌ **À FAIRE** |
| POST | `/parkings/:id/maintenance` | Oui | gestionnaire | ❌ **À FAIRE** |
| PATCH | `/parkings/:id/maintenance/:mid` | Oui | gestionnaire | ❌ **À FAIRE** |

---

## 🚨 CHANGEMENTS CRITIQUES

### **1. AuthController - POST /auth/verify-sms**
Ajouter `parking_id`, `parking_nom`, `parking_adresse` au user retourné

### **2. Créer 9 nouveaux endpoints** 
Voir la liste ci-dessus (endpoints avec ❌)

### **3. Ajouter validations Zod**
Pour tous les payloads et réponses

### **4. Frontend AuthContext**
Mettre à jour le type `User` pour inclure `parking_id`, `parking_nom`, `parking_adresse`

---

## ✨ NOTES
- Tous les endpoints gestionnaire **DOIVENT** vérifier que l'utilisateur est bien gestionnaire
- Tous les endpoints parking **DOIVENT** vérifier que le gestionnaire a accès à ce parking
- Pas de breaking changes sur les endpoints existants (Admin, Finance, etc.)
