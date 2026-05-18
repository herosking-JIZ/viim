# 📊 Flux des Données du Dashboard - N'DJIGI

## 🎯 Vue d'ensemble

Le dashboard affiche les KPIs et statistiques de la plateforme. Voici le flux complet des données du backend jusqu'à l'affichage.

---

## 1️⃣ POINT D'ENTRÉE : Dashboard.tsx
**Fichier:** `web/n-djigi/src/pages/admin/Dashboard.tsx`

### État local (React State)
```typescript
const [kpis, setKpis] = useState<AdminKpis | null>(null)
const [coursesSemaine, setCoursesSemaine] = useState<ChartDataPoint[]>([])
const [evolution, setEvolution] = useState<ChartDataPoint[]>([])
const [paiements, setPaiements] = useState<{ name: string; value: number }[]>([])
const [topChauffeurs, setTopChauffeurs] = useState<TopChauffeur[]>([])
const [loading, setLoading] = useState(true)
```

### Chargement des données (useEffect)
```typescript
useEffect(() => {
  const load = async () => {
    try {
      // 🔄 Appel parallèle de toutes les requêtes API
      const [k, cs, ev, pm, tc] = await Promise.all([
        dashboardService.kpis(),              // KPIs
        dashboardService.coursesSemaine(),    // Cours semaine
        dashboardService.evolutionMensuelle(), // Évolution
        dashboardService.moyensPaiement(),    // Moyens de paiement
        dashboardService.topChauffeurs(),     // Top 5 chauffeurs
      ])
      
      // 📦 Mise à jour de l'état
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
}, [])
```

---

## 2️⃣ SERVICE API : dashboardService
**Fichier:** `web/n-djigi/src/services/api.ts` (lignes 656-679)

### Fonction 1: KPIs
```typescript
export const dashboardService = {
  kpis: async (): Promise<AdminKpis> => {
    if (IS_DEMO) { 
      await delay(); 
      return mock.MOCK_KPIS  // 👈 Données de test
    }
    // 🌐 Requête réelle au backend
    const { data } = await api.get<ApiResponse<AdminKpis>>('/dashboard/kpis')
    return extractData(data)
  },
```

### Fonction 2: Courses par semaine
```typescript
  coursesSemaine: async (): Promise<ChartDataPoint[]> => {
    if (IS_DEMO) { 
      await delay(); 
      return mock.MOCK_COURSES_SEMAINE 
    }
    const { data } = await api.get<ApiResponse<ChartDataPoint[]>>('/dashboard/courses-semaine')
    return extractData(data)
  },
```

### Fonction 3: Évolution mensuelle
```typescript
  evolutionMensuelle: async (): Promise<ChartDataPoint[]> => {
    if (IS_DEMO) { 
      await delay(); 
      return mock.MOCK_EVOLUTION 
    }
    const { data } = await api.get<ApiResponse<ChartDataPoint[]>>('/dashboard/evolution-mensuelle')
    return extractData(data)
  },
```

### Fonction 4: Moyens de paiement
```typescript
  moyensPaiement: async (): Promise<{ name: string; value: number }[]> => {
    if (IS_DEMO) { 
      await delay(); 
      return mock.MOCK_PAIEMENTS 
    }
    const { data } = await api.get<ApiResponse<{ name: string; value: number }[]>>('/dashboard/moyens-paiement')
    return extractData(data)
  },
```

### Fonction 5: Top chauffeurs
```typescript
  topChauffeurs: async (): Promise<TopChauffeur[]> => {
    if (IS_DEMO) { 
      await delay(); 
      return mock.MOCK_TOP_CHAUFFEURS 
    }
    const { data } = await api.get<ApiResponse<TopChauffeur[]>>('/dashboard/top-chauffeurs')
    return extractData(data)
  },
}
```

---

## 3️⃣ INSTANCE AXIOS : api
**Fichier:** `web/n-djigi/src/services/api.ts` (lignes 24-74)

### Configuration
```typescript
const api: AxiosInstance = axios.create({
  baseURL: '/api/v1',
  headers: { 'Content-Type': 'application/json' },
})
```

### Interceptor de requête (Injection du token)
```typescript
api.interceptors.request.use((config) => {
  const token = localStorage.getItem(STORAGE_KEY_ACCESS)
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})
```

### Interceptor de réponse (Gestion erreurs & refresh token)
```typescript
api.interceptors.response.use(
  (res) => res,
  async (err) => {
    const status = err.response?.status

    // Si token expiré (401), tenter le refresh
    if (status === 401) {
      const refreshToken = localStorage.getItem(STORAGE_KEY_REFRESH)
      if (refreshToken && !err.config._retry) {
        err.config._retry = true
        try {
          const { data } = await axios.post('/api/v1/auth/refresh', { refresh_token: refreshToken })
          const newToken = data.data?.access_token
          if (newToken) {
            localStorage.setItem(STORAGE_KEY_ACCESS, newToken)
            if (data.data?.refresh_token) {
              localStorage.setItem(STORAGE_KEY_REFRESH, data.data.refresh_token)
            }
            err.config.headers.Authorization = `Bearer ${newToken}`
            return api(err.config)  // 🔄 Retry avec nouveau token
          }
        } catch {
          // Refresh échoué → redirection vers login
          localStorage.removeItem(STORAGE_KEY_ACCESS)
          localStorage.removeItem(STORAGE_KEY_REFRESH)
          window.location.href = '/login'
        }
      }
    }
    return Promise.reject(err)
  }
)
```

### Helper extractData
```typescript
function extractData<T>(apiResponse: ApiResponse<T>): T {
  if (!apiResponse.success) {
    const err: any = new Error(apiResponse.message || 'Erreur serveur')
    err.backendErrors = apiResponse.errors
    throw err
  }
  return apiResponse.data
}
```

---

## 4️⃣ RÉPONSES BACKEND RÉELLES

### 1. GET /api/v1/dashboard/kpis
```json
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

### 2. GET /api/v1/dashboard/courses-semaine
```json
{
  "success": true,
  "message": "Courses par semaine",
  "data": [
    { "label": "Lun", "value": 62 },
    { "label": "Mar", "value": 78 },
    { "label": "Mer", "value": 55 },
    { "label": "Jeu", "value": 91 },
    { "label": "Ven", "value": 110 },
    { "label": "Sam", "value": 87 },
    { "label": "Dim", "value": 45 }
  ],
  "errors": null
}
```

### 3. GET /api/v1/dashboard/evolution-mensuelle
```json
{
  "success": true,
  "message": "Évolution mensuelle",
  "data": [
    { "label": "Oct", "value": 820 },
    { "label": "Nov", "value": 940 },
    { "label": "Déc", "value": 1100 },
    { "label": "Jan", "value": 980 },
    { "label": "Fév", "value": 1250 },
    { "label": "Mar", "value": 1430 },
    { "label": "Avr", "value": 1580 }
  ],
  "errors": null
}
```

### 4. GET /api/v1/dashboard/moyens-paiement
```json
{
  "success": true,
  "message": "Moyens de paiement",
  "data": [
    { "name": "Mobile Money", "value": 58 },
    { "name": "Espèces", "value": 28 },
    { "name": "Carte Visa", "value": 10 },
    { "name": "Autre", "value": 4 }
  ],
  "errors": null
}
```

### 5. GET /api/v1/dashboard/top-chauffeurs
```json
{
  "success": true,
  "message": "Top chauffeurs",
  "data": [
    { "rang": 1, "nom": "Hamidou Traoré", "chiffre_affaires": 312000 },
    { "rang": 2, "nom": "Adama Ouédraogo", "chiffre_affaires": 278500 },
    { "rang": 3, "nom": "Salif Kaboré", "chiffre_affaires": 245000 },
    { "rang": 4, "nom": "Moussa Diallo", "chiffre_affaires": 198000 },
    { "rang": 5, "nom": "Ibrahim Zongo", "chiffre_affaires": 175500 }
  ],
  "errors": null
}
```

---

## 5️⃣ TYPES TYPESCRIPT
**Fichier:** `web/n-djigi/src/types/index.ts` (lignes 353-374)

### AdminKpis
```typescript
export interface AdminKpis {
  total_utilisateurs: number      // Nombre total d'utilisateurs
  courses_aujourd_hui: number     // Courses du jour
  revenus_commission_jour: number // Revenus du jour en XOF
  satisfaction_moyenne: number    // Note /5
  tendance_utilisateurs: number   // % de variation
  tendance_courses: number        // % de variation
}
```

### ChartDataPoint
```typescript
export interface ChartDataPoint {
  label: string  // Jour, mois, etc.
  value: number  // Valeur numérique
}
```

### TopChauffeur
```typescript
export interface TopChauffeur {
  rang: number         // 1-5
  nom: string          // Nom du chauffeur
  chiffre_affaires: number // Montant en XOF
}
```

---

## 6️⃣ COMPOSANTS D'AFFICHAGE

### KpiCard (Lignes 60-89)
```typescript
// 4 KPI cards affichées
<KpiCard
  title="Utilisateurs totaux"
  value={kpis?.total_utilisateurs ?? '—'}
  subtitle="Tous rôles confondus"
  icon={Users}
  trend={kpis?.tendance_utilisateurs}
  loading={loading}
/>

<KpiCard
  title="Courses aujourd'hui"
  value={kpis?.courses_aujourd_hui ?? '—'}
  icon={Car}
  trend={kpis?.tendance_courses}
  loading={loading}
/>

<KpiCard
  title="Commissions du jour"
  value={kpis ? formatFCFA(kpis.revenus_commission_jour) : '—'}
  icon={CreditCard}
  loading={loading}
/>

<KpiCard
  title="Satisfaction moyenne"
  value={kpis ? `${kpis.satisfaction_moyenne} / 5` : '—'}
  icon={Star}
  loading={loading}
/>
```

### Graphique courses semaine (Lignes 93-107)
```typescript
<BarChart data={coursesSemaine} barSize={28}>
  <XAxis dataKey="label" />
  <YAxis />
  <Tooltip />
  <Bar dataKey="value" name="Courses" fill="hsl(24,95%,53%)" />
</BarChart>
```

### Graphique évolution mensuelle (Lignes 109-134)
```typescript
<AreaChart data={evolution}>
  <XAxis dataKey="label" />
  <YAxis />
  <Area
    type="monotone"
    dataKey="value"
    name="Courses"
    stroke="hsl(24,95%,53%)"
  />
</AreaChart>
```

### Pie chart moyens paiement (Lignes 139-168)
```typescript
<PieChart width={160} height={160}>
  <Pie
    data={paiements}
    cx="50%"
    cy="50%"
    innerRadius={48}
    outerRadius={72}
    dataKey="value"
    paddingAngle={3}
  >
    {paiements.map((p, i) => (
      <Cell key={p.name} fill={COLORS[i % COLORS.length]} />
    ))}
  </Pie>
</PieChart>
```

### Top 5 chauffeurs (Lignes 170-193)
```typescript
<ol className="space-y-2">
  {topChauffeurs.map((c) => (
    <li key={c.rang} className="flex items-center gap-3">
      <div className="w-6 h-6 rounded-full bg-primary/10">
        {c.rang}
      </div>
      <span className="flex-1">{c.nom}</span>
      <span>{formatFCFA(c.chiffre_affaires)}</span>
    </li>
  ))}
</ol>
```

---

## 7️⃣ FLUX COMPLET DIAGRAMME

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER VISITS DASHBOARD                        │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│              Dashboard.tsx Component Mounts (useEffect)               │
│                                                                       │
│  ✅ Load 5 API calls in parallel using Promise.all()                │
│  • dashboardService.kpis()                                          │
│  • dashboardService.coursesSemaine()                                │
│  • dashboardService.evolutionMensuelle()                            │
│  • dashboardService.moyensPaiement()                                │
│  • dashboardService.topChauffeurs()                                 │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    dashboardService in api.ts                        │
│                                                                       │
│  Each service method:                                               │
│  1. Checks IS_DEMO (development mode)                               │
│  2. If demo → return mock data (mockData.ts)                        │
│  3. If real → call api.get() with endpoint                          │
│  4. extractData() unwraps { success, data, errors }                 │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                      Axios Instance (api)                            │
│                                                                       │
│  Request Interceptor:                                               │
│  └─ Inject Authorization token from localStorage                    │
│                                                                       │
│  POST → Backend at /api/v1/dashboard/*                              │
│                                                                       │
│  Response Interceptor:                                              │
│  ├─ If 401 (token expired)                                          │
│  │  └─ Refresh token & retry request                               │
│  └─ If error → throw error                                          │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│                  BACKEND (Node.js/Express)                           │
│                                                                       │
│  Routes:                                                            │
│  • GET /api/v1/dashboard/kpis                                       │
│  • GET /api/v1/dashboard/courses-semaine                            │
│  • GET /api/v1/dashboard/evolution-mensuelle                        │
│  • GET /api/v1/dashboard/moyens-paiement                            │
│  • GET /api/v1/dashboard/top-chauffeurs                             │
│                                                                       │
│  Process:                                                           │
│  1. Authenticate user (middleware)                                  │
│  2. Query database (Prisma)                                         │
│  3. Format response { success, message, data, errors }              │
│  4. Return JSON                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│              Response: ApiResponse<T> JSON                           │
│                                                                       │
│  Example (KPIs):                                                    │
│  {                                                                   │
│    "success": true,                                                 │
│    "message": "KPIs...",                                            │
│    "data": {                                                         │
│      "total_utilisateurs": 1284,                                    │
│      "courses_aujourd_hui": 93,                                     │
│      "revenus_commission_jour": 48750,                              │
│      "satisfaction_moyenne": 4.6,                                   │
│      "tendance_utilisateurs": 5.2,                                  │
│      "tendance_courses": -2.1                                       │
│    },                                                                │
│    "errors": null                                                   │
│  }                                                                   │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│            extractData() in dashboardService                         │
│                                                                       │
│  1. Check if success === false                                      │
│     └─ If false: throw error with message                           │
│  2. Return only data field (T)                                      │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│        React State Updates in Dashboard.tsx                          │
│                                                                       │
│  setKpis(k)                           ← AdminKpis                   │
│  setCoursesSemaine(cs)                ← ChartDataPoint[]            │
│  setEvolution(ev)                     ← ChartDataPoint[]            │
│  setPaiements(Array.isArray(pm)...)   ← { name, value }[]           │
│  setTopChauffeurs(tc)                 ← TopChauffeur[]              │
│  setLoading(false)                    ← boolean                     │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│              React Re-renders Dashboard Component                    │
│                                                                       │
│  1. KPI Cards ← display kpis.total_utilisateurs, etc.               │
│  2. BarChart  ← display coursesSemaine[]                            │
│  3. AreaChart ← display evolution[]                                 │
│  4. PieChart  ← display paiements[]                                 │
│  5. TopList   ← display topChauffeurs[]                             │
└─────────────────────────────────────────────────────────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────────┐
│              USER SEES RENDERED DASHBOARD                            │
│                                                                       │
│  ✅ 4 KPI cards with values & trends                                │
│  ✅ Bar chart of daily courses                                      │
│  ✅ Area chart of monthly evolution                                 │
│  ✅ Pie chart of payment methods                                    │
│  ✅ Ranked list of top 5 drivers                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 8️⃣ RÉSUMÉ DES FICHIERS

| Fichier | Responsabilité |
|---------|----------------|
| `Dashboard.tsx` | UI, état local, chargement des données |
| `api.ts` | Service API, appels HTTP, gestion des tokens |
| `types/index.ts` | Contrats TypeScript (AdminKpis, ChartDataPoint, etc.) |
| `mockData.ts` | Données de test (MOCK_KPIS, MOCK_COURSES_SEMAINE, etc.) |
| **Backend** | `/api/v1/dashboard/*` endpoints |

---

## 9️⃣ NOTES IMPORTANTES

### ✅ Points forts
- **Parallélisation** : Toutes les 5 requêtes API sont lancées en parallèle avec `Promise.all()`
- **Gestion des erreurs** : Try/catch avec message d'erreur affiché en console
- **Mode démo** : Support pour le dev local sans backend
- **Refresh token** : Gestion automatique des tokens expirés
- **Types** : Full TypeScript pour la sécurité des types

### ⚠️ À améliorer
- Ajouter des indicateurs de **rechargement partiels** (1 graphique qui charge lentement)
- **Retry logic** sur erreur réseau
- **Cache** des données avec timestamp
- **Pagination** si top chauffeurs > 5

---

## 🔟 COMMENT TESTER

### 1. Mode démo (localStorage)
```javascript
// Dans la console du navigateur
localStorage.setItem('VITE_DEMO_MODE', 'true')
window.location.reload()
```

### 2. Avec Postman
```
GET http://localhost:3000/api/v1/dashboard/kpis
Headers:
  Authorization: Bearer <token>
  Content-Type: application/json
```

### 3. Logs en développement
```typescript
// Ajouter dans Dashboard.tsx
useEffect(() => {
  console.log('KPIs:', kpis)
  console.log('Courses semaine:', coursesSemaine)
  console.log('Top chauffeurs:', topChauffeurs)
}, [kpis, coursesSemaine, topChauffeurs])
```
