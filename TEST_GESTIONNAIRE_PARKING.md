# 🧪 TEST COMPLET - GESTIONNAIRE PARKING

**Date**: 2026-05-23  
**Status**: ✅ PRÊT POUR TEST

---

## 📋 RÉSUMÉ DES FIXES APPLIQUÉES

### Backend - Controller Fix
**Fichier**: `backend/src/controllers/gestionnaireController.js`

**Problèmes Identifiés & Fixes**:
1. ❌ `id_utilisateur` → ✅ `id_gestionnaire` (colonne correcte dans Prisma schema)
2. ❌ Filtre `actif: true` sur gestionnaire_parking → ✅ Supprimé (colonne n'existe pas)
3. ❌ Retour du champ `actif` → ✅ Supprimé (colonne n'existe pas dans parking table)

**Code Corrigé**:
```javascript
const gestionnaire = await prisma.gestionnaire_parking.findFirst({
  where: {
    id_gestionnaire: userId  // ✅ CORRECT
  },
  select: {
    id_gestionnaire: true,
    id_parking: true,
    parking: {
      select: {
        id_parking: true,
        nom: true,
        adresse: true,
        ville: true,
        capacite_totale: true,
        capacite_occupee: true
        // ✅ `actif` supprimé (n'existe pas)
      }
    }
  }
})
```

### Frontend - Service Type Fix
**Fichier**: `web/n-djigi/src/services/api.ts`

**Fix**: Suppression du champ `actif` des types de réponse (il n'existe pas dans le backend)

---

## 🔐 AUTHENTIFICATION DE TEST

**Utilisateur de Test**: Gestionnaire  
**Email**: `compaoreguetawendezacharie@gmail.com`  
**Parking Assigné**: **BWT** (id: `608da502-d5c6-40a4-a047-9dd276bdf9a2`)  
**Auth Provider**: Keycloak + Local password

---

## ✅ TEST PLAN - GESTIONNAIRE LOGIN FLOW

### **Étape 1: Lancer le Frontend**
```bash
# Terminal 1: Vérifier que le web container est en cours d'exécution
docker ps | grep ndjigi-web
# Accéder à: http://localhost:3000
```

### **Étape 2: Login avec Gestionnaire**
1. **URL**: http://localhost:3000/login
2. **Email**: `compaoreguetawendezacharie@gmail.com`
3. **Password**: `Heroskingjesuss100#`
4. **Cliquer**: "Se connecter"
5. **Attendre**: Prompt SMS (message "Vérifier SMS")

### **Étape 3: Vérifier SMS**
1. **URL**: http://localhost:3000/verify-sms
2. **Vérifier**: Page demande code SMS
3. **Code SMS**: Les codes de test sont disponibles dans les logs backend
   ```
   docker logs ndjigi-backend | grep -i "otp\|sms\|code" | tail -5
   ```
4. **Saisir code** et soumettre
5. **Redirection**: Devrait aller vers Dashboard (parkeur)

---

## 🎯 VÉRIFICATIONS CRITIQUES APRÈS LOGIN

### **Via DevTools > Console**

```javascript
// 1. Vérifier que user.parking_id existe
const { useAuth } = // Accès via composant
const { user } = useAuth()

console.log({
  id_utilisateur: user.id_utilisateur,
  nom: user.nom,
  roles: user.roles,
  parking_id: user.parking_id,      // ✅ Doit = '608da502-d5c6-40a4-a047-9dd276bdf9a2'
  parking_nom: user.parking_nom,    // ✅ Doit = 'BWT'
  parking_adresse: user.parking_adresse // ✅ Doit = 'CITE AZIMO'
})

// 2. Vérifier localStorage
const storedUser = JSON.parse(localStorage.getItem('ndjigi_user'))
console.log('localStorage user:', storedUser)
// parking_id, parking_nom, parking_adresse doivent être présents

// 3. Vérifier que le Bearer token existe
const token = localStorage.getItem('ndjigi_access_token')
console.log('Token length:', token ? token.length : 'MISSING')
```

### **Via Network Tab (DevTools > Network)**

1. **Filtrer par**: `/api/v1/gestionnaire/me/parking`
2. **Observer**:
   - ✅ Status: **200** (succès)
   - ✅ Request Headers contient: `Authorization: Bearer ...`
   - ✅ Response contient:
     ```json
     {
       "success": true,
       "message": "Parking du gestionnaire récupéré.",
       "data": {
         "id_parking": "608da502-d5c6-40a4-a047-9dd276bdf9a2",
         "nom": "BWT",
         "adresse": "CITE AZIMO",
         "ville": "Ouagadougou",
         "capacite_totale": 50,
         "capacite_occupee": 12
       }
     }
     ```

---

## 📱 TEST DES PAGES PARKEUR

### **Page 1: Dashboard (/)** 
**Attendu**: Titre du parking affiche "BWT"
```
✅ Parking: BWT
✅ Capacité: 50 places totales
✅ Occupée: 12 places
✅ Disponible: 38 places
```

### **Page 2: Flux (le premier lien parkeur)**
**Attendu**: Affiche les mouvements du parking BWT
```
✅ Tableau des mouvements (entrées/sorties)
✅ Filtre par parking fonctionne
✅ Liste n'est pas vide (au moins 1 mouvement)
```

### **Page 3: Maintenance (maintenance parkeur)**
**Attendu**: Affiche les demandes de maintenance pour BWT
```
✅ Tableau des demandes
✅ Filtre par parking
✅ Peut voir statuts (en_attente, confirmee, etc.)
```

### **Page 4: Véhicules (parkeur)**
**Attendu**: Affiche la liste des véhicules du parking BWT
```
✅ Tableau des véhicules
✅ Colonnes: immatriculation, marque, modèle, état
✅ Filtre/recherche fonctionne
```

---

## 🔴 ERROR SCENARIOS - À TESTER

### **Cas 1: Gestionnaire SANS parking assigné**
1. **Préparation**: Créer un gestionnaire sans parking
2. **Attendre**:
   - ✅ Erreur 404: "Aucun parking assigné"
   - ✅ Login réussit (ne bloque pas)
   - ✅ Pages montrent message "Aucun parking assigné"

### **Cas 2: Token expiré**
1. **Attendre**: ~1 heure
2. **Ou**: Supprimer le token du localStorage
3. **Attendre**:
   - ✅ Axios tente le refresh automatiquement
   - ✅ Si refresh échoue → redirection /login

### **Cas 3: Admin ou Passager login**
1. **Vérifier**: Les pages admin/passager n'appellent PAS `/gestionnaire/me/parking`
2. **Résultat**: ✅ Zéro impact sur les autres rôles

---

## 🗂️ FICHIERS IMPLIQUÉS (6 au total)

### **Backend (3 fichiers)**
- [x] `backend/src/controllers/gestionnaireController.js` - getMyParking() method (FIXED)
- [x] `backend/src/routes/gestionnaireRoute.js` - GET /me/parking route
- [x] `backend/src/routes/index.js` - Route registration (line 69)

### **Frontend (3 fichiers)**
- [x] `web/n-djigi/src/types/index.ts` - AuthUser interface (parking_id, parking_nom, parking_adresse)
- [x] `web/n-djigi/src/contexts/AuthContext.tsx` - loadGestionnaireParking() (auto-called after verifySms)
- [x] `web/n-djigi/src/services/api.ts` - gestionnaireService.getMyParking() (FIXED)

---

## 📊 API ENDPOINT FINAL

```
GET /api/v1/gestionnaire/me/parking
─────────────────────────────────────

Authentication:     Required (Bearer token)
Authorization:      Any authenticated user (404 if not gestionnaire)
Rate Limit:         Via global API limits
Timeout:            5s

Query Parameters:   None
Request Body:       None

Response (200):
{
  "success": true,
  "message": "Parking du gestionnaire récupéré.",
  "data": {
    "id_parking": "uuid",
    "nom": "BWT",
    "adresse": "CITE AZIMO",
    "ville": "Ouagadougou",
    "capacite_totale": 50,
    "capacite_occupee": 12
  },
  "errors": null
}

Error (401):
{
  "success": false,
  "message": "Token manquant. Connectez-vous.",
  "data": null,
  "errors": null
}

Error (404):
{
  "success": false,
  "message": "Aucun parking assigné à ce gestionnaire.",
  "data": null,
  "errors": { "code": "NO_PARKING_ASSIGNED" }
}

Error (500):
{
  "success": false,
  "message": "Erreur serveur lors de la récupération du parking.",
  "data": null,
  "errors": null
}
```

---

## 🚀 COMMANDES UTILES POUR DEBUG

```bash
# 1. Voir les logs du backend en temps réel
docker logs -f ndjigi-backend

# 2. Vérifier que le container est sain
docker ps | grep ndjigi-backend

# 3. Relancer le backend proprement
docker restart ndjigi-backend

# 4. Voir les bases de données
docker exec ndjigi-postgres psql -U ndjigi_user -d ndjigi_db

# 5. Requête SQL - vérifier le gestionnaire
docker exec ndjigi-postgres psql -U ndjigi_user -d ndjigi_db -c \
  "SELECT u.id_utilisateur, u.email, gp.id_parking, p.nom 
   FROM utilisateur u 
   LEFT JOIN gestionnaire_parking gp ON u.id_utilisateur = gp.id_gestionnaire 
   LEFT JOIN parking p ON gp.id_parking = p.id_parking 
   WHERE u.email='compaoreguetawendezacharie@gmail.com';"
```

---

## ✨ CHECKLIST FINALE

### Backend
- [x] Controller méthode implémentée (getMyParking)
- [x] Colonne correcte (id_gestionnaire, pas id_utilisateur)
- [x] Champs non-existants supprimés (actif)
- [x] Route enregistrée (/gestionnaire/me/parking)
- [x] Authentification requise (Bearer token)
- [x] Gestion d'erreurs complète (401, 404, 500)
- [x] Réponse JSON valide
- [x] Zéro breaking changes

### Frontend
- [x] Types TypeScript mis à jour
- [x] AuthContext charge le parking après SMS
- [x] Service API implémenté
- [x] localStorage persiste les données
- [x] Mode démo supporté
- [x] Gestion d'erreurs (ne bloque pas login)
- [x] Pas d'appels pour non-gestionnaires

### Intégration
- [x] Bearer token passé correctement
- [x] Response format aligné
- [x] Pas de champs supplémentaires
- [x] Pas de dépendances manquantes

---

## 📝 NOTES IMPORTANTES

1. **Pas de champ `actif`** : Le parking n'a pas de colonne `actif` en base de données. Seul le gestionnaire peut voir ses parkings (via FK dans gestionnaire_parking).

2. **Keycloak Auth** : L'utilisateur est authentifié via Keycloak + Local password hash. Le Bearer token vient de l'endpoint /auth/verify-sms après 2FA.

3. **Timing du Chargement** : setTimeout(..., 100ms) ensures localStorage tokens are saved before calling the API.

4. **Graceful Degradation** : Si l'API échoue, le login réussit quand même. Les pages affichent "Aucun parking" plutôt que crasher.

5. **Autres Rôles** : Admin, Passager, Chauffeur, Propriétaire ne sont pas affectés (zéro changements).

---

## 🎯 RÉSULTAT ATTENDU

Après login du gestionnaire :
✅ User.parking_id = '608da502-d5c6-40a4-a047-9dd276bdf9a2'
✅ User.parking_nom = 'BWT'
✅ User.parking_adresse = 'CITE AZIMO'
✅ Dashboard affiche les infos du parking
✅ Flux, Maintenance, Véhicules fonctionnent
✅ localStorage contient les données parking
✅ Network tab montre GET /gestionnaire/me/parking → 200

**STATUS**: 🚀 **PRÊT À TESTER EN PRODUCTION**
