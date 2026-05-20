# MULTER - Architecture Production Complète

## 1. LE RÔLE EXACT DE MULTER DANS multipart/form-data

### 1.1 Flux HTTP Multipart

```
FRONTEND (React/Next.js)
   ↓
FormData avec fichiers
   ↓
POST /api/upload (multipart/form-data)
   ↓
Network Layer
   ↓
EXPRESS SERVER
   ├─ Raw Buffer reçu
   ├─ Headers: Content-Type: multipart/form-data; boundary=----XXXXX
   └─ Body: binary data (pas parsé encore)
   ↓
MULTER MIDDLEWARE
   ├─ Parse multipart/form-data
   ├─ Sépare fichiers et champs
   ├─ Applique diskStorage/memoryStorage
   ├─ Valide MIME types
   ├─ Vérifie limites taille
   └─ Stocke fichier physiquement
   ↓
req.file / req.files + req.body populés
   ↓
ROUTE HANDLER
   └─ Traitement métier
```

### 1.2 Ce que reçoit le serveur - Anatomie du flux HTTP

```
Request brute:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

POST /api/upload HTTP/1.1
Host: localhost:3000
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary
Content-Length: 524288

------WebKitFormBoundary
Content-Disposition: form-data; name="file"; filename="document.pdf"
Content-Type: application/pdf

[BINARY DATA - PDF FILE]
------WebKitFormBoundary
Content-Disposition: form-data; name="title"

My Document
------WebKitFormBoundary--

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Sans Multer:
  req.body = {} (vide)
  req.file = undefined
  req.files = undefined
  Fichier = PERDU EN MÉMOIRE

Avec Multer:
  req.file = {
    fieldname: 'file',
    originalname: 'document.pdf',
    encoding: '7bit',
    mimetype: 'application/pdf',
    destination: '/uploads',
    filename: '1716139200000-document.pdf',
    path: '/uploads/1716139200000-document.pdf',
    size: 250000
  }
  req.body = {
    title: 'My Document'
  }
  Fichier = SAUVEGARDÉ PHYSIQUEMENT
```

### 1.3 Timeline d'une requête

```
T0ms   ┌─ Navigateur crée FormData()
       │
T5ms   ├─ FormData.append('file', blob, 'test.pdf')
       ├─ FormData.append('title', 'Test')
       │
T10ms  ├─ fetch('POST /api/upload', { body: formData })
       ├─ Browser encode multipart/form-data
       │
T15ms  ├─ HTTP transmission start (TCP handshake)
       │
T100ms ├─ Express reçoit raw bytes
       │  req.on('data', chunk => { /* buffer chunks */ })
       │
T150ms ├─ MULTER INTERCEPTE
       │  ├─ Parse boundary markers
       │  ├─ Extrait headers pour chaque part
       │  ├─ Identifie: file vs form fields
       │  │
       │  Pour file:
       │  ├─ Lit Content-Disposition: name="file"; filename="test.pdf"
       │  ├─ Lit Content-Type: application/pdf
       │  ├─ Valide MIME type
       │  ├─ Vérifie taille < maxSize
       │  ├─ Crée stream d'écriture vers disk
       │  ├─ Write binary chunks to disk
       │  │
       │  Pour form fields:
       │  ├─ Accumule text data
       │  ├─ Population req.body
       │
T200ms ├─ Multer.diskStorage appelle callback
       │  filename: '1716139200000-test.pdf'
       │  destination: './uploads'
       │
T250ms ├─ Fichier sauvegardé à:
       │  /home/app/uploads/1716139200000-test.pdf
       │
T300ms ├─ req.file + req.body prêts
       ├─ Appel route handler
       │
T350ms ├─ Route handler traite métier
       │  ├─ Sauvegarde métadonnées en DB
       │  ├─ Génération URL accès
       │  │
T400ms ├─ Response envoyée
       │  { success: true, fileId: 123 }
       │
T410ms └─ Client reçoit réponse
```

## 2. CYCLE COMPLET D'UPLOAD

### 2.1 Architecture Full-Stack

```
┌─────────────────────────────────────────────────────────────────┐
│                     FRONTEND (React/Next.js)                    │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ Component:                                               │   │
│ │  <input type="file" />  +  useState(file)              │   │
│ │                                                          │   │
│ │ FormData construction:                                 │   │
│ │  const fd = new FormData()                             │   │
│ │  fd.append('file', file)                              │   │
│ │  fd.append('metadata', JSON.stringify(meta))         │   │
│ │                                                          │   │
│ │ Request:                                               │   │
│ │  fetch('/api/documents/upload', {                     │   │
│ │    method: 'POST',                                     │   │
│ │    body: fd  // Navigateur: multipart/form-data       │   │
│ │  })                                                     │   │
│ └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ HTTP POST (multipart/form-data)
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (Express/NestJS)                     │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ 1. Multer Middleware                                     │   │
│ │    - Parse multipart boundaries                         │   │
│ │    - Valide MIME type (application/pdf)                │   │
│ │    - Vérifie limites taille (10MB max)                 │   │
│ │    - Applique diskStorage                              │   │
│ │    → Crée stream d'écriture                            │   │
│ │    → Fichier stocké: /uploads/uploads/[UUID].pdf     │   │
│ │    → Popule req.file, req.body                         │   │
│ │                                                          │   │
│ │ 2. Route Handler                                        │   │
│ │    - req.file.filename = '1716139200000-doc.pdf'      │   │
│ │    - req.body = { title: 'Mon PDF' }                   │   │
│ │                                                          │   │
│ │ 3. Service Layer                                        │   │
│ │    - Génère URL accès: /files/uploads/[UUID].pdf      │   │
│ │    - Hash SHA256 du fichier                            │   │
│ │    - Dimensions image (si applicable)                  │   │
│ │                                                          │   │
│ │ 4. Database (Prisma + PostgreSQL)                      │   │
│ │    ```sql                                               │   │
│ │    INSERT INTO documents (                              │   │
│ │      title, file_path, file_url,                       │   │
│ │      mime_type, file_size, storage_hash                │   │
│ │    ) VALUES (                                           │   │
│ │      'Mon PDF', '/uploads/[UUID].pdf',                │   │
│ │      'https://api.example.com/files/uploads/[UUID]',  │   │
│ │      'application/pdf', 250000,                        │   │
│ │      'sha256_hash_here'                                │   │
│ │    )                                                    │   │
│ │    ```                                                   │   │
│ │                                                          │   │
│ │ 5. Response                                             │   │
│ │    {                                                    │   │
│ │      documentId: 123,                                  │   │
│ │      fileUrl: 'https://api.example.com/files/...',    │   │
│ │      status: 'success'                                 │   │
│ │    }                                                    │   │
│ └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ JSON Response + file_url
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                   STORAGE LAYER                                 │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ Disk Structure:                                          │   │
│ │ /home/app/                                              │   │
│ │ ├── uploads/                                            │   │
│ │ │   ├── 1716139200000-doc.pdf  (250KB)                 │   │
│ │ │   ├── 1716139200001-img.jpg  (2.5MB)                 │   │
│ │ │   └── 1716139200002-video.mp4  (500MB)               │   │
│ │ ├── thumbnails/  (cachés)                              │   │
│ │ └── temp/  (uploads incomplets)                        │   │
│ │                                                          │   │
│ │ Métadonnées en PostgreSQL:                             │   │
│ │ documents {                                             │   │
│ │   id: 123                                               │   │
│ │   title: 'Mon PDF'                                      │   │
│ │   file_path: '/uploads/1716139200000-doc.pdf'         │   │
│ │   file_url: 'https://api.example.com/files/...'       │   │
│ │   mime_type: 'application/pdf'                         │   │
│ │   file_size: 250000                                    │   │
│ │   storage_hash: 'abc123def456...'                      │   │
│ │   created_at: 2026-05-19                               │   │
│ │ }                                                        │   │
│ └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ Fichier physique sauvegardé + métadonnées en DB
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│                 RETRIEVAL & SERVING                             │
│ ┌──────────────────────────────────────────────────────────┐   │
│ │ GET /files/uploads/1716139200000-doc.pdf                │   │
│ │                                                          │   │
│ │ 1. Middleware d'authentification                        │   │
│ │ 2. Lookup en DB → vérification permissions             │   │
│ │ 3. Streaming depuis disk                               │   │
│ │    res.sendFile('/uploads/1716139200000-doc.pdf')     │   │
│ │ 4. Headers:                                             │   │
│ │    Content-Type: application/pdf                        │   │
│ │    Content-Length: 250000                               │   │
│ │    Content-Disposition: attachment; filename="..."     │   │
│ │ 5. Binaire streamé au client                           │   │
│ │                                                          │   │
│ │ Cache:                                                  │   │
│ │ - ETag basé sur storage_hash                           │   │
│ │ - Cache-Control: private, max-age=31536000            │   │
│ └──────────────────────────────────────────────────────────┘   │
└────────────────────────┬──────────────────────────────────────────┘
                         │
                         │ PDF téléchargé
                         ↓
                    UTILISATEUR
```

## 3. MODES DE STOCKAGE MULTER - ANALYSE COMPLÈTE

### 3.1 diskStorage

```javascript
// Production-grade configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Logique dynamique pour destination
    const uploadDir = determineUploadDir(req);
    // Créer dir si inexistant
    fs.mkdirSync(uploadDir, { recursive: true });
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    // Strategy: [timestamp]-[random]-[originalname]
    // Évite collisions et sécurité
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    const filename = file.fieldname + '-' + uniqueSuffix + 
                     path.extname(file.originalname);
    cb(null, filename);
  }
});

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 100 * 1024 * 1024,  // 100MB
    files: 10,                     // Max 10 fichiers simultané
    fields: 50                     // Max 50 champs form
  },
  fileFilter: (req, file, cb) => {
    // Valider MIME type
    const allowed = ['application/pdf', 'image/jpeg', 'image/png'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('MIME type not allowed'));
    }
  }
});

// AVANTAGES:
// ✓ Simple, direct, performant
// ✓ Fichiers persistants localement
// ✓ Pas de dépendance externe
// ✓ Idéal pour développement
// ✓ Accès rapide (I/O local)

// INCONVÉNIENTS:
// ✗ Scalabilité: un seul serveur/disque
// ✗ Pas de réplication
// ✗ Problématique si disque plein
// ✗ Coût de maintenance stockage
// ✗ Sauvegarde manuelle nécessaire
// ✗ Pas de multi-régions

// CAS D'USAGE:
// • MVP / POC
// • Applications monolithe
// • Développement local
// • Petits projets (<1000 users)
// • Assets de petite taille

// LIMITES PRODUCTION:
// • Maximum ~1-2TB par serveur pratiquement
// • Vitesse dégradée après ~100k fichiers/dossier
// • Pas de haute disponibilité
// • RTO/RPO faibles sans backup externe
```

### 3.2 memoryStorage

```javascript
const upload = multer({
  storage: multer.memoryStorage()
});

// Quand utilisé:
app.post('/api/quick-process', upload.single('file'), (req, res) => {
  // req.file.buffer contient les données binaires
  // PAS DE fichier sauvegardé sur disque
  
  console.log('File in memory:', {
    fieldname: req.file.fieldname,
    originalname: req.file.originalname,
    encoding: req.file.encoding,
    mimetype: req.file.mimetype,
    size: req.file.size,
    buffer: req.file.buffer  // <-- Buffer (données binaires)
  });
  
  // Utilisation commune:
  // 1. Upload + traitement immédiat
  // 2. Compression avant stockage
  // 3. Génération miniatures
  // 4. Envoi vers service externe (S3, etc.)
  
  // Exemple: Upload → S3
  const s3 = new AWS.S3();
  s3.upload({
    Bucket: 'my-bucket',
    Key: `uploads/${Date.now()}-${req.file.originalname}`,
    Body: req.file.buffer,
    ContentType: req.file.mimetype
  }, (err, data) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    // Fichier supprimé automatiquement après réponse
    // Mémoire libérée
    res.json({ s3Url: data.Location });
  });
});

// AVANTAGES:
// ✓ Très rapide (pas I/O disque)
// ✓ Ideal pour petits fichiers
// ✓ Traitement immédiat possible
// ✓ Pas de cleanup disque nécessaire

// INCONVÉNIENTS:
// ✗ Mémoire RAM = limitation critique
// ✗ Chaque requête consomme RAM
// ✗ Crash serveur = perte données
// ✗ Problème si plusieurs uploads simultanés
// ✗ Pas persistance

// LIMITES PRODUCTION:
// • Max fichier = RAM disponible - overhead système
// • 4GB RAM serveur → max ~1-2 fichiers 100MB simultané
// • 100 uploads simultanés 10MB → 1GB RAM utilisée
// • Garbage collection peut causer lag
```

### 3.3 Stockage personnalisé (S3/MinIO)

```javascript
// Custom storage: Upload vers S3 directement
const AWS = require('aws-sdk');
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY,
  secretAccessKey: process.env.AWS_SECRET_KEY,
  region: 'us-east-1'
});

class S3Storage {
  constructor(options = {}) {
    this.bucket = options.bucket;
    this.region = options.region || 'us-east-1';
  }

  _handleFile(req, file, cb) {
    const key = `uploads/${Date.now()}-${file.originalname}`;
    
    const params = {
      Bucket: this.bucket,
      Key: key,
      Body: file.stream,  // Stream direct depuis réseau
      ContentType: file.mimetype,
      ACL: 'private',
      // Métadonnées
      Metadata: {
        originalname: file.originalname,
        mimetype: file.mimetype,
        uploader: req.user?.id
      }
    };

    s3.upload(params, (err, data) => {
      if (err) return cb(err);
      
      // Callback avec métadonnées S3
      cb(null, {
        bucket: this.bucket,
        key: key,
        location: data.Location,  // https://bucket.s3.region.amazonaws.com/key
        etag: data.ETag,
        size: file.size,
        mimetype: file.mimetype
      });
    });
  }

  _removeFile(req, file, cb) {
    // Optionnel: cleanup si upload échoue
    s3.deleteObject({
      Bucket: this.bucket,
      Key: file.key
    }, cb);
  }
}

const s3Storage = new S3Storage({ bucket: 'my-app-uploads' });
const upload = multer({ storage: s3Storage });

// AVANTAGES:
// ✓ Scalabilité illimitée
// ✓ Durabilité (11 9s avec S3)
// ✓ Multi-régions possibles
// ✓ Versioning possible
// ✓ CDN intégré (CloudFront)
// ✓ Serverless compatible

// INCONVÉNIENTS:
// ✗ Coût AWS (par GB + requête)
// ✗ Latence réseau (100-500ms)
// ✗ Complexité authentification
// ✗ Dépendance AWS

// LIMITES PRODUCTION:
// • Coût: ~$0.023/GB/mois (us-east-1)
// • Requests: $0.0004 per 1000 PUT (8GB jour = ~$100/mois)
// • Latence: 100-300ms vs 1-5ms disk
// • Bande passante sortante: $0.09/GB
```

### 3.4 Streaming

```javascript
// Streaming = traitement pendant la réception
// Pas de "rechargement en mémoire" ou "sauvegarde complète"
// Données traitées au fur et mesure du transfert

const fsm = require('fsm-stream-mapper');

const upload = multer({
  storage: multer.memoryStorage(),
  fileFilter: (req, file, cb) => {
    // Validation pendant stream (early rejection)
    if (file.size > 100 * 1024 * 1024) {
      return cb(new Error('File too large'));
    }
    cb(null, true);
  }
});

// Exemple 1: Upload vers S3 avec streaming
app.post('/api/upload-stream-s3', upload.single('file'), async (req, res) => {
  const pass = new PassThrough();
  
  // Déclencher upload S3 immédiatement
  s3.upload({
    Bucket: 'my-bucket',
    Key: `uploads/${Date.now()}-${req.file.originalname}`,
    Body: pass,  // Stream S3 reçoit données au fur et mesure
    ContentType: req.file.mimetype
  }).promise()
    .then(data => res.json({ location: data.Location }))
    .catch(err => res.status(500).json({ error: err.message }));
  
  // Mais ici on a req.file.buffer (memoryStorage)
  // Pour vrai streaming, utiliser custom storage
});

// Exemple 2: Vrai streaming avec custom storage
class StreamingS3Storage {
  _handleFile(req, file, cb) {
    const pass = new PassThrough();
    
    const params = {
      Bucket: 'my-bucket',
      Key: `uploads/${Date.now()}-${file.originalname}`,
      Body: pass,
      ContentType: file.mimetype
    };

    const upload = s3.upload(params);
    
    // file.stream = RequestStream depuis client
    // Direct pipeline vers S3
    file.stream
      .pipe(upload)  // Données streamées directement
      .on('error', err => cb(err))
      .on('finish', (data) => {
        cb(null, {
          bucket: params.Bucket,
          key: params.Key,
          location: upload.Location,
          size: file.size
        });
      });
  }

  _removeFile(req, file, cb) { cb(); }
}

// AVANTAGES:
// ✓ Mémoire constante (O(1) vs O(filesize))
// ✓ Très rapide (pas d'attente fin transfert)
// ✓ Scalable à gros fichiers (500GB+)
// ✓ Traitement parallelisable

// INCONVÉNIENTS:
// ✗ Erreurs en milieu de flux = fichier corrompu
// ✗ Plus complexe à implémenter
// ✗ Validation posteriori difficile
// ✗ Cleanup si échoue = tricky

// UTILISATION PRODUCTION:
// • Gros fichiers (>500MB)
// • Vidéos, archives compressées
// • S3/cloud requis
// • API haute performance
```

### 3.5 Comparaison stratégies

```
┌─────────────────┬──────────────────────────────────────────────────┐
│ Mode            │ Cas d'usage                                      │
├─────────────────┼──────────────────────────────────────────────────┤
│ diskStorage     │ MVP, dev, petites apps, assets < 100MB           │
│ memoryStorage   │ Fichiers <10MB, traitement immédiat, cache      │
│ S3/Cloud        │ Production, scalabilité, gros fichiers, CDN      │
│ Streaming       │ Très gros fichiers, ressources limitées         │
│ MinIO (local)   │ Production locale, S3-compatible, données privées │
└─────────────────┴──────────────────────────────────────────────────┘

Comparaison performance:

                 Latency    Memory   Scalability  Cost   Durability
                 ─────────  ────────  ─────────   ───    ──────────
diskStorage      1ms        O(1)      Local       Low    Low
memoryStorage    0.1ms      O(size)   Single      None   None
S3               100ms      O(1)      Unlimited   High   Very High
MinIO            5ms        O(1)      Cluster     Med    Medium
Streaming+S3     100ms      O(1)      Unlimited   High   Very High
```

---

## 4. CONFIGURATION COMPLÈTE PRODUCTION

### 4.1 Base : diskStorage sécurisée

```javascript
// backend/config/multer.config.js
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');

// Répertoires sécurisés
const UPLOAD_DIR = path.join(__dirname, '../../../uploads');
const TEMP_DIR = path.join(UPLOAD_DIR, 'temp');

// Créer dirs
[UPLOAD_DIR, TEMP_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true, mode: 0o755 });
  }
});

// Configuration sécurisée
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    // Dossier temporaire pour upload en cours
    // Déplacement vers final après validation
    cb(null, TEMP_DIR);
  },
  filename: (req, file, cb) => {
    // Nommage sécurisé: pas d'infos sensitives
    // Format: [timestamp]-[random]-[hash]
    const timestamp = Date.now();
    const random = crypto.randomBytes(8).toString('hex');
    const ext = path.extname(file.originalname);
    const filename = `${timestamp}-${random}${ext}`;
    cb(null, filename);
  }
});

// MIME types acceptés (whitelist stricte)
const ALLOWED_MIMES = {
  documents: ['application/pdf', 'application/msword', 
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document'],
  images: ['image/jpeg', 'image/png', 'image/webp'],
  videos: ['video/mp4', 'video/quicktime'],
  archives: ['application/zip', 'application/x-rar-compressed']
};

// Validation fichiers
const fileFilter = (req, file, cb) => {
  // 1. Vérifier MIME type
  const isValidMime = Object.values(ALLOWED_MIMES)
    .flat()
    .includes(file.mimetype);
  
  if (!isValidMime) {
    return cb(new Error(`MIME type '${file.mimetype}' not allowed`));
  }

  // 2. Vérifier extension (double vérification)
  const ext = path.extname(file.originalname).toLowerCase();
  const allowedExts = ['.pdf', '.doc', '.docx', '.jpg', '.png', '.zip'];
  
  if (!allowedExts.includes(ext)) {
    return cb(new Error(`File extension '${ext}' not allowed`));
  }

  // 3. Vérifier nom fichier (pas de path traversal)
  if (file.originalname.includes('..') || file.originalname.includes('/')) {
    return cb(new Error('Invalid filename characters'));
  }

  cb(null, true);
};

// Instance Multer
const upload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024,  // 100MB max par fichier
    files: 10,                     // 10 fichiers max par requête
    fields: 50                     // 50 champs max
  }
});

module.exports = { upload, UPLOAD_DIR, TEMP_DIR, ALLOWED_MIMES };
```

### 4.2 Upload simple

```javascript
// routes/documentRoute.js
const express = require('express');
const router = express.Router();
const { upload } = require('../config/multer.config');
const documentController = require('../controllers/documentController');
const { authenticateToken } = require('../middlewares/authenticateToken');

// Upload simple fichier
router.post(
  '/upload',
  authenticateToken,
  upload.single('file'),  // Field name: 'file'
  documentController.handleUpload
);

// Controller
// controllers/documentController.js
const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');
const { prisma } = require('../config/prisma');

exports.handleUpload = async (req, res) => {
  try {
    // 1. Multer a fourni req.file
    if (!req.file) {
      return res.status(400).json({ error: 'No file provided' });
    }

    const { file } = req;
    const { title, description } = req.body;

    // 2. Calcul hash SHA256 pour intégrité
    const fileContent = await fs.readFile(file.path);
    const fileHash = crypto.createHash('sha256')
      .update(fileContent)
      .digest('hex');

    // 3. Déplacer du temp vers final
    const filename = `${Date.now()}-${file.filename}`;
    const finalPath = path.join(
      path.dirname(file.path),
      '..',
      filename
    );
    
    await fs.rename(file.path, finalPath);

    // 4. Sauvegarder métadonnées en DB
    const document = await prisma.document.create({
      data: {
        title: title || file.originalname,
        description,
        fileName: filename,
        filePath: finalPath,
        fileUrl: `/files/documents/${filename}`,
        mimeType: file.mimetype,
        fileSize: file.size,
        storageHash: fileHash,
        userId: req.user.id
      }
    });

    // 5. Response
    res.status(201).json({
      success: true,
      document: {
        id: document.id,
        title: document.title,
        fileUrl: document.fileUrl,
        fileSize: document.fileSize
      }
    });

  } catch (error) {
    // Cleanup en cas d'erreur
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    res.status(500).json({ error: error.message });
  }
};
```

### 4.3 Upload multiple

```javascript
// Route: upload jusqu'à 5 fichiers
router.post(
  '/upload-multiple',
  authenticateToken,
  upload.array('files', 5),  // Max 5 fichiers, field name: 'files'
  async (req, res) => {
    try {
      if (!req.files || req.files.length === 0) {
        return res.status(400).json({ error: 'No files provided' });
      }

      const uploadedDocs = [];

      for (const file of req.files) {
        // Même logique que handleUpload simple
        const fileHash = crypto.createHash('sha256')
          .update(await fs.readFile(file.path))
          .digest('hex');

        const filename = `${Date.now()}-${file.filename}`;
        const finalPath = path.join(
          path.dirname(file.path),
          '..',
          filename
        );
        
        await fs.rename(file.path, finalPath);

        const doc = await prisma.document.create({
          data: {
            title: file.originalname,
            fileName: filename,
            filePath: finalPath,
            mimeType: file.mimetype,
            fileSize: file.size,
            storageHash: fileHash,
            userId: req.user.id
          }
        });

        uploadedDocs.push(doc);
      }

      res.status(201).json({
        success: true,
        count: uploadedDocs.length,
        documents: uploadedDocs
      });

    } catch (error) {
      // Cleanup tous les fichiers temporaires
      if (req.files) {
        await Promise.all(
          req.files.map(f => fs.unlink(f.path).catch(() => {}))
        );
      }
      res.status(500).json({ error: error.message });
    }
  }
);
```

### 4.4 Upload champs mixtes (fichier + metadata)

```javascript
// Exemple: document PDF + extra fields
router.post(
  '/upload-with-metadata',
  authenticateToken,
  upload.fields([
    { name: 'document', maxCount: 1 },
    { name: 'thumbnail', maxCount: 1 }
  ]),
  async (req, res) => {
    try {
      const { document, thumbnail } = req.files;
      const { title, category, tags } = req.body;

      if (!document || document.length === 0) {
        return res.status(400).json({ error: 'Document required' });
      }

      // Traiter document principal
      const docFile = document[0];
      // ... même logique hash/move/save ...

      // Traiter thumbnail optionnel
      if (thumbnail && thumbnail.length > 0) {
        const thumbFile = thumbnail[0];
        // ... traitement image ...
      }

      res.status(201).json({ success: true });

    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  }
);
```

### 4.5 Upload vidéo haute résolution

```javascript
const ffmpeg = require('fluent-ffmpeg');

router.post(
  '/upload-video',
  authenticateToken,
  upload.single('video'),
  async (req, res) => {
    try {
      const { file } = req;
      
      // Vérifier vidéo valide
      if (!file.mimetype.startsWith('video/')) {
        await fs.unlink(file.path);
        return res.status(400).json({ error: 'Not a video file' });
      }

      // Vérifier durée (ex: max 1h)
      const duration = await new Promise((resolve, reject) => {
        ffmpeg.ffprobe(file.path, (err, metadata) => {
          if (err) return reject(err);
          resolve(metadata.format.duration);
        });
      });

      if (duration > 3600) {
        await fs.unlink(file.path);
        return res.status(400).json({ 
          error: 'Video too long (max 1 hour)' 
        });
      }

      // Sauvegarder métadonnées
      const video = await prisma.video.create({
        data: {
          title: req.body.title,
          fileName: file.filename,
          filePath: file.path,
          mimeType: file.mimetype,
          fileSize: file.size,
          duration: duration,
          userId: req.user.id,
          processingStatus: 'PENDING'  // Queue pour traitement
        }
      });

      // Déclencher job d'encodage (voir section Redis)
      await videoProcessingQueue.add({
        videoId: video.id,
        filePath: file.path
      });

      res.status(201).json({
        success: true,
        videoId: video.id,
        message: 'Video uploaded, processing started'
      });

    } catch (error) {
      if (req.file) await fs.unlink(req.file.path).catch(() => {});
      res.status(500).json({ error: error.message });
    }
  }
);
```

### 4.6 Upload image avec validation avancée

```javascript
const sharp = require('sharp');

router.post(
  '/upload-image',
  authenticateToken,
  upload.single('image'),
  async (req, res) => {
    try {
      const { file } = req;

      // 1. Vérifier c'est vraiment une image (magic bytes)
      const metadata = await sharp(file.path).metadata();
      
      if (!['jpeg', 'png', 'webp'].includes(metadata.format)) {
        await fs.unlink(file.path);
        return res.status(400).json({ error: 'Invalid image format' });
      }

      // 2. Vérifier dimensions
      if (metadata.width > 4000 || metadata.height > 4000) {
        await fs.unlink(file.path);
        return res.status(400).json({ error: 'Image too large' });
      }

      // 3. Créer miniature
      const thumbnail = await sharp(file.path)
        .resize(200, 200, { fit: 'cover' })
        .toBuffer();

      const thumbFilename = `thumb-${file.filename}`;
      const thumbPath = path.join(path.dirname(file.path), thumbFilename);
      
      await fs.writeFile(thumbPath, thumbnail);

      // 4. Sauvegarder
      const image = await prisma.image.create({
        data: {
          title: req.body.title,
          fileName: file.filename,
          filePath: file.path,
          thumbnailPath: thumbPath,
          mimeType: file.mimetype,
          fileSize: file.size,
          width: metadata.width,
          height: metadata.height,
          userId: req.user.id
        }
      });

      res.status(201).json({
        success: true,
        image: {
          id: image.id,
          imageUrl: `/files/images/${image.fileName}`,
          thumbnailUrl: `/files/images/${thumbFilename}`
        }
      });

    } catch (error) {
      if (req.file) await fs.unlink(req.file.path).catch(() => {});
      res.status(500).json({ error: error.message });
    }
  }
);
```

### 4.7 Frontend React

```typescript
// Frontend React upload
import React, { useState } from 'react';
import axios from 'axios';

export function DocumentUpload() {
  const [file, setFile] = useState<File | null>(null);
  const [title, setTitle] = useState('');
  const [loading, setLoading] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleUpload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) return;

    const formData = new FormData();
    formData.append('file', file);
    formData.append('title', title);

    try {
      setLoading(true);
      
      const response = await axios.post('/api/documents/upload', formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
        onUploadProgress: (progressEvent) => {
          const percentCompleted = Math.round(
            (progressEvent.loaded * 100) / (progressEvent.total || 1)
          );
          setProgress(percentCompleted);
        }
      });

      console.log('Upload success:', response.data);
      // Reset form
      setFile(null);
      setTitle('');
      setProgress(0);

    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleUpload}>
      <input
        type="file"
        onChange={(e) => setFile(e.target.files?.[0] || null)}
        disabled={loading}
      />
      <input
        type="text"
        placeholder="Document title"
        value={title}
        onChange={(e) => setTitle(e.target.value)}
        disabled={loading}
      />
      <button type="submit" disabled={loading || !file}>
        {loading ? `Uploading... ${progress}%` : 'Upload'}
      </button>
    </form>
  );
}
```

---

## 5. SÉCURITÉ DES UPLOADS

### 5.1 Menaces et mitigations

```
MENACE 1: MIME SPOOFING
━━━━━━━━━━━━━━━━━━━━━━━
Attaquant upload fichier executable avec extension .pdf

Exemple:
  ├─ Fichier: malware.exe
  ├─ Renommé: malware.pdf
  ├─ Content-Type header: application/pdf (faux!)
  └─ Serveur accepte car se fie à Content-Type

MITIGATIONS:
  ✓ Vérifier magic bytes (premiers octets fichier)
  ✓ Utiliser library: file-type ou sharp
  ✓ Validator indépendant du client
  ✓ Extension whitelist stricte

const fileType = require('file-type');

fileFilter = async (req, file, cb) => {
  const buffer = await file.stream.slice(0, 4100);  // Premiers 4KB
  const type = await fileType.fromBuffer(buffer);
  
  if (!type || !ALLOWED_MIMES.includes(type.mime)) {
    return cb(new Error('File type mismatch'));
  }
  cb(null, true);
};

MENACE 2: PATH TRAVERSAL
━━━━━━━━━━━━━━━━━━━━━━
Attaquant utilise ../ pour écrire hors dossier upload

Exemple:
  filename: "../../etc/passwd"  ou  "../../../sensitive.pdf"
  → Écriture en root au lieu de /uploads

MITIGATIONS:
  ✓ Sanitizer tous les noms fichiers
  ✓ Générer noms aléatoires côté serveur
  ✓ Ne JAMAIS faire confiance originalname
  ✓ Path validation strict

// MAUVAIS ❌
const dest = path.join(UPLOAD_DIR, file.originalname);

// BON ✅
const safeFilename = sanitizeFilename(file.originalname);
const filename = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}`;
const dest = path.join(UPLOAD_DIR, filename);

// Vérifier path ne sort pas du dossier
const resolved = path.resolve(dest);
if (!resolved.startsWith(path.resolve(UPLOAD_DIR))) {
  throw new Error('Path traversal detected');
}

MENACE 3: EXÉCUTION DE CODE
━━━━━━━━━━━━━━━━━━━━━━━━
Fichier uploadé côté dossier web-accessible + exécutable

Exemple:
  ├─ Upload: shell.php → /var/www/html/uploads/shell.php
  ├─ Attacker browse: http://example.com/uploads/shell.php
  └─ Code PHP exécuté, RCE (Remote Code Execution)

MITIGATIONS:
  ✓ Uploads HORS dossier web-accessible
  ✓ Servir via route endpoint (pas direct filesystem)
  ✓ Désactiver exécution dans dossier uploads
  ✓ Content-Type header strict

// Structure:
/var/www/html/
  ├── app.js
  ├── routes/
  └── public/
      ├── index.html
      └── images/  ← web-accessible

/var/uploads/  ← HORS public (NOT web-accessible)
  ├── document-1.pdf
  └── image-2.jpg

// Servir via endpoint (pas direct)
app.get('/files/:filename', (req, res) => {
  const filePath = path.join('/var/uploads', req.params.filename);
  res.setHeader('Content-Disposition', 'attachment');
  res.setHeader('Content-Type', 'application/octet-stream');
  res.sendFile(filePath);
});

// .htaccess (Apache) pour bloquer exécution
<FilesMatch "\.php$">
  Deny from all
</FilesMatch>

MENACE 4: VIRUS / MALWARE
━━━━━━━━━━━━━━━━━━━━━━
Fichier contient malware, virus, ou contenu dangereux

MITIGATIONS:
  ✓ ClamAV (antivirus open source)
  ✓ VirusTotal API (scan cloud)
  ✓ Sandboxing fichier
  ✓ Quarantine jusqu'à scan

const NodeClam = require('clamscan');

const clamscan = await new NodeClam().init({
  clamdscan: { host: 'localhost', port: 3310 }
});

fileFilter = async (req, file, cb) => {
  const { isInfected } = await clamscan.scanFile(file.path);
  
  if (isInfected) {
    await fs.unlink(file.path);
    return cb(new Error('File infected'));
  }
  cb(null, true);
};

MENACE 5: DENIAL OF SERVICE (DOS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Attaquant upload massive quantité pour saturer disque/mémoire

Exemple:
  ├─ Upload 1000x 100MB fichiers
  ├─ Disque rempli (stockage infini requis)
  ├─ Mémoire serveur saturée
  └─ Service indisponible

MITIGATIONS:
  ✓ Limites taille fichier
  ✓ Limites nombre fichiers/request
  ✓ Rate limiting par user/IP
  ✓ Quota par user
  ✓ Monitoring disque

const rateLimit = require('express-rate-limit');

const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,  // 15 minutes
  max: 10,                    // 10 uploads par user
  message: 'Too many uploads, try again later'
});

app.post('/upload', uploadLimiter, upload.single('file'), handler);

// Multer config
multer({
  limits: {
    fileSize: 100 * 1024 * 1024,  // 100MB max
    files: 5,                      // 5 fichiers simultané
    fields: 50
  }
});

// Quota utilisateur (DB)
const userUploadedSize = await prisma.document.aggregate({
  where: { userId: req.user.id },
  _sum: { fileSize: true }
});

const userQuota = 5 * 1024 * 1024 * 1024;  // 5GB par user
const usedSize = userUploadedSize._sum.fileSize || 0;

if (usedSize + file.size > userQuota) {
  return res.status(413).json({ error: 'Quota exceeded' });
}

MENACE 6: INFORMATION DISCLOSURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Fichiers peuvent contenir métadonnées sensibles (EXIF images, props PDF, etc.)

MITIGATIONS:
  ✓ Stripper métadonnées
  ✓ Recompresser images
  ✓ Re-encoder vidéos
  
const sharp = require('sharp');

const cleanedImage = await sharp(file.path)
  .withMetadata(false)  // Enlève EXIF
  .toBuffer();

await fs.writeFile(finalPath, cleanedImage);
```

---

## 6. ARCHITECTURE PRODUCTION - COMPARAISON COMPLÈTE

### 6.1 Option A: Disque Local

```
Architecture:
━━━━━━━━━━━━

          ┌─────────────────────────┐
          │   Frontend (React)       │
          │  upload via fetch()      │
          └────────────┬─────────────┘
                       │ multipart/form-data
                       ↓
          ┌─────────────────────────┐
          │  Express Server         │
          │  ├─ Multer diskStorage  │
          │  └─ Save to /uploads/   │
          └────────────┬─────────────┘
                       │ fs.writeFile()
                       ↓
          ┌─────────────────────────┐
          │   Local Filesystem      │
          │  /var/app/uploads/      │
          │  ├─ doc1.pdf (250MB)    │
          │  ├─ img2.jpg (5MB)      │
          │  └─ video3.mp4 (500MB)  │
          └─────────────────────────┘

Schéma stockage:

Server         Disque Local        DB (PostgreSQL)
┌─────────┐  ┌──────────────────┐  ┌─────────────┐
│Express  │  │/var/app/uploads/ │  │documents    │
│Multer   │─→│                  │  ├─────────────┤
│         │  │├─ 123456-doc.pdf │→→│fileName     │
│         │  │├─ 234567-img.jpg │  │filePath     │
│         │  │└─ 345678-video   │  │fileSize     │
└─────────┘  └──────────────────┘  └─────────────┘


AVANTAGES:
  ✓ Simple (zéro dépendances)
  ✓ Rapide (latency 1-5ms)
  ✓ Bon marché (juste disque)
  ✓ Offline possible
  ✓ Dev/test facile

INCONVÉNIENTS:
  ✗ Un seul serveur = SPOF
  ✗ Pas scalable horizontalement
  ✗ Pas de réplication
  ✗ Disque plein = catastrophe
  ✗ Backup manuel
  ✗ Multi-région impossible

CAS D'USAGE:
  • MVP / POC
  • Startup early stage
  • App monolithe
  • Teams < 50 personnes
  • Données non-critiques
  • Assets < 500GB total

LIMITES:
  • Max ~1-2TB disque pratiquement
  • Max ~100k fichiers/dossier
  • Perf dégrade avec age
  • Pas de haute dispo
```

### 6.2 Option B: Stockage Partagé (NFS)

```
Architecture:
━━━━━━━━━━━━

    ┌──────────────┐    ┌──────────────┐
    │Express Srv 1 │    │Express Srv 2 │
    │ Multer       │    │ Multer       │
    └──────┬───────┘    └───────┬──────┘
           │                    │
           └────────┬───────────┘
                    │ NFS mount
                    ↓
           ┌────────────────────┐
           │   NFS Server       │
           │  /exports/uploads/ │
           │  ├─ doc1.pdf       │
           │  ├─ img2.jpg       │
           │  └─ video3.mp4     │
           └────────────────────┘
                    ↑
                    │ iSCSI / FC (optionnel)
           ┌────────────────────┐
           │   Storage Array    │
           │   (RAID-6)         │
           └────────────────────┘

Flux:
Serveur1: /uploads/doc1.pdf → NFS → Remote Storage
Serveur2: /uploads/doc1.pdf ← NFS ← Remote Storage (même fichier)

AVANTAGES:
  ✓ Scalable horizontalement
  ✓ Haute dispo (plusieurs serveurs)
  ✓ Partage centralisé
  ✓ RAID possible (réplication)
  ✓ Snapshots / backup centralisé

INCONVÉNIENTS:
  ✗ Latency NFS (10-50ms vs 1-5ms local)
  ✗ Complexité setup (NFS server)
  ✗ Single point of failure (NFS server)
  ✗ Coût: NFS server + storage dédié
  ✗ Pas de multi-région (même datacenter)
  ✗ Concurrency issues parfois

CAS D'USAGE:
  • Apps monolithe à plusieurs instances
  • Startups échelle moyenne
  • Enterprise infrastructure existant
  • Données semi-critiques
  • Budget < cloud enterprise

LIMITES:
  • Max ~10-50TB pratiquement
  • NFS server devient bottleneck
  • Perf dégradée si latence réseau high
  • Pas geo-distribution
```

### 6.3 Option C: AWS S3

```
Architecture:
━━━━━━━━━━━━

┌─────────────────────────────────────────────────────┐
│                    AWS Region (us-east-1)           │
│  ┌────────────────────────────────────────────────┐ │
│  │            Application (Express)                │ │
│  │  ├─ memoryStorage + stream to S3             │ │
│  │  └─ SDK: aws-sdk v3                          │ │
│  └────────────────────┬───────────────────────────┘ │
│                       │                             │
│                       │ HTTP/HTTPS                  │
│                       ↓                             │
│  ┌────────────────────────────────────────────────┐ │
│  │         S3 Bucket (us-east-1)                  │ │
│  │  uploads/                                      │ │
│  │  ├─ 2026/05/doc1.pdf                          │ │
│  │  ├─ 2026/05/img2.jpg                          │ │
│  │  └─ 2026/05/video3.mp4                        │ │
│  │                                                │ │
│  │  Replication: AZ1, AZ2, AZ3 (auto)            │ │
│  └────────────────────────────────────────────────┘ │
│                       ↑                             │
│                       │                             │
│  ┌────────────────────────────────────────────────┐ │
│  │         CloudFront (CDN)                       │ │
│  │  • Edge locations worldwide                    │ │
│  │  • Cache: 86400s                               │ │
│  │  • GET latency: 10-100ms global                │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘


Code:
━━━━━

const AWS = require('aws-sdk');

const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: 'us-east-1'
});

class S3Storage {
  _handleFile(req, file, cb) {
    const key = `uploads/${new Date().toISOString().split('T')[0]}/${Date.now()}-${file.originalname}`;
    
    const params = {
      Bucket: 'my-app-uploads',
      Key: key,
      Body: file.stream,
      ContentType: file.mimetype,
      ACL: 'private',
      Metadata: {
        'original-name': file.originalname,
        'upload-date': new Date().toISOString()
      },
      // Encryption
      ServerSideEncryption: 'AES256',
      // Storage class pour cost optimization
      StorageClass: 'STANDARD'  // ou 'INTELLIGENT_TIERING'
    };

    s3.upload(params, (err, data) => {
      if (err) return cb(err);
      
      // Générer signed URL pour accès temporaire
      const getUrl = s3.getSignedUrl('getObject', {
        Bucket: params.Bucket,
        Key: key,
        Expires: 3600  // 1 heure
      });

      cb(null, {
        bucket: params.Bucket,
        key: key,
        location: data.Location,
        getUrl: getUrl,
        etag: data.ETag,
        size: file.size
      });
    });
  }

  _removeFile(req, file, cb) {
    s3.deleteObject({
      Bucket: file.bucket,
      Key: file.key
    }, cb);
  }
}

const upload = multer({ storage: new S3Storage() });

// Route
app.post('/upload', upload.single('file'), async (req, res) => {
  const doc = await prisma.document.create({
    data: {
      title: req.body.title,
      s3Key: req.file.key,
      s3Url: req.file.location,  // https://bucket.s3.region.amazonaws.com/key
      downloadUrl: req.file.getUrl,  // Signed URL temporaire
      fileSize: req.file.size,
      userId: req.user.id
    }
  });

  res.json({
    documentId: doc.id,
    downloadUrl: doc.downloadUrl,  // Valid 1h
    publicUrl: `https://cdn.example.com${req.file.key}`  // CloudFront
  });
});


AVANTAGES:
  ✓ Scalabilité infini
  ✓ Durabilité: 11x9s (99.999999999%)
  ✓ Multi-AZ par défaut
  ✓ CloudFront intégré
  ✓ Versioning, lifecycle policies
  ✓ Serverless compatible
  ✓ Enterprise-grade

INCONVÉNIENTS:
  ✗ Coût variable (imprédictible)
  ✗ Latency: 100-300ms vs 1-5ms disk
  ✗ Requêtes additionnelles $ (PUT/GET)
  ✗ Dépendance AWS (vendor lock-in)
  ✗ Complexité authentification (IAM, signatures)
  ✗ Data sovereignty issues possibles

COÛT ESTIMÉ (1TB/mois):
  Storage: 1000 GB × $0.023 = $23/mois
  GET/PUT: 1000 requests × $0.0004 + uploads = ~$50/mois
  Bandwidth: 1000 GB download × $0.09 = $90/mois
  ────────────────────────────────────────────────
  TOTAL: ~$160/mois pour 1TB/mois de trafic

CAS D'USAGE:
  • Production startup/enterprise
  • Apps serverless (Lambda)
  • Scalabilité requise
  • Multi-région stratégique
  • Budget disponible

LIMITES:
  • Pas offline
  • Coût peut être cher à grande échelle
  • Latency réseau inévitable
  • Vendor lock-in
```

### 6.4 Option D: Cloudinary

```
Service managed = upload + transformation + delivery

Architecture:
         ┌──────────────────────┐
         │  Your App (Express)  │
         └──────────┬───────────┘
                    │
                    │ Upload via SDK
                    ↓
         ┌──────────────────────┐
         │  Cloudinary Platform │
         │  • Storage           │
         │  • Transform (resize, │
         │    crop, format)    │
         │  • CDN (global)      │
         │  • Optimization      │
         └──────────────────────┘

Code:
const cloudinary = require('cloudinary').v2;

cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

app.post('/upload', upload.single('image'), async (req, res) => {
  try {
    const result = await cloudinary.uploader.upload(req.file.path, {
      folder: 'my-app/images',
      resource_type: 'image',
      // Auto-optimisation
      quality: 'auto',
      fetch_format: 'auto'
    });

    // Transformations on-the-fly:
    // result.secure_url → original
    // cloudinary.url(result.public_id, {
    //   width: 400,
    //   height: 300,
    //   crop: 'fill',
    //   quality: 'auto',
    //   fetch_format: 'auto'
    // })

    res.json({
      imageUrl: result.secure_url,
      thumbnailUrl: cloudinary.url(result.public_id, {
        width: 200,
        crop: 'thumb'
      })
    });

  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

AVANTAGES:
  ✓ Très simple (SDK fait tout)
  ✓ Transformations intégrées (resize, crop, etc.)
  ✓ CDN global très rapide
  ✓ Compression auto (smart scaling)
  ✓ Responsive images générées automatiquement
  ✓ Pas infrastructure à gérer

INCONVÉNIENTS:
  ✗ Coût: $0.10/1000 transformations
  ✗ Plus cher que S3 long terme
  ✗ Moins flexible que S3
  ✗ Vendor lock-in Cloudinary
  ✗ Limit gratuit: 1000/mois

CAS D'USAGE:
  • Startups early stage
  • Apps image-heavy (media)
  • Pas besoin personnalisation extrême
  • Priorité: speed to market

COÛT ESTIMÉ:
  Free tier: 1000 transformations/mois
  Paid: $99/mois = 1M transformations
  Pour 100k uploads/mois: ~$100/mois
```

### 6.5 Option E: MinIO (Self-hosted S3-compatible)

```
Architecture:
━━━━━━━━━━━━━

┌────────────────────────────────────────────────┐
│          Your Infrastructure (On-Prem/VPS)     │
│  ┌──────────────────────────────────────────┐  │
│  │  Express App                             │  │
│  │  └─ AWS SDK compatible               │  │
│  └──────────────┬─────────────────────────┘  │
│                 │                             │
│                 │ S3-compatible API          │
│                 ↓                             │
│  ┌──────────────────────────────────────────┐  │
│  │  MinIO Cluster                           │  │
│  │  ┌─────────────────────────────────────┐ │  │
│  │  │  MinIO Node 1 (12TB SSD)           │ │  │
│  │  │  ├─ uploads/doc1.pdf              │ │  │
│  │  │  ├─ uploads/img2.jpg              │ │  │
│  │  │  └─ replication to Node 2/3       │ │  │
│  │  └─────────────────────────────────────┘ │  │
│  │  ┌─────────────────────────────────────┐ │  │
│  │  │  MinIO Node 2 (12TB SSD)           │ │  │
│  │  │  (Replica données Node 1)          │ │  │
│  │  └─────────────────────────────────────┘ │  │
│  │  ┌─────────────────────────────────────┐ │  │
│  │  │  MinIO Node 3 (12TB SSD)           │ │  │
│  │  │  (Replica données Node 1)          │ │  │
│  │  └─────────────────────────────────────┘ │  │
│  │                                          │  │
│  │  Capacité: 12TB × 3 = 36TB              │  │
│  │  Durabilité: Erasure Coding 4+2        │  │
│  │  (4 data blocks + 2 parity blocks)      │  │
│  └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘

Code:
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');

const s3Client = new S3Client({
  region: 'us-east-1',
  endpoint: 'http://minio-server:9000',  // MinIO endpoint
  credentials: {
    accessKeyId: process.env.MINIO_ACCESS_KEY,
    secretAccessKey: process.env.MINIO_SECRET_KEY
  },
  forcePathStyle: true  // Important pour MinIO
});

// Code identique à AWS S3
app.post('/upload', upload.single('file'), async (req, res) => {
  const command = new PutObjectCommand({
    Bucket: 'my-app-uploads',
    Key: `uploads/${Date.now()}-${req.file.originalname}`,
    Body: fs.createReadStream(req.file.path),
    ContentType: req.file.mimetype
  });

  try {
    const response = await s3Client.send(command);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

AVANTAGES:
  ✓ S3-compatible (code switch easy)
  ✓ Self-hosted (données propriétaires)
  ✓ Scalable (cluster)
  ✓ Coût marginal (juste hardware)
  ✓ Pas vendor lock-in
  ✓ Erasure coding (durabilité)

INCONVÉNIENTS:
  ✗ Opérational complexity (gérer cluster)
  ✗ Hardware investment up-front
  ✗ Support limité (community)
  ✗ Pas CDN intégré
  ✗ Latency: 10-50ms (données chez toi)

CAS D'USAGE:
  • Enterprise (données sensibles)
  • Organisations très grandes (scale)
  • On-prem infrastructure
  • Compliance stricte (GDPR, etc.)
  • À long terme < coût S3

COÛT ESTIMÉ (5 ans):
  Hardware: 3 × $3000/node = $9000
  Maintenance/ops: $200k/5ans
  Total: ~$200k vs $500k S3 pour même données

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
COMPARAISON RÉSUMÉ:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

|           | Disk | NFS    | S3     | CloudinaryMinIO  |
|-----------|------|--------|--------|----------|--------| 
| Scalab    | Low  | Med    | High   | High     | Med    |
| Latency   | 1ms  | 10ms   | 100ms  | 50ms     | 10ms   |
| HA        | No   | Med    | Yes    | Yes      | Yes    |
| Cost      | Low  | Med    | High   | Med      | Low*   |
| Setup     | Minimal | Med | Low    | Very Low | High   |
| CDN       | No   | No     | Yes    | Yes      | No     |
| Managed   | No   | No     | Yes    | Yes      | No     |

* Low cost long-term, high upfront capital
```

---

## 7. REDIS + QUEUES (ASYNC PROCESSING)

### 7.1 Pourquoi Redis ne stocke pas fichiers

Redis = In-Memory Data Store → Max RAM = limite
Upload via Redis = catastrophe mémoire pour gros fichiers

**USE CASE CORRECT**:
- File stocker sur disque/S3
- Métadonnées temporaires → Redis (1h TTL)
- Job queue → BullMQ (Redis backend)
- Worker fetch et traite fichier depuis disque

### 7.2 Architecture: Upload → Queue → Worker → Processing

```
Upload reçu → Multer diskStorage → DB insert
                                  ↓
                           BullMQ enqueue
                                  ↓
                           Redis queue store
                                  ↓
                    Worker poll queue (1s interval)
                                  ↓
                       Lock job (prevent duplication)
                                  ↓
                  Read fichier depuis disk/S3
                                  ↓
              ffmpeg encode, sharp optimize, etc.
                                  ↓
                      Upload result vers S3
                                  ↓
                    UPDATE DB status = 'READY'
                                  ↓
                     Remove job de Redis queue
                                  ↓
                    WebSocket notify client
```

### 7.3 Implémentation BullMQ + Multer

```javascript
// Enqueue dans controller après upload
const videoProcessingQueue = new Queue('video-processing', redisOptions);

const job = await videoProcessingQueue.add(
  { videoId: 123, filePath: '/uploads/video.mp4' },
  { attempts: 3, backoff: { type: 'exponential', delay: 2000 } }
);

// Worker process
videoProcessingQueue.process(3, async (job) => {
  const { videoId, filePath } = job.data;
  
  job.progress(10);  // Progress report
  
  // Encode video
  await encodeVideoWith ffmpeg(filePath, '/tmp/480p.mp4');
  job.progress(50);
  
  // Upload S3
  const url = await uploadToS3('/tmp/480p.mp4', `videos/${videoId}/480p.mp4`);
  job.progress(90);
  
  // Update DB
  await prisma.video.update({
    where: { id: videoId },
    data: { status: 'READY', processedUrl: url }
  });
  
  job.progress(100);
  return { success: true };
});
```

---

## 8. POSTGRESQL ET MÉTADONNÉES FICHIERS

### 8.1 Pourquoi PAS stocker fichiers en BYTEA

```sql
-- ❌ ANTIPATTERN
CREATE TABLE documents (
  id SERIAL,
  file_data BYTEA  -- 100MB PDF = énorme DB!
);

-- ✓ PATTERN CORRECT
CREATE TABLE documents (
  id SERIAL,
  file_name VARCHAR(255),
  file_path VARCHAR(500),     -- Local path ou S3 key
  file_url VARCHAR(500),      -- Accès URL
  mime_type VARCHAR(100),
  file_size BIGINT,           -- En bytes
  storage_hash VARCHAR(64),   -- SHA256
  status VARCHAR(50),         -- UPLOADED, PROCESSING, READY, FAILED
  created_at TIMESTAMP
);
```

### 8.2 Prisma Schema

```prisma
model Document {
  id        Int     @id @default(autoincrement())
  userId    Int
  
  title       String
  fileName    String      // Pas original name!
  filePath    String      // /uploads/doc.pdf ou S3 key
  fileUrl     String      // URL accès
  mimeType    String
  fileSize    BigInt
  storageHash String      // SHA256 intégrité
  status      String      // UPLOADED | PROCESSING | READY | FAILED
  
  uploadedAt  DateTime @default(now())
  processedAt DateTime?
  deletedAt   DateTime?   // Soft delete
  
  @@index([userId])
  @@index([status])
  @@index([deletedAt])
}
```

---

## 9. ARCHITECTURE MODERNE RECOMMANDÉE

**Tech Stack**:
- Frontend: React 18 + react-dropzone + axios
- Backend: NestJS + Multer + Prisma
- Storage: AWS S3 + CloudFront CDN
- Async: BullMQ (Redis backend)
- Database: PostgreSQL

**Dossiers**:
```
backend/
├── src/modules/documents/
│   ├── controllers/document.controller.ts
│   ├── services/document.service.ts
│   ├── dto/upload-document.dto.ts
│   └── guards/document-ownership.guard.ts
├── src/config/
│   ├── multer.config.ts
│   └── bull.config.ts
├── src/workers/
│   └── video-processor.ts
└── prisma/schema.prisma

uploads/
├── documents/
├── images/
│   ├── originals/
│   └── thumbnails/
└── videos/
    ├── originals/
    └── processed/
```

---

## 10. CAS RÉELS ET ANALYSE CRITIQUE

### MVP (< 1000 users)
- diskStorage simple
- PostgreSQL metadata
- Pas de queue
- **Cost**: ~$25/mth

### Petite Production (1k-10k users)
- diskStorage + backup
- Rate limiting
- MIME validation stricte
- Monitoring disque
- **Cost**: ~$50/mth

### Production Scale (10k+ users)
- AWS S3 + CloudFront
- BullMQ async processing
- Multi-instance backend
- Automated scaling
- **Cost**: $0.02 per GB uploaded (scales with usage)

### Erreurs fréquentes débutants
1. Confiance `originalname` (collisions, traversal)
2. Pas error handling/cleanup
3. memoryStorage pour gros fichiers (OOM)
4. Pas MIME validation
5. Metadata dans filename (dépassement limite OS)
6. Pas concurrency control (DOS)
7. Trop confiance client-side validation

### Compromis: diskStorage vs S3
- **diskStorage**: Simple, $0, limité à ~1TB
- **S3**: Complexe, $40/mth, scalable infini, predictable cost

---

## CHECKLIST PRODUCTION

✓ MIME validation (magic bytes, pas juste header)
✓ File size limits (multer limits + DB)
✓ Rate limiting (prevent DOS)
✓ Error handling + file cleanup on failure
✓ Backup strategy (daily ou S3 redundancy)
✓ Monitoring (disk space, error rates, latency)
✓ Soft deletes + retention policy
✓ Security audit (path traversal, execution)
✓ Test upload, errors, concurrency
✓ Documentation (API, deployment, recovery)

