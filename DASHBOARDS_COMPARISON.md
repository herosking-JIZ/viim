# 🎯 Comparaison des 3 Dashboards - N'DJIGI

## 📋 Vue d'ensemble

Il existe **3 dashboards** différents selon le rôle de l'utilisateur:

| Rôle | Fichier | État | Affichage |
|------|---------|------|-----------|
| **Admin** | `pages/admin/Dashboard.tsx` | ✅ Complet | Statistiques globales |
| **Gestionnaire (Manager)** | `pages/manager/ManagerDashboard.tsx` | ⚠️ Placeholder | Profil utilisateur |
| **Parkeur (Propriétaire parking)** | `pages/parkeur/ParkeurDashboard.tsx` | ✅ Complet | Gestion parking |

---

## 1️⃣ ADMIN DASHBOARD
📁 `web/n-djigi/src/pages/admin/Dashboard.tsx`

### 📊 Structure et données

#### État local
```typescript
const [kpis, setKpis] = useState<AdminKpis | null>(null)
const [coursesSemaine, setCoursesSemaine] = useState<ChartDataPoint[]>([])
const [evolution, setEvolution] = useState<ChartDataPoint[]>([])
const [paiements, setPaiements] = useState<{ name: string; value: number }[]>([])
const [topChauffeurs, setTopChauffeurs] = useState<TopChauffeur[]>([])
const [loading, setLoading] = useState(true)
```

#### Appels API
```typescript
const [k, cs, ev, pm, tc] = await Promise.all([
  dashboardService.kpis(),              // → AdminKpis
  dashboardService.coursesSemaine(),    // → ChartDataPoint[]
  dashboardService.evolutionMensuelle(), // → ChartDataPoint[]
  dashboardService.moyensPaiement(),    // → { name, value }[]
  dashboardService.topChauffeurs(),     // → TopChauffeur[]
])
```

#### Affichage (6 éléments)

| Élément | Type | Données | Affichage |
|---------|------|---------|-----------|
| KPI Utilisateurs | Card | `kpis.total_utilisateurs` | "1284" |
| KPI Courses | Card | `kpis.courses_aujourd_hui` | "93" |
| KPI Commissions | Card | `formatFCFA(kpis.revenus_commission_jour)` | "48 750 XOF" |
| KPI Satisfaction | Card | `kpis.satisfaction_moyenne / 5` | "4.6 / 5" |
| Chart Courses/jour | BarChart | `coursesSemaine[]` | Graphique |
| Chart Évolution | AreaChart | `evolution[]` | Graphique |
| Pie Paiements | PieChart | `paiements[]` | Graphique circulaire |
| Top Chauffeurs | List | `topChauffeurs[]` | Ranked list 1-5 |

### 🔄 Flux de données

```
Admin accède /dashboard
    ↓
Dashboard.tsx monte → useEffect
    ↓
Promise.all([5 appels dashboardService])
    ↓
api.get() avec Authorization Bearer
    ↓
Backend retourne { success, data, errors }
    ↓
extractData() unwrap
    ↓
setKpis(), setCoursesSemaine(), etc.
    ↓
Component re-render
    ↓
Affichage KPI Cards + 3 Graphiques + Top 5
```

### 📌 Endpoints utilisés

```
GET /api/v1/dashboard/kpis
GET /api/v1/dashboard/courses-semaine
GET /api/v1/dashboard/evolution-mensuelle
GET /api/v1/dashboard/moyens-paiement
GET /api/v1/dashboard/top-chauffeurs
```

---

## 2️⃣ MANAGER DASHBOARD
📁 `web/n-djigi/src/pages/manager/ManagerDashboard.tsx`

### ⚠️ État actuel: PLACEHOLDER

```typescript
export default function ManagerDashboard() {
  const { user } = useAuth()

  return (
    <div className="space-y-6">
      <h1>Tableau de bord Gestionnaire</h1>
      <p>Bienvenue, {user?.prenom} {user?.nom}</p>
      
      {/* ⚠️ Page en construction */}
      <AlertCircle />
      <p>Le dashboard gestionnaire est en cours de développement.</p>
      
      {/* 3 cartes d'info simples */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <Card title="Status" value="Actif" />
        <Card title="Rôle" value="Gestionnaire" />
        <Card title="Email" value={user?.email} />
      </div>
    </div>
  )
}
```

### 🎯 À implémenter

Le manager dashboard devrait afficher:

#### Option 1: Vue synthétique du gestionnaire
```typescript
// État à ajouter
const [stats, setStats] = useState({
  utilisateurs_geres: 0,      // Nombre utilisateurs gérés
  commissions_dues: 0,         // Total dû
  documents_en_attente: 0,     // Documents à valider
  tickets_ouverts: 0,          // Support actif
  paiements_recents: [],       // Derniers paiements
})

// Appels API à ajouter
utilisateursService.list({ role: 'gestionnaire' })
supportService.list({ statut: 'ouvert' })
financesService.kpis()
```

#### Option 2: Voir aussi ParkeurDashboard
Le gestionnaire est responsable d'un parking, donc pourrait avoir besoin d'une vue parkeur.

---

## 3️⃣ PARKEUR DASHBOARD
📁 `web/n-djigi/src/pages/parkeur/ParkeurDashboard.tsx`

### 🎨 Structure complète

#### État local
```typescript
const { user } = useAuth()
const { toast } = useToast()

const [parking, setParking] = useState<Parking | null>(null)
const [vehicules, setVehicules] = useState<VehiculeParking[]>([])
const [mouvements, setMouvements] = useState<MouvementParking[]>([])
const [loading, setLoading] = useState(true)
const [search, setSearch] = useState('')
const [searchMvt, setSearchMvt] = useState('')
const [modal, setModal] = useState<ModalType>(null)
const [selectedVehicule, setSelectedVehicule] = useState<VehiculeParking | null>(null)
const [form, setForm] = useState<FormData>(DEFAULT_FORM)
const [submitting, setSubmitting] = useState(false)

const parkingId = user?.parking_id
```

#### Appels API
```typescript
const load = useCallback(async () => {
  if (!parkingId) return
  setLoading(true)
  try {
    const [pk, veh, mvt] = await Promise.all([
      parkeurService.monParking(parkingId),        // → Parking
      parkeurService.vehiculesPresents(parkingId), // → VehiculeParking[]
      parkeurService.mouvements(parkingId, {...}), // → MouvementParking[]
    ])
    setParking(pk)
    setVehicules(veh)
    setMouvements(mvt)
  } catch (err) {
    toast({ title: 'Erreur de chargement', variant: 'destructive' })
  } finally {
    setLoading(false)
  }
}, [parkingId, searchMvt])

useEffect(() => { load() }, [load])
```

#### Affichage (5 éléments)

| Élément | Type | Données | Affichage |
|---------|------|---------|-----------|
| En-tête | Text | `parking.nom, adresse, ville, horaires` | "Parking Central Ouaga" |
| KPI Véhicules | Card | `parking.capacite_occupee / capacite_totale` | "54 / 80" |
| KPI Mouvements | Card | `mouvementsAujourdhui` | "3" |
| KPI Horaires | Card | `parking.horaires` | "6h-23h" |
| Boutons Action | Buttons | - | "Réception" & "Sortie" |
| Table Véhicules | Table | `filteredVehicules[]` | 6 colonnes |
| Table Mouvements | Table | `mouvements[]` | 5 colonnes |
| Modals | Dialogs | 4 types | Réception/Sortie/Edit/Maintenance |

### 🔄 Flux de données

```
Parkeur accède /parkeur
    ↓
ParkeurDashboard monte → useCallback + useEffect
    ↓
load() déclenché
    ↓
Vérifie parkingId (sinon: "Aucun parking assigné")
    ↓
Promise.all([3 appels parkeurService])
    ↓
setParking(), setVehicules(), setMouvements()
    ↓
Component affiche:
  - En-tête avec parking info
  - 3 KPI cards
  - Table véhicules présents
  - Table historique mouvements
    ↓
User peut:
  - Cliquer "Réception" → Modal form
  - Cliquer "Sortie" → Modal form
  - Cliquer Crayon → Modal edit
  - Cliquer Clé anglaise → Modal maintenance
    ↓
Au submit: parkeurService.receptionVehicule(), sortieVehicule(), etc.
    ↓
load() rappelé → Données actualisées
```

### 📌 Endpoints utilisés

```
GET /api/v1/parkings/{parkingId}
GET /api/v1/parkings/{parkingId}/vehicules
GET /api/v1/parkings/{parkingId}/mouvements

POST /api/v1/parkings/{parkingId}/entree       (réception)
POST /api/v1/parkings/{parkingId}/sortie       (sortie)
PATCH /api/v1/vehicules/{vehiculeId}           (edit)
POST /api/v1/parkings/{parkingId}/maintenance  (maintenance)
```

### 🎯 Fonctionnalités

#### 1. Réception véhicule (Modal)
```typescript
const handleSubmit = async () => {
  await parkeurService.receptionVehicule(parkingId, {
    immatriculation: form.immatriculation,
    etat_vehicule: form.etat_vehicule,      // bon, a_verifier, dommage
    commentaire: form.commentaire,
  })
}
```

#### 2. Sortie véhicule (Modal)
```typescript
await parkeurService.sortieVehicule(parkingId, {
  immatriculation: form.immatriculation,
  etat_vehicule: form.etat_vehicule,
  commentaire: form.commentaire,
})
```

#### 3. Modifier véhicule (Modal)
```typescript
await parkeurService.updateVehicule(selectedVehicule.id_vehicule, {
  immatriculation: form.immatriculation,
  marque: form.marque,
  modele: form.modele,
  categorie: form.categorie,
})
```

#### 4. Maintenance véhicule (Modal)
```typescript
await parkeurService.declencherMaintenance(parkingId, selectedVehicule.id_vehicule, form.motif)
```

---

## 📊 TABLEAU COMPARATIF COMPLET

| Critère | Admin | Manager | Parkeur |
|---------|-------|---------|---------|
| **Fichier** | `Dashboard.tsx` | `ManagerDashboard.tsx` | `ParkeurDashboard.tsx` |
| **État** | ✅ Complet | ⚠️ Placeholder | ✅ Complet |
| **Rôle** | admin | gestionnaire | proprietaire |
| **Nbre d'API calls** | 5 | 0 (placeholder) | 3+ |
| **KPI Cards** | 4 | 3 (info seulement) | 3 (parking) |
| **Graphiques** | 3 (Bar, Area, Pie) | 0 | 0 |
| **Tables** | 1 (Top 5) | 0 | 2 (Véhicules, Mouvements) |
| **Modals** | 0 | 0 | 4 (Réception, Sortie, Edit, Maintenance) |
| **Search/Filter** | ❌ | ❌ | ✅ (2x) |
| **Réactivité données** | 1x au montage | - | Réload après action |
| **Tokens JWT** | ✅ Bearer | ✅ Bearer | ✅ Bearer |
| **Gestion erreurs** | ✅ try/catch | N/A | ✅ try/catch + toast |

---

## 🔗 FLOW PARALLÈLE DES 3 DASHBOARDS

```
User Log In → AuthContext
    ↓
Token stored in localStorage
    ↓
Router redirects by role:
    ├─ role='admin' → /dashboard (Admin Dashboard)
    ├─ role='gestionnaire' → /manager (Manager Dashboard) ⚠️ Placeholder
    └─ role='proprietaire' → /parkeur (Parkeur Dashboard)
    ↓
Dashboard mount → useEffect/useCallback
    ↓
Each dashboard:
  ├─ Verify role/parking_id
  ├─ Fetch data with dashboardService/parkeurService
  ├─ Intercept Authorization: Bearer <token>
  ├─ Update state (setState)
  └─ Render UI
    ↓
User interacts
    ├─ Admin: Voir statistiques
    ├─ Manager: Voir profil ⚠️
    └─ Parkeur: Gérer véhicules/mouvements
```

---

## 🚀 PROCHAINES ÉTAPES

### Pour Manager Dashboard

Le dashboard gestionnaire est actuellement un placeholder. Il devrait:

1. **Option A:** Afficher un summary de la gestion
   ```typescript
   const [stats, setStats] = useState({
     utilisateurs_total: 0,
     documents_attente: 0,
     tickets_ouverts: 0,
     commission_due: 0,
   })
   
   useEffect(() => {
     Promise.all([
       utilisateursService.list(),
       documentsService.listEnAttente(),
       supportService.list({ statut: 'ouvert' }),
       financesService.kpis(),
     ]).then(([users, docs, tickets, fin]) => {
       setStats({
         utilisateurs_total: users.total,
         documents_attente: docs.length,
         tickets_ouverts: tickets.total,
         commission_due: fin.commissions_totales,
       })
     })
   }, [])
   ```

2. **Option B:** Rediriger vers parkeur si parking_id existe
   ```typescript
   if (user?.parking_id) {
     return <ParkeurDashboard />
   }
   ```

3. **Option C:** Afficher listes paginées
   - Utilisateurs gérés
   - Documents à valider
   - Tickets support
   - Transactions récentes

---

## 📋 RÉSUMÉ

### ✅ Dashboards Actifs
1. **Admin Dashboard** - Complet avec statistiques et graphiques
2. **Parkeur Dashboard** - Complet avec gestion parking

### ⚠️ À Compléter
1. **Manager Dashboard** - Placeholder, à implémenter

### 🎯 Points clés
- Admin voit la **vue globale** de la plateforme
- Parkeur gère son **parking spécifique** et ses véhicules
- Manager devrait voir sa **zone de gestion** (utilisateurs, documents, tickets)
- Tous les 3 utilisent **Authorization Bearer Token**
- Tous les 3 ont **gestion d'erreurs** avec toast/console

