# 🚀 Dashboard - Référence Rapide

## 📍 Fichiers clés

### 1. **Dashboard Component** 
📁 `web/n-djigi/src/pages/admin/Dashboard.tsx`

```typescript
// ✅ CETTE LIGNE DÉCLENCHE TOUT LE FLUX
const [kpis, setKpis] = useState<AdminKpis | null>(null)
const [coursesSemaine, setCoursesSemaine] = useState<ChartDataPoint[]>([])
const [evolution, setEvolution] = useState<ChartDataPoint[]>([])
const [paiements, setPaiements] = useState<{ name: string; value: number }[]>([])
const [topChauffeurs, setTopChauffeurs] = useState<TopChauffeur[]>([])

// ✅ QUAND LE COMPOSANT SE MONTE (useEffect)
useEffect(() => {
  const load = async () => {
    try {
      // 🔄 APPELLE 5 ENDPOINTS EN PARALLÈLE
      const [k, cs, ev, pm, tc] = await Promise.all([
        dashboardService.kpis(),              
        dashboardService.coursesSemaine(),    
        dashboardService.evolutionMensuelle(), 
        dashboardService.moyensPaiement(),    
        dashboardService.topChauffeurs(),     
      ])
      
      // 💾 MET À JOUR L'ÉTAT LOCAL
      setKpis(k)
      setCoursesSemaine(cs)
      setEvolution(ev)
      setPaiements(Array.isArray(pm) ? pm : [])
      setTopChauffeurs(tc)
    } catch (err) {
      console.error('Dashboard load error:', err)
    } finally {
      setLoading(false)
    }
  }
  load()
}, []) // ← Lance UNE SEULE FOIS au montage
```

### 2. **Service API**
📁 `web/n-djigi/src/services/api.ts` (lignes 656-679)

```typescript
export const dashboardService = {
  kpis: async (): Promise<AdminKpis> => {
    if (IS_DEMO) { await delay(); return mock.MOCK_KPIS }
    // 🌐 VRAIE REQUÊTE HTTP
    const { data } = await api.get<ApiResponse<AdminKpis>>('/dashboard/kpis')
    return extractData(data)  // Unwrap la réponse
  },

  coursesSemaine: async (): Promise<ChartDataPoint[]> => {
    if (IS_DEMO) { await delay(); return mock.MOCK_COURSES_SEMAINE }
    const { data } = await api.get<ApiResponse<ChartDataPoint[]>>('/dashboard/courses-semaine')
    return extractData(data)
  },

  evolutionMensuelle: async (): Promise<ChartDataPoint[]> => {
    if (IS_DEMO) { await delay(); return mock.MOCK_EVOLUTION }
    const { data } = await api.get<ApiResponse<ChartDataPoint[]>>('/dashboard/evolution-mensuelle')
    return extractData(data)
  },

  moyensPaiement: async (): Promise<{ name: string; value: number }[]> => {
    if (IS_DEMO) { await delay(); return mock.MOCK_PAIEMENTS }
    const { data } = await api.get<ApiResponse<{ name: string; value: number }[]>>('/dashboard/moyens-paiement')
    return extractData(data)
  },

  topChauffeurs: async (): Promise<TopChauffeur[]> => {
    if (IS_DEMO) { await delay(); return mock.MOCK_TOP_CHAUFFEURS }
    const { data } = await api.get<ApiResponse<TopChauffeur[]>>('/dashboard/top-chauffeurs')
    return extractData(data)
  },
}
```

### 3. **Instance Axios**
📁 `web/n-djigi/src/services/api.ts` (lignes 24-88)

```typescript
// 📡 INSTANCE AXIOS
const api: AxiosInstance = axios.create({
  baseURL: '/api/v1',  // URL de base
  headers: { 'Content-Type': 'application/json' },
})

// 🔓 INTERCEPTOR REQUÊTE : injecter le token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(STORAGE_KEY_ACCESS)
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

// 🔒 INTERCEPTOR RÉPONSE : gérer les erreurs & refresh
api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const status = err.response?.status
    if (status === 401) {  // Token expiré
      // Tenter le refresh...
    }
    return Promise.reject(err)
  }
)

// 🛠️ HELPER : extraire data depuis ApiResponse
function extractData<T>(apiResponse: ApiResponse<T>): T {
  if (!apiResponse.success) {
    throw new Error(apiResponse.message || 'Erreur serveur')
  }
  return apiResponse.data
}
```

### 4. **Types TypeScript**
📁 `web/n-djigi/src/types/index.ts` (lignes 353-374)

```typescript
// 📊 KPIs
export interface AdminKpis {
  total_utilisateurs: number      // ex: 1284
  courses_aujourd_hui: number     // ex: 93
  revenus_commission_jour: number // ex: 48750 XOF
  satisfaction_moyenne: number    // ex: 4.6 / 5
  tendance_utilisateurs: number   // ex: 5.2 (%)
  tendance_courses: number        // ex: -2.1 (%)
}

// 📈 Données de graphique
export interface ChartDataPoint {
  label: string  // "Lun", "Mar", "Oct", etc.
  value: number  // 62, 78, 820, etc.
}

// 🏆 Top chauffeurs
export interface TopChauffeur {
  rang: number         // 1, 2, 3, etc.
  nom: string          // "Hamidou Traoré"
  chiffre_affaires: number // 312000 XOF
}

// 💳 Moyens de paiement
// { name: "Mobile Money", value: 58 }
// { name: "Espèces", value: 28 }
```

### 5. **Données de Test**
📁 `web/n-djigi/src/data/mockData.ts` (lignes 60-64)

```typescript
export const MOCK_KPIS: AdminKpis = { 
  total_utilisateurs: 1284, 
  courses_aujourd_hui: 93, 
  revenus_commission_jour: 48750, 
  satisfaction_moyenne: 4.6, 
  tendance_utilisateurs: 5.2, 
  tendance_courses: -2.1 
}

export const MOCK_COURSES_SEMAINE: ChartDataPoint[] = [
  { label: 'Lun', value: 62 },
  { label: 'Mar', value: 78 },
  { label: 'Mer', value: 55 },
  // ... etc
]

export const MOCK_PAIEMENTS = [
  { name: 'Mobile Money', value: 58 },
  { name: 'Espèces', value: 28 },
  // ... etc
]

export const MOCK_TOP_CHAUFFEURS: TopChauffeur[] = [
  { rang: 1, nom: 'Hamidou Traoré', chiffre_affaires: 312000 },
  { rang: 2, nom: 'Adama Ouédraogo', chiffre_affaires: 278500 },
  // ... etc
]
```

---

## 🔄 FLUX SIMPLIFIÉ EN 5 ÉTAPES

```
┌──────────────────────────────────────────────────────────┐
│ ÉTAPE 1: Dashboard monte et appelle useEffect            │
│ → Déclenche Promise.all([5 appels API])                 │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ ÉTAPE 2: dashboardService envoie requêtes HTTP           │
│ GET /dashboard/kpis                                      │
│ GET /dashboard/courses-semaine                           │
│ GET /dashboard/evolution-mensuelle                       │
│ GET /dashboard/moyens-paiement                           │
│ GET /dashboard/top-chauffeurs                            │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ ÉTAPE 3: Axios interceptor ajoute token Bearer           │
│ Authorization: Bearer <token>                            │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ ÉTAPE 4: Backend traite et retourne JSON                │
│ { success: true, data: {...}, errors: null }            │
└──────────────────────────────────────────────────────────┘
                         ↓
┌──────────────────────────────────────────────────────────┐
│ ÉTAPE 5: extractData() unwrap + setters update état      │
│ setKpis(k), setCoursesSemaine(cs), etc.                 │
│ → Component re-render avec nouvelles données            │
└──────────────────────────────────────────────────────────┘
```

---

## 📡 ENDPOINTS BACKEND

Tous les endpoints retournent ce format:

```json
{
  "success": boolean,
  "message": string,
  "data": T,  // Type dépend de l'endpoint
  "errors": null | Record<string, string>
}
```

### Endpoints du dashboard:

| Endpoint | Type | Retourne | Notes |
|----------|------|----------|-------|
| `/api/v1/dashboard/kpis` | GET | `AdminKpis` | KPIs pour les 4 cartes |
| `/api/v1/dashboard/courses-semaine` | GET | `ChartDataPoint[]` | Graphique barres |
| `/api/v1/dashboard/evolution-mensuelle` | GET | `ChartDataPoint[]` | Graphique aires |
| `/api/v1/dashboard/moyens-paiement` | GET | `{ name, value }[]` | Graphique pie |
| `/api/v1/dashboard/top-chauffeurs` | GET | `TopChauffeur[]` | Liste 5 meilleurs |

---

## 🎨 AFFICHAGE DU DASHBOARD

### Ligne 51-56: En-tête
```tsx
<div className="space-y-6">
  <div>
    <h1 className="text-2xl font-display font-bold">Tableau de bord</h1>
    <p className="text-sm text-muted-foreground">Vue d'ensemble de la plateforme</p>
  </div>
```

### Ligne 59-90: KPI Cards (4 cards)
```tsx
<div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
  <KpiCard title="Utilisateurs totaux" value={kpis?.total_utilisateurs ?? '—'} ... />
  <KpiCard title="Courses aujourd'hui" value={kpis?.courses_aujourd_hui ?? '—'} ... />
  <KpiCard title="Commissions du jour" value={formatFCFA(kpis?.revenus_commission_jour)} ... />
  <KpiCard title="Satisfaction moyenne" value={`${kpis?.satisfaction_moyenne} / 5`} ... />
</div>
```

### Ligne 93-135: 2 Graphiques (Barres + Aires)
```tsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
  {/* Graphique 1: Courses par jour */}
  <BarChart data={coursesSemaine} />
  
  {/* Graphique 2: Évolution mensuelle */}
  <AreaChart data={evolution} />
</div>
```

### Ligne 137-194: 2 Graphiques (Pie + Top Chauffeurs)
```tsx
<div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
  {/* Graphique 3: Moyens de paiement (Pie) */}
  <PieChart data={paiements} />
  
  {/* Graphique 4: Top 5 chauffeurs (Liste) */}
  <ol>
    {topChauffeurs.map(c => (
      <li>{c.rang}. {c.nom} — {formatFCFA(c.chiffre_affaires)}</li>
    ))}
  </ol>
</div>
```

---

## 🧪 EXEMPLE RÉEL: Appel KPIs

### 1️⃣ User visite /dashboard
```
Dashboard.tsx monte → useEffect se lance
```

### 2️⃣ Dashboard appelle dashboardService.kpis()
```typescript
const [kpis, setKpis] = useState<AdminKpis | null>(null)

useEffect(() => {
  const load = async () => {
    const k = await dashboardService.kpis()  // ← ICI
    setKpis(k)
  }
  load()
}, [])
```

### 3️⃣ Service envoie GET /dashboard/kpis
```typescript
const { data } = await api.get<ApiResponse<AdminKpis>>('/dashboard/kpis')
//        ↑ { success: true, data: {...}, errors: null }

return extractData(data)  // Retourne juste le `data` field
```

### 4️⃣ Axios interceptor ajoute le token
```typescript
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(STORAGE_KEY_ACCESS)
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})
```

### 5️⃣ Requête au backend
```
GET /api/v1/dashboard/kpis HTTP/1.1
Host: localhost:3000
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
Content-Type: application/json
```

### 6️⃣ Backend retourne
```json
HTTP/1.1 200 OK

{
  "success": true,
  "message": "KPIs récupérés",
  "data": {
    "total_utilisateurs": 1284,
    "courses_aujourd_hui": 93,
    "revenus_commission_jour": 48750,
    "satisfaction_moyenne": 4.6,
    "tendance_utilisateurs": 5.2,
    "tendance_courses": -2.1
  },
  "errors": null
}
```

### 7️⃣ Frontend reçoit et met à jour l'état
```typescript
const k = extractData(data)  // AdminKpis
//    = {
//      total_utilisateurs: 1284,
//      courses_aujourd_hui: 93,
//      ...
//    }

setKpis(k)  // ← Trigger re-render
```

### 8️⃣ Component affiche les données
```tsx
<KpiCard
  title="Utilisateurs totaux"
  value={kpis?.total_utilisateurs ?? '—'}  // ← affiche 1284
  ...
/>
```

---

## 🚨 ERREURS COURANTES

| Erreur | Cause | Solution |
|--------|-------|----------|
| "Cannot read property 'kpis' of undefined" | `dashboardService` non importé | `import { dashboardService } from '@/services/api'` |
| "data is null" | State pas encore chargé | Utiliser `kpis?.property` ou `?? '—'` |
| 401 Unauthorized | Token expiré ou manquant | Vérifier localStorage, token dans Authorization header |
| Mock data jamais chargé | `IS_DEMO` = false | Vérifier `.env`: `VITE_DEMO_MODE=true` |
| Graphs affichent "undefined" | Data n'a pas le bon format | Vérifier structure { label, value } |

---

## 💡 OPTIMISATIONS POSSIBLES

### ✅ Actuellement
- ✅ Chargement parallèle avec `Promise.all()`
- ✅ Gestion automatique du refresh token
- ✅ Support mode démo/production
- ✅ Full TypeScript

### 🔄 À ajouter
```typescript
// Cache avec timestamp
const CACHE_DURATION = 5 * 60 * 1000  // 5 minutes
const cached = { data: null, timestamp: 0 }

const kpis = async () => {
  if (Date.now() - cached.timestamp < CACHE_DURATION) {
    return cached.data
  }
  const data = await api.get(...)
  cached.data = data
  cached.timestamp = Date.now()
  return data
}

// Retry sur erreur réseau
const retryAsync = (fn, maxRetries = 3) => {
  return fn().catch(err => 
    maxRetries > 0 ? retryAsync(fn, maxRetries - 1) : Promise.reject(err)
  )
}

// Recharger au focus de la fenêtre
useEffect(() => {
  window.addEventListener('focus', load)
  return () => window.removeEventListener('focus', load)
}, [])
```

---

## 📚 FICHIERS CONNEXES

- `KpiCard.tsx` - Composant pour afficher une KPI
- `useToast.ts` - Hook pour afficher des notifications
- `formatFCFA()` - Fonction pour formater les montants

---

## 🎯 RÉSUMÉ ULTRA-COURT

| Quoi | Où | Quand |
|------|----|----|
| **Chargement data** | Dashboard.tsx useEffect | Au montage |
| **Envoi requête** | dashboardService + axios | Immédiatement |
| **Injection token** | Axios interceptor | Avant chaque requête |
| **Traitement** | Backend (Node.js) | Au reçu de la requête |
| **Réception** | extractData() | Après réponse 200 |
| **Affichage** | setters + re-render | React update |

