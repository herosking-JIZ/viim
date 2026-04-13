import { useState, useEffect, useCallback } from 'react'
import { Search, LogIn, LogOut, Pencil, Wrench, AlertTriangle, Car, Activity, Clock } from 'lucide-react'
import { parkeurService } from '@/services/api'
import { useAuth } from '@/contexts/AuthContext'
import { StatusBadge } from '@/components/StatusBadge'
import { KpiCard } from '@/components/KpiCard'
import { useToast } from '@/hooks/useToast'
import { formatDate } from '@/lib/utils'
import type { Parking, VehiculeParking, MouvementParking } from '@/types'

type ModalType = 'reception' | 'sortie' | 'edit' | 'maintenance' | null

interface FormData {
  immatriculation: string
  etat_vehicule: string
  commentaire: string
  marque: string
  modele: string
  categorie: string
  motif: string
}

const ETAT_OPTIONS = [
  { value: 'bon', label: '✅ Bon état' },
  { value: 'a_verifier', label: '⚠️ À vérifier' },
  { value: 'dommage', label: '🚨 Dommage' },
]

const CATEGORIES = ['moto', 'berline', 'suv', 'minivan', 'camion', 'autre']

const DEFAULT_FORM: FormData = {
  immatriculation: '', etat_vehicule: 'bon', commentaire: '',
  marque: '', modele: '', categorie: 'berline', motif: '',
}

export default function ParkeurDashboard() {
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

  const load = useCallback(async () => {
    if (!parkingId) return
    setLoading(true)
    try {
      const [pk, veh, mvt] = await Promise.all([
        parkeurService.monParking(parkingId),
        parkeurService.vehiculesPresents(parkingId),
        parkeurService.mouvements(parkingId, { search: searchMvt }),
      ])
      setParking(pk)
      setVehicules(veh)
      setMouvements(mvt)
    } catch {
      toast({ title: 'Erreur de chargement', variant: 'destructive' })
    } finally {
      setLoading(false)
    }
  }, [parkingId, searchMvt])

  useEffect(() => { load() }, [load])

  const openModal = (type: ModalType, veh?: VehiculeParking) => {
    setModal(type)
    setSelectedVehicule(veh ?? null)
    setForm(veh ? { ...DEFAULT_FORM, immatriculation: veh.immatriculation, marque: veh.marque, modele: veh.modele, categorie: veh.categorie } : DEFAULT_FORM)
  }

  const handleSubmit = async () => {
    if (!parkingId) return
    setSubmitting(true)
    try {
      if (modal === 'reception') {
        await parkeurService.receptionVehicule(parkingId, { immatriculation: form.immatriculation, etat_vehicule: form.etat_vehicule, commentaire: form.commentaire })
        toast({ title: 'Véhicule réceptionné', variant: 'success' })
      } else if (modal === 'sortie') {
        await parkeurService.sortieVehicule(parkingId, { immatriculation: form.immatriculation, etat_vehicule: form.etat_vehicule, commentaire: form.commentaire })
        toast({ title: 'Sortie enregistrée', variant: 'success' })
      } else if (modal === 'edit' && selectedVehicule) {
        await parkeurService.updateVehicule(selectedVehicule.id_vehicule, { immatriculation: form.immatriculation, marque: form.marque, modele: form.modele, categorie: form.categorie })
        toast({ title: 'Véhicule mis à jour', variant: 'success' })
      } else if (modal === 'maintenance' && selectedVehicule) {
        await parkeurService.declencherMaintenance(parkingId, selectedVehicule.id_vehicule, form.motif)
        toast({ title: 'Maintenance déclenchée', variant: 'success' })
      }
      setModal(null)
      load()
    } catch {
      toast({ title: 'Erreur', variant: 'destructive' })
    } finally {
      setSubmitting(false)
    }
  }

  const filteredVehicules = vehicules.filter((v) =>
    !search || v.immatriculation.toLowerCase().includes(search.toLowerCase()) ||
    v.marque.toLowerCase().includes(search.toLowerCase())
  )

  const mouvementsAujourdhui = mouvements.filter((m) => {
    const today = new Date().toDateString()
    return new Date(m.date_mouvement).toDateString() === today
  }).length

  if (!parkingId) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] text-center gap-4">
        <div className="w-16 h-16 rounded-2xl bg-warning/15 flex items-center justify-center">
          <AlertTriangle className="h-8 w-8 text-warning" />
        </div>
        <div>
          <h2 className="font-display font-bold text-lg">Aucun parking assigné</h2>
          <p className="text-muted-foreground mt-1">Contactez un administrateur pour être affecté à un parking.</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-5">
      {/* En-tête parking */}
      {parking && (
        <div>
          <h1 className="text-2xl font-display font-bold">{parking.nom}</h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {parking.adresse} · {parking.ville} {parking.horaires && `· ${parking.horaires}`}
          </p>
        </div>
      )}

      {/* KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <KpiCard title="Véhicules présents" value={parking ? `${parking.capacite_occupee} / ${parking.capacite_totale}` : '—'} subtitle="Places occupées / capacité" icon={Car} loading={loading} />
        <KpiCard title="Mouvements aujourd'hui" value={mouvementsAujourdhui} subtitle="Entrées et sorties du jour" icon={Activity} loading={loading} />
        <KpiCard title="Horaires" value={parking?.horaires ?? '—'} subtitle="Horaires d'ouverture" icon={Clock} loading={loading} />
      </div>

      {/* Boutons d'action */}
      <div className="flex flex-wrap gap-3">
        <button
          onClick={() => openModal('reception')}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-primary-foreground font-semibold text-sm hover:bg-primary/90 transition-colors"
        >
          <LogIn className="h-4 w-4" />
          Réception véhicule
        </button>
        <button
          onClick={() => openModal('sortie')}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl border border-border hover:bg-muted font-semibold text-sm transition-colors"
        >
          <LogOut className="h-4 w-4" />
          Sortie véhicule
        </button>
      </div>

      {/* Véhicules présents */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-border flex flex-wrap gap-3 items-center justify-between">
          <h2 className="font-display font-semibold">Véhicules présents</h2>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Immatriculation, marque…"
              className="pl-9 pr-3 py-2 rounded-xl border border-input bg-background text-sm outline-none focus:ring-2 focus:ring-primary/50 w-52"
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/40">
                {['Immatriculation', 'Véhicule', 'Catégorie', 'Propriétaire', 'Statut', 'Actions'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 font-semibold text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {loading ? (
                [...Array(5)].map((_, i) => (
                  <tr key={i} className="border-b border-border">{[...Array(6)].map((_, j) => <td key={j} className="px-4 py-3"><div className="h-4 bg-muted rounded animate-pulse" /></td>)}</tr>
                ))
              ) : filteredVehicules.length === 0 ? (
                <tr><td colSpan={6} className="px-4 py-10 text-center text-muted-foreground">Aucun véhicule présent</td></tr>
              ) : (
                filteredVehicules.map((v) => (
                  <tr key={v.id_vehicule} className="border-b border-border last:border-0 hover:bg-muted/30">
                    <td className="px-4 py-3 font-mono font-semibold">{v.immatriculation}</td>
                    <td className="px-4 py-3">{v.marque} {v.modele}</td>
                    <td className="px-4 py-3 capitalize text-muted-foreground">{v.categorie}</td>
                    <td className="px-4 py-3">{v.proprietaire_nom}</td>
                    <td className="px-4 py-3"><StatusBadge status={v.statut} /></td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1">
                        <button onClick={() => openModal('edit', v)} className="p-1.5 rounded-lg hover:bg-muted text-muted-foreground" title="Modifier">
                          <Pencil className="h-3.5 w-3.5" />
                        </button>
                        {v.statut !== 'maintenance' && (
                          <button onClick={() => openModal('maintenance', v)} className="p-1.5 rounded-lg hover:bg-warning/10 text-warning" title="Maintenance">
                            <Wrench className="h-3.5 w-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Historique mouvements */}
      <div className="bg-card border border-border rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-border flex flex-wrap gap-3 items-center justify-between">
          <h2 className="font-display font-semibold">Historique des mouvements</h2>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <input
              value={searchMvt}
              onChange={(e) => setSearchMvt(e.target.value)}
              placeholder="Rechercher…"
              className="pl-9 pr-3 py-2 rounded-xl border border-input bg-background text-sm outline-none focus:ring-2 focus:ring-primary/50 w-52"
            />
          </div>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border bg-muted/40">
                {['Date', 'Type', 'Immatriculation', 'État', 'Commentaire'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 font-semibold text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {mouvements.length === 0 ? (
                <tr><td colSpan={5} className="px-4 py-10 text-center text-muted-foreground">Aucun mouvement</td></tr>
              ) : (
                mouvements.map((m) => (
                  <tr key={m.id_log} className="border-b border-border last:border-0 hover:bg-muted/30">
                    <td className="px-4 py-3 text-muted-foreground">{formatDate(m.date_mouvement)}</td>
                    <td className="px-4 py-3"><StatusBadge status={m.type_mouvement} /></td>
                    <td className="px-4 py-3 font-mono font-semibold">{m.immatriculation}</td>
                    <td className="px-4 py-3"><StatusBadge status={m.etat_vehicule} /></td>
                    <td className="px-4 py-3 text-muted-foreground max-w-[200px] truncate">{m.commentaire ?? '—'}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modals */}
      {modal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" onClick={() => setModal(null)}>
          <div className="bg-card border border-border rounded-2xl p-6 w-full max-w-md shadow-2xl animate-fade-in" onClick={(e) => e.stopPropagation()}>

            {/* Réception / Sortie */}
            {(modal === 'reception' || modal === 'sortie') && (
              <>
                <h2 className="font-display font-bold text-lg mb-5">
                  {modal === 'reception' ? '🚗 Réception véhicule' : '🚀 Sortie véhicule'}
                </h2>
                <div className="space-y-3">
                  <div>
                    <label className="block text-sm font-medium mb-1">Immatriculation</label>
                    <input
                      type="text"
                      value={form.immatriculation}
                      onChange={(e) => setForm((f) => ({ ...f, immatriculation: e.target.value.toUpperCase() }))}
                      placeholder="AA-123-BF"
                      className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm font-mono outline-none focus:ring-2 focus:ring-primary/50"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">État du véhicule</label>
                    <select
                      value={form.etat_vehicule}
                      onChange={(e) => setForm((f) => ({ ...f, etat_vehicule: e.target.value }))}
                      className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50"
                    >
                      {ETAT_OPTIONS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium mb-1">Commentaire (optionnel)</label>
                    <textarea
                      value={form.commentaire}
                      onChange={(e) => setForm((f) => ({ ...f, commentaire: e.target.value }))}
                      rows={2}
                      className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50 resize-none"
                    />
                  </div>
                </div>
              </>
            )}

            {/* Edit véhicule */}
            {modal === 'edit' && (
              <>
                <h2 className="font-display font-bold text-lg mb-5">✏️ Modifier le véhicule</h2>
                <div className="space-y-3">
                  {[
                    { key: 'immatriculation', label: 'Immatriculation' },
                    { key: 'marque', label: 'Marque' },
                    { key: 'modele', label: 'Modèle' },
                  ].map(({ key, label }) => (
                    <div key={key}>
                      <label className="block text-sm font-medium mb-1">{label}</label>
                      <input
                        type="text"
                        value={(form as any)[key]}
                        onChange={(e) => setForm((f) => ({ ...f, [key]: e.target.value }))}
                        className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50"
                      />
                    </div>
                  ))}
                  <div>
                    <label className="block text-sm font-medium mb-1">Catégorie</label>
                    <select
                      value={form.categorie}
                      onChange={(e) => setForm((f) => ({ ...f, categorie: e.target.value }))}
                      className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50"
                    >
                      {CATEGORIES.map((c) => <option key={c} value={c} className="capitalize">{c}</option>)}
                    </select>
                  </div>
                </div>
              </>
            )}

            {/* Maintenance */}
            {modal === 'maintenance' && selectedVehicule && (
              <>
                <h2 className="font-display font-bold text-lg mb-5">🔧 Déclencher maintenance</h2>
                <div className="bg-muted rounded-xl p-3 mb-4 text-sm">
                  <p className="font-semibold">{selectedVehicule.marque} {selectedVehicule.modele}</p>
                  <p className="font-mono text-muted-foreground">{selectedVehicule.immatriculation}</p>
                </div>
                <div>
                  <label className="block text-sm font-medium mb-1">Motif de la maintenance</label>
                  <textarea
                    value={form.motif}
                    onChange={(e) => setForm((f) => ({ ...f, motif: e.target.value }))}
                    placeholder="Décrivez le problème…"
                    rows={3}
                    className="w-full rounded-xl border border-input bg-background px-3.5 py-2 text-sm outline-none focus:ring-2 focus:ring-primary/50 resize-none"
                  />
                </div>
              </>
            )}

            <div className="flex gap-3 mt-6 justify-end">
              <button onClick={() => setModal(null)} className="px-4 py-2 rounded-xl border border-border hover:bg-muted text-sm">
                Annuler
              </button>
              <button
                onClick={handleSubmit}
                disabled={submitting}
                className={`px-4 py-2 rounded-xl text-sm font-medium disabled:opacity-60 ${
                  modal === 'maintenance'
                    ? 'bg-warning text-warning-foreground hover:bg-warning/90'
                    : 'bg-primary text-primary-foreground hover:bg-primary/90'
                }`}
              >
                {submitting ? 'En cours…' : modal === 'maintenance' ? 'Confirmer la maintenance' : 'Confirmer'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}
