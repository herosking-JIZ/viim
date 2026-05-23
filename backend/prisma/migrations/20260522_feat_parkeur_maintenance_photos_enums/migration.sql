-- CreateEnum type_maintenance
CREATE TYPE "type_maintenance" AS ENUM ('mecanique', 'electricite', 'carrosserie');

-- CreateEnum maintenance_statut
CREATE TYPE "maintenance_statut" AS ENUM ('en_attente', 'confirmee', 'en_reparation', 'terminee', 'bon_etat');

-- CreateEnum maintenance_urgence
CREATE TYPE "maintenance_urgence" AS ENUM ('basse', 'normale', 'haute');

-- AlterTable journal_parking - Add commentaire
ALTER TABLE "journal_parking" ADD COLUMN "commentaire" TEXT;

-- CreateIndex for journal_parking
CREATE INDEX "idx_journal_parking_parking_date" ON "journal_parking"("id_parking", "date_mouvement");

-- Recreate maintenance table with new structure
-- First, drop the old maintenance table constraints if any
ALTER TABLE "maintenance" DROP CONSTRAINT IF EXISTS "maintenance_id_vehicule_fkey";

-- AlterTable maintenance - Restructure
ALTER TABLE "maintenance"
  ADD COLUMN "id_parking" UUID,
  ADD COLUMN "id_gestionnaire" UUID,
  ADD COLUMN "type" "type_maintenance",
  ADD COLUMN "urgence" "maintenance_urgence" NOT NULL DEFAULT 'normale',
  RENAME COLUMN "statut" TO "statut_old",
  ADD COLUMN "statut" "maintenance_statut" NOT NULL DEFAULT 'en_attente',
  DROP COLUMN "statut_old",
  RENAME COLUMN "date_debut" TO "date_creation",
  RENAME COLUMN "date_fin" TO "date_resolution";

-- Add foreign keys for maintenance
ALTER TABLE "maintenance"
  ADD CONSTRAINT "maintenance_id_parking_fkey" FOREIGN KEY ("id_parking") REFERENCES "parking"("id_parking") ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT "maintenance_id_gestionnaire_fkey" FOREIGN KEY ("id_gestionnaire") REFERENCES "utilisateur"("id_utilisateur") ON DELETE RESTRICT ON UPDATE CASCADE;

-- CreateTable maintenance_step
CREATE TABLE "maintenance_step" (
    "id_step" UUID NOT NULL DEFAULT gen_random_uuid(),
    "id_maintenance" UUID NOT NULL,
    "statut_ancien" "maintenance_statut",
    "statut_nouveau" "maintenance_statut" NOT NULL,
    "commentaire" TEXT,
    "date_transition" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "maintenance_step_pkey" PRIMARY KEY ("id_step")
);

-- CreateTable mouvement_photo
CREATE TABLE "mouvement_photo" (
    "id_photo" UUID NOT NULL DEFAULT gen_random_uuid(),
    "id_mouvement" UUID,
    "id_maintenance" UUID,
    "filename" VARCHAR(255) NOT NULL,
    "fileKey" TEXT NOT NULL,
    "filepath" TEXT,
    "mimeType" VARCHAR(50) NOT NULL,
    "fileSize" BIGINT NOT NULL,
    "uploadedAt" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "mouvement_photo_pkey" PRIMARY KEY ("id_photo")
);

-- CreateIndex for maintenance_step
CREATE INDEX "idx_maintenance_step_maintenance_date" ON "maintenance_step"("id_maintenance", "date_transition");

-- CreateIndex for mouvement_photo
CREATE UNIQUE INDEX "mouvement_photo_fileKey_key" ON "mouvement_photo"("fileKey");
CREATE INDEX "idx_mouvement_photo_mouvement" ON "mouvement_photo"("id_mouvement");
CREATE INDEX "idx_mouvement_photo_maintenance" ON "mouvement_photo"("id_maintenance");

-- CreateIndex for maintenance (update existing)
CREATE INDEX "idx_maintenance_vehicule" ON "maintenance"("id_vehicule");
CREATE INDEX "idx_maintenance_parking" ON "maintenance"("id_parking");
CREATE INDEX "idx_maintenance_statut" ON "maintenance"("statut");

-- AddForeignKey maintenance_step -> maintenance
ALTER TABLE "maintenance_step" ADD CONSTRAINT "maintenance_step_id_maintenance_fkey" FOREIGN KEY ("id_maintenance") REFERENCES "maintenance"("id_maintenance") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey mouvement_photo -> journal_parking
ALTER TABLE "mouvement_photo" ADD CONSTRAINT "mouvement_photo_id_mouvement_fkey" FOREIGN KEY ("id_mouvement") REFERENCES "journal_parking"("id_log") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey mouvement_photo -> maintenance
ALTER TABLE "mouvement_photo" ADD CONSTRAINT "mouvement_photo_id_maintenance_fkey" FOREIGN KEY ("id_maintenance") REFERENCES "maintenance"("id_maintenance") ON DELETE CASCADE ON UPDATE CASCADE;
