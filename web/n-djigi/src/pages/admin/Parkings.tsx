import { useState, useEffect, useCallback } from 'react'
import { Search, Pencil, ParkingCircle, Car, Activity } from 'lucide-react'
import { parkingsService } from '@/services/api'
import { KpiCard } from '@/components/KpiCard'
import { StatusBadge } from '@/components/StatusBadge'
import { useToast } from '@/hooks/useToast'
import { formatDate } from '@/lib/utils'
import type { Parking, MouvementParking } from '@/types'

export default function Parkings() {
  const { toast } = useToast()
  const [parkings, setParkings] = useState<Parking[]>([])
  const [mouvements, setMouvements] = useState<MouvementParking[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [editTarget, setEditTarget] = useState<Parking | null>(null)
  const [editForm, setEditForm] = useState<Partial<Parking>>({})

  const load = useCallback(async () => {
    setLoading(true)
    try {
      const [ps, mv] = await Promise.all([
        parkingsService.list(),
        parkingsService.mouvements({ search }),
      ])
      setParkings(ps)
      setMouvements(mv)
    } catch {
      toast({ title: 'Erreur', variant: 'destructive' })
    } finally {
      setLoading(false)
    }
  }, [search])

  useEffect(() => { load() }, [load])

  const handleEdit = (p: Parking) => {
    setEditTarget(p)
    setEditForm({ ...p })
  }

  const handleSave = async () => {
    if (!editTarget) return
    try {
      await parkingsService.update(editTarget.id_parking, editForm)
      toast({ title: 'Parking mis à jour', variant: 'success' })
      setEditTarget(null)
      load()
    } catch {
      toast({ title: 'Erreur', variant: 'destructive' })
    }
  }

  const totalVehicules = parkings.reduce((s, p) => s + p.capacite_occupee, 0)
  const totalCapacite = parkings.reduce((s, p) => s + p.capacite_totale, 0)
  const actifs = parkings.filter((p) => p.actif).length

  return (
    <div className="space-y-5">
      <div>
        <h1 className="text-2xl font-display font-bold">Parkings</h1>
        <p className="text-sm text-muted-foreground mt-0.5">Réseau de parkings N'DJIGI</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <KpiCard title="Parkings actifs" value={actifs} subtitle={`sur ${parkings.length} au total`} icon={ParkingCircle} loading={loading} />
        <KpiCard title="Véhicules en parking" value={totalVehicules} subtitle={`capacité totale : ${totalCapacite}`} icon={Car} loading={loading} />
        <KpiCard title="Mouvements récents" value={mouvements.length} subtitle="Entrées et sorties" icon={Activity} loading={loading} />
      </div>

      {/* Liste parkings */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-border">
          <h2 className="font-display font-semibold">Liste des parkings</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/40">
                {['Nom', 'Ville', 'Adresse', 'Véhicules', 'Horaires', 'Statut', ''].map((h) => (
                  <th key={h} className="text-left px-4 py-3 font-semibold text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(4)].map((_, i) => (
                  <tr key={i} className="border-b border-border">
                    {[...Array(7)].map((_, j) => <td key={j} className="px-4 py-3"><div className="h-4 bg-muted rounded animate-pulse" /></td>)}
                  </tr>
                ))
              ) : (
                parkings.map((p) => (
                  <tr key={p.id_parking} className="border-b border-border last:border-0 hover:bg-muted/30">
                    <td className="px-4 py-3 font-semibold">{p.nom}</td>
                    <td className="px-4 py-3">{p.ville}</td>
                    <td className="px-4 py-3 text-muted-foreground max-w-[200px] truncate">{p.adresse}</td>
                    <td className="px-4 py-3">
                      <span className={p.capacite_occupee >= p.capacite_totale ? 'text-destructive font-semibold' : ''}>
                        {p.capacite_occupee}
                      </span>
                      <span className="text-muted-foreground">/{p.capacite_totale}</span>
                    </td>
                    <td className="px-4 py-3 text-muted-foreground">{p.horaires ?? '—'}</td>
                    <td className="px-4 py-3"><StatusBadge status={p.actif ? 'actif' : 'suspendu'} /></td>
                    <td className="px-4 py-3">
                      <button onClick={() => handleEdit(p)} className="p-1.5 rounded-lg hover:bg-muted text-muted-foreground hover:text-foreground">
                        <Pencil className="h-4 w-4" />
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Mouvements */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-border flex flex-wrap gap-3 items-center justify-between">
          <h2 className="font-display font-semibold">Mouvements récents</h2>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Rechercher…"
              className="pl-9 pr-3 py-2 rounded-xl border border-input bg-background text-sm outline-none focus:ring-2 focus:ring-primary/50 w-60" />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/40">
                {['Date', 'Type', 'Immatriculation', 'Parking', 'Parkeur', 'État', 'Commentaire'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 font-semibold text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {mouvements.length === 0 ? (
                <tr><td colSpan={7} className="px-4 py-10 text-center text-muted-foreground">Aucun mouvement</td></tr>
              ) : (
                mouvements.map((m) => (
                  <tr key={m.id_log} className="border-b border-border last:border-0 hover:bg-muted/30">
                    <td className="px-4 py-3 text-muted-foreground">{formatDate(m.date_mouvement)}</td>
                    <td className="px-4 py-3"><StatusBadge status={m.type_mouvement} /></td>
                    <td className="px-4 py-3 font-mono font-medium">{m.immatriculation}</td>
                    <td className="px-4 py-3">{m.parking_nom}</td>
                    <td className="px-4 py-3">{m.parkeur_nom}</td>
                    <td className="px-4 py-3"><StatusBadge status={m.etat_vehicule} /></td>
                    <td className="px-4 py-3 text-muted-foreground max-w-[200px] truncate">{m.commentaire ?? '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal édition */}
      {editTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" onClick={() => setEditTarget(null)}>
          <div className="bg-card border border-border rounded-2xl p-6 w-full max-w-md shadow-2xl animate-fade-in" onClick={(e) => e.stopPropagation()}>
            <h2 className="font-display font-bold text-lg mb-5">Modifier le parking</h2>
            <div className="space-y-3">
              {[
                { key: 'nom', label: 'Nom', type: 'text' },
                { key: 'ville', label: 'Ville', type: 'text' },
                { key: 'adresse', label: 'Adresse', type: 'text' },
                { key: 'capacite_totale', label: 'Capacité', type: 'number' },
                { key: 'horaires', label: 'Horaires', type: 'text' },
              ].map(({ key, label, type }) => (
                <div key={key}>
                  <label className="block text-sm font-medium mb-1">{label}</label>
                  <input
                    type={type}
                    value={(editForm as any)[key] ?? ''}
                    onChange={(e) => setEditForm((f) => ({ ...f, [key]: type === 'number' ? Number(e.target.value) : e.target.value }))}
                    className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50"
                  />
                </div>
              ))}
              <div className="flex items-center gap-3">
                <label className="text-sm font-medium">Parking actif</label>
                <button
                  onClick={() => setEditForm((f) => ({ ...f, actif: !f.actif }))}
                  className={`relative inline-flex h-5 w-9 items-center rounded-full transition-colors ${editForm.actif ? 'bg-primary' : 'bg-muted'}`}
                >
                  <span className={`inline-block h-4 w-4 rounded-full bg-white shadow transition-transform ${editForm.actif ? 'translate-x-4' : 'translate-x-0.5'}`} />
                </button>
              </div>
            </div>
            <div className="flex gap-3 mt-6 justify-end">
              <button onClick={() => setEditTarget(null)} className="px-4 py-2 rounded-xl border border-border hover:bg-muted text-sm">Annuler</button>
              <button onClick={handleSave} className="px-4 py-2 rounded-xl bg-primary text-primary-foreground text-sm font-medium hover:bg-primary/90">Enregistrer</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
