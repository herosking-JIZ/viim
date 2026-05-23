# 🛠️ FEUILLE DE ROUTE - IMPLÉMENTATION GESTIONNAIRE

## 📌 OBJECTIF
Implémenter les endpoints backend pour que le gestionnaire ait accès à:
- ✅ Dashboard avec infos parking
- ✅ Flux Entrée/Sortie  
- ✅ Liste Véhicules
- ✅ Maintenance

**Pas de breaking changes** - Tous les endpoints existants restent fonctionnels

---

## 🎬 PHASE 1 - AUTHENTIFICATION (30 min)

### **Tâche 1.1 : Modifier POST /auth/verify-sms**
**Fichier** : `backend/src/controllers/authController.js`

**Code actuel** (ligne ~130) :
```javascript
// Retourne user SANS parking_id
const user = {
  id_utilisateur: utilisateur.id_utilisateur,
  email: utilisateur.email,
  nom: utilisateur.nom,
  prenom: utilisateur.prenom,
  // ... reste du code
}
```

**Code attendu** :
```javascript
// Après décodage JWT, récupérer le parking assigné
const gestionnaire = null;
if (userRoles.includes('ndjigi-gestionnaire')) {
  gestionnaire = await prisma.gestionnaire_parking.findFirst({
    where: { id_utilisateur: utilisateur.id_utilisateur },
    include: { parking: { select: { id_parking: true, nom: true, adresse: true } } }
  });
}

const user = {
  id_utilisateur: utilisateur.id_utilisateur,
  email: utilisateur.email,
  nom: utilisateur.nom,
  prenom: utilisateur.prenom,
  numero_telephone: utilisateur.numero_telephone,
  photo_profil: utilisateur.photo_profil,
  roles: userRoles,
  auth_provider: 'keycloak',
  // ✅ NOUVEAU
  parking_id: gestionnaire?.parking?.id_parking || null,
  parking_nom: gestionnaire?.parking?.nom || null,
  parking_adresse: gestionnaire?.parking?.adresse || null
}
```

**Avant** : `POST /auth/verify-sms` retourne user sans parking
**Après** : User contient `parking_id`, `parking_nom`, `parking_adresse`

---

## 🎯 PHASE 2 - ENDPOINTS PARKEUR (90 min)

### **Tâche 2.1 : GET /parkings/:parkingId/detail-parkeur**
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 8)

**Problème actuel** : Réponse retourne `parking` object complet + stats séparées

**Action** : Reformater pour retourner exactement selon le contrat

```javascript
// ✅ CORRECTION
async detailParking(req, res) {
  const { parkingId } = req.params;
  
  const parking = await prisma.parking.findUnique({
    where: { id_parking: parkingId },
    include: {
      gestionnaire_parking: {
        where: { actif: true },
        include: {
          utilisateur: {
            select: { nom: true, prenom: true, email: true, numero_telephone: true }
          }
        },
        take: 1
      }
    }
  });

  if (!parking) {
    return res.status(404).json({ success: false, message: 'Parking introuvable' });
  }

  // Calculer stats du jour
  const aujourd_hui = new Date();
  aujourd_hui.setHours(0, 0, 0, 0);
  
  const [mouvements, stats] = await Promise.all([
    prisma.journal_parking.groupBy({
      by: ['type_mouvement'],
      where: {
        id_parking: parkingId,
        date_mouvement: { gte: aujourd_hui }
      },
      _count: true
    }),
    prisma.vehicule.groupBy({
      by: ['etat_parking'],
      where: { id_parking: parkingId, supprime_le: null },
      _count: true
    })
  ]);

  const mouvements_entree = mouvements.find(m => m.type_mouvement === 'entree')?._count || 0;
  const mouvements_sortie = mouvements.find(m => m.type_mouvement === 'sortie')?._count || 0;

  return res.status(200).json({
    success: true,
    message: 'Détails du parking',
    data: {
      id_parking: parking.id_parking,
      nom: parking.nom,
      adresse: parking.adresse,
      capacite_totale: parking.capacite_totale,
      capacite_occupee: parking.capacite_occupee,
      latitude: parking.latitude,
      longitude: parking.longitude,
      ville: parking.ville,
      horaires: parking.horaires,
      actif: parking.actif,
      gestionnaire_info: parking.gestionnaire_parking[0] ? {
        id_gestionnaire: parking.gestionnaire_parking[0].id_gestionnaire,
        nom: parking.gestionnaire_parking[0].utilisateur.nom,
        prenom: parking.gestionnaire_parking[0].utilisateur.prenom,
        email: parking.gestionnaire_parking[0].utilisateur.email,
        numero_telephone: parking.gestionnaire_parking[0].utilisateur.numero_telephone,
        date_prise_poste: parking.gestionnaire_parking[0].date_prise_poste
      } : null,
      stats_jour: {
        mouvements_entree,
        mouvements_sortie,
        vehicules_bon_etat: stats.find(s => s.etat_parking === 'bon_etat')?._count || 0,
        vehicules_besoin_maintenance: stats.find(s => s.etat_parking === 'besoin_maintenance')?._count || 0,
        vehicules_en_maintenance: stats.find(s => s.etat_parking === 'en_maintenance')?._count || 0,
        vehicules_retires: stats.find(s => s.etat_parking === 'retire')?._count || 0
      }
    }
  });
}
```

---

### **Tâche 2.2 : GET /parkings/:parkingId/vehicules**
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 56)

**Problème** : Manquent `couleur`, `date_arrivee`, `proprietaire` object séparé

```javascript
// ✅ CORRECTION
async vehiculesGares(req, res) {
  const { parkingId } = req.params;
  const { etat, search, page = 1, limit = 50 } = req.query;

  const where = {
    id_parking: parkingId,
    supprime_le: null
  };

  if (etat) {
    where.etat_parking = etat;
  }

  if (search) {
    where.immatriculation = { contains: search.toUpperCase(), mode: 'insensitive' };
  }

  const skip = (parseInt(page) - 1) * parseInt(limit);

  const [vehicules, total] = await Promise.all([
    prisma.vehicule.findMany({
      where,
      skip,
      take: parseInt(limit),
      include: {
        proprietaire: {
          include: {
            utilisateur: { select: { id_utilisateur: true, nom: true, prenom: true, email: true } }
          }
        },
        journal_parking: {
          orderBy: { date_mouvement: 'desc' },
          take: 1,
          select: {
            date_mouvement: true,
            etat_vehicule: true,
            besoin_maintenance: true,
            type_mouvement: true
          }
        }
      }
    }),
    prisma.vehicule.count({ where })
  ]);

  const data = vehicules.map(v => ({
    id_vehicule: v.id_vehicule,
    immatriculation: v.immatriculation,
    marque: v.marque,
    modele: v.modele,
    couleur: v.couleur, // ✅ NOUVEAU
    etat_vehicule: v.journal_parking[0]?.etat_vehicule || 'bon_etat',
    besoin_maintenance: v.journal_parking[0]?.besoin_maintenance || false,
    date_arrivee: v.journal_parking[0]?.date_mouvement || v.date_creation, // ✅ NOUVEAU
    proprietaire: { // ✅ STRUCTURE SEPAREE
      id_utilisateur: v.proprietaire.utilisateur.id_utilisateur,
      nom: v.proprietaire.utilisateur.nom,
      prenom: v.proprietaire.utilisateur.prenom,
      email: v.proprietaire.utilisateur.email
    }
  }));

  return res.status(200).json({
    success: true,
    message: 'Véhicules du parking',
    data: {
      data,
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(total / parseInt(limit))
    }
  });
}
```

---

### **Tâche 2.3 : GET /parkings/:parkingId/mouvements-parkeur**
**Fichier** : `backend/src/controllers/parkeurController.js` (ligne 98)

**Problème** : `parkeur_nom` au lieu de structure `gestionnaire` séparée + manquent champs

```javascript
// ✅ CORRECTION
async mouvementsParkeur(req, res) {
  const { parkingId } = req.params;
  const { page = 1, limit = 20, search, type_mouvement } = req.query;

  const skip = (parseInt(page) - 1) * parseInt(limit);
  const where = { id_parking: parkingId };

  if (type_mouvement) {
    where.type_mouvement = type_mouvement;
  }

  if (search?.trim()) {
    where.vehicule = {
      immatriculation: { contains: search, mode: 'insensitive' }
    };
  }

  const [mouvements, total] = await Promise.all([
    prisma.journal_parking.findMany({
      where,
      orderBy: { date_mouvement: 'desc' },
      skip,
      take: parseInt(limit),
      include: {
        vehicule: { select: { immatriculation: true } },
        utilisateur: { select: { nom: true, prenom: true } }
      }
    }),
    prisma.journal_parking.count({ where })
  ]);

  const data = mouvements.map(m => ({
    id_log: m.id_log,
    id_vehicule: m.id_vehicule,
    id_parking: m.id_parking,
    id_utilisateur: m.id_utilisateur, // ✅ NOUVEAU
    immatriculation: m.vehicule.immatriculation,
    type_mouvement: m.type_mouvement,
    etat_vehicule: m.etat_vehicule,
    besoin_maintenance: m.besoin_maintenance, // ✅ NOUVEAU
    commentaire: m.commentaire,
    date_mouvement: m.date_mouvement,
    gestionnaire: { // ✅ NOUVEAU (structure séparée)
      nom: m.utilisateur.nom,
      prenom: m.utilisateur.prenom
    }
  }));

  return res.status(200).json({
    success: true,
    message: 'Mouvements récupérés',
    data: {
      data,
      total,
      page: parseInt(page),
      limit: parseInt(limit),
      totalPages: Math.ceil(total / parseInt(limit))
    }
  });
}
```

---

## 🔧 PHASE 3 - MAINTENANCE (60 min)

### **Tâche 3.1 : Vérifier GET /parkings/:parkingId/maintenance**
**Fichier** : `backend/src/controllers/maintenanceController.js` (ligne 91)

**À vérifier** : Structure contient `photos`, `gestionnaire`, `technicien`

---

### **Tâche 3.2 : Vérifier PATCH /parkings/:parkingId/maintenance/:maintenanceId**

**À vérifier** : Retourne `id_maintenance`, `statut`, `date_maj`

---

## ✅ PHASE 4 - VALIDATION ZOD (30 min)

Tous les payloads doivent être validés. Vérifier:

**Fichier** : `backend/src/validators/parkingValidation.js`

Ajouter si manquant:
```javascript
const detailParkeurSchema = z.object({ /* ... */ });
const vehiculesGaresSchema = z.object({ /* ... */ });
const mouvementsParkeurSchema = z.object({ /* ... */ });
```

---

## 📝 PHASE 5 - FRONTEND (60 min)

### **Tâche 5.1 : Mettre à jour AuthContext**
**Fichier** : `web/n-djigi/src/contexts/AuthContext.tsx`

```typescript
interface User {
  id_utilisateur: string;
  email: string;
  nom: string;
  prenom: string;
  roles: string[];
  parking_id?: string;      // ✅ NOUVEAU
  parking_nom?: string;     // ✅ NOUVEAU
  parking_adresse?: string; // ✅ NOUVEAU
}
```

### **Tâche 5.2 : Implémenter ManagerDashboard**
**Fichier** : `web/n-djigi/src/pages/manager/ManagerDashboard.tsx`

Faire appels à:
- `parkeurService.detailParking(user?.parking_id)`
- Afficher les stats du parking

### **Tâche 5.3 : Tester les pages**
- [ ] ParkeurFlux → Affiche véhicules + historique
- [ ] ParkeurMaintenance → Affiche demandes maintenance
- [ ] ParkeurVehicules → Affiche tous les véhicules
- [ ] ManagerDashboard → Affiche infos parking

---

## 📊 TEMPS ESTIMÉ PAR PHASE

| Phase | Tâche | Effort | Statut |
|-------|-------|--------|--------|
| 1 | Auth verify-sms | 15 min | ⏳ À FAIRE |
| 2.1 | detailParking | 30 min | ⏳ À FAIRE |
| 2.2 | vehiculesGares | 20 min | ⏳ À FAIRE |
| 2.3 | mouvementsParkeur | 20 min | ⏳ À FAIRE |
| 3.1 | maintenance GET | 15 min | ⏳ À VÉRIFIER |
| 3.2 | maintenance PATCH | 15 min | ⏳ À VÉRIFIER |
| 4 | Validations Zod | 30 min | ⏳ À FAIRE |
| 5.1 | AuthContext | 15 min | ⏳ À FAIRE |
| 5.2 | ManagerDashboard | 45 min | ⏳ À FAIRE |
| 5.3 | Tests | 30 min | ⏳ À FAIRE |

**TOTAL** : ~3 heures de travail

---

## 🚀 COMMENÇONS PAR

**Ordre recommandé** :
1. ✅ Phase 1 - Authentification (bloquant)
2. ✅ Phase 2 - Endpoints parkeur
3. ✅ Phase 3 - Vérifier maintenance
4. ✅ Phase 4 - Validations
5. ✅ Phase 5 - Frontend

---

## ✨ CHECKLIST D'IMPLÉMENTATION

### Backend
- [ ] POST /auth/verify-sms - Ajouter parking_id
- [ ] GET /parkings/:id/detail-parkeur - Reformater
- [ ] GET /parkings/:id/vehicules - Ajouter champs
- [ ] GET /parkings/:id/mouvements-parkeur - Restructurer
- [ ] Vérifier maintenance endpoints
- [ ] Ajouter validations Zod
- [ ] Tester chaque endpoint avec curl/Postman

### Frontend
- [ ] AuthContext - Ajouter parking_id
- [ ] ManagerDashboard - Implémenter
- [ ] Tester les 4 pages gestionnaire
- [ ] Vérifier que les données s'affichent

### Sécurité
- [ ] Vérifier permissions (can:parking:lire, can:parking:gerer)
- [ ] Vérifier qu'un gestionnaire ne voit que son parking
- [ ] Vérifier qu'on ne peut pas modifier un autre parking

---

## 📞 QUESTIONS À CLARIFIER

1. Le champ `couleur` existe-t-il dans la table `vehicule` ?
2. Le champ `etat_parking` est-il le bon nom ?
3. La table `gestionnaire_parking` a-t-elle le bon schéma ?
4. Les permissions `can:parking:lire` et `can:parking:gerer` sont-elles correctes pour gestionnaire ?

---

## 🎯 LIVRABLE FINAL

✅ Gestionnaire se connecte
✅ Voit son parking assigné
✅ Accède à Dashboard, Flux, Maintenance, Véhicules
✅ Toutes les pages s'affichent avec données réelles
✅ Zéro breaking changes sur les endpoints existants
