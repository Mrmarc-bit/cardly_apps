-- ==============================================================================
-- CARDLY SUPABASE CLOUD DATABASE SCHEMA (ENTERPRISE EDITION)
-- Skema PostgreSQL resmi untuk Sinkronisasi Cloud, Dompet Digital & Dokumen
-- Standar: ISO/IEC 7810 ID-1, Privacy-First Zero-Knowledge, UU PDP / GDPR
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS moddatetime SCHEMA extensions;

-- ==============================================================================
-- 2. MIGRASI & PERBAIKAN UNIQUE CONSTRAINT TABEL EKSISTING
-- ==============================================================================
-- Memastikan tabel 'cards' dan 'documents' yang sudah ada memiliki constraint UNIQUE pada 'id'
-- agar relasi Foreign Key (REFERENCES) pada tabel anak tidak memicu error 42830.
DO $$ BEGIN
  -- 2.1 Perbaikan Kolom profiles jika tabel sudah ada dari setup lama
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'profiles') THEN
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS avatar_url TEXT;
    ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS account_tier TEXT DEFAULT 'free';
  END IF;

  -- 2.2 Perbaikan Unique Constraint cards
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'cards') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'cards_id_unique') THEN
      ALTER TABLE public.cards ADD CONSTRAINT cards_id_unique UNIQUE (id);
    END IF;
  END IF;

  -- 2.3 Perbaikan Unique Constraint documents
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'documents') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'documents_id_unique') THEN
      ALTER TABLE public.documents ADD CONSTRAINT documents_id_unique UNIQUE (id);
    END IF;
  END IF;
END $$;

-- ==============================================================================
-- 3. MODUL IDENTITAS & PENGATURAN (PROFILES & SETTINGS)
-- ==============================================================================

-- 3.1 Profiles Utama
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  account_tier TEXT DEFAULT 'free',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view and edit own profile') THEN
    CREATE POLICY "Users can view and edit own profile"
      ON public.profiles FOR ALL
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- 3.2 User Settings (Preferensi Aplikasi)
CREATE TABLE IF NOT EXISTS public.user_settings (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  theme_mode TEXT DEFAULT 'system',
  accent_color TEXT DEFAULT 'lime',
  is_biometric_enabled BOOLEAN DEFAULT false,
  auto_lock_interval_seconds INT DEFAULT 60,
  mask_sensitive_data_on_preview BOOLEAN DEFAULT true,
  screenshot_protection_active BOOLEAN DEFAULT true,
  cloud_sync_enabled BOOLEAN DEFAULT true,
  auto_backup_frequency TEXT DEFAULT 'weekly',
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_settings' AND policyname = 'Users can manage own settings') THEN
    CREATE POLICY "Users can manage own settings"
      ON public.user_settings FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 3.3 User Devices (Sesi Multi-Device & Push Notifications)
CREATE TABLE IF NOT EXISTS public.user_devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_id TEXT NOT NULL,
  device_model TEXT NOT NULL,
  os_version TEXT NOT NULL,
  app_version TEXT NOT NULL,
  fcm_push_token TEXT,
  is_current_device BOOLEAN DEFAULT false,
  last_active_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, device_id)
);

ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'user_devices' AND policyname = 'Users can manage own devices') THEN
    CREATE POLICY "Users can manage own devices"
      ON public.user_devices FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==============================================================================
-- 4. MODUL DOMPET KARTU (CARDS WALLET)
-- ==============================================================================

-- 4.1 Tabel Cards Utama
CREATE TABLE IF NOT EXISTS public.cards (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  nickname TEXT NOT NULL,
  holder_name TEXT NOT NULL,
  issuer TEXT NOT NULL,
  network TEXT NOT NULL,
  last_four_digits VARCHAR(4) NOT NULL,
  expiry_date TIMESTAMPTZ,
  color_theme TEXT NOT NULL,
  notes TEXT,
  is_contactless BOOLEAN NOT NULL DEFAULT true,
  is_favorite BOOLEAN NOT NULL DEFAULT false,
  is_archived BOOLEAN NOT NULL DEFAULT false,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id, user_id),
  CONSTRAINT cards_id_unique UNIQUE (id),
  CONSTRAINT check_last_four_only CHECK (LENGTH(last_four_digits) <= 4)
);

CREATE INDEX IF NOT EXISTS idx_cards_user_fav ON public.cards(user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_cards_user_archived ON public.cards(user_id, is_archived);

ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can manage their own cards') THEN
    CREATE POLICY "Users can manage their own cards"
      ON public.cards FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 4.2 Card Barcodes & QR Codes (Membership / Loyalty)
CREATE TABLE IF NOT EXISTS public.card_barcodes (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  barcode_format TEXT NOT NULL, -- 'QR_CODE', 'CODE_128', 'EAN_13'
  barcode_value TEXT NOT NULL,
  alt_text_display TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.card_barcodes ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'card_barcodes' AND policyname = 'Users can manage card barcodes') THEN
    CREATE POLICY "Users can manage card barcodes"
      ON public.card_barcodes FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 4.3 Card Custom Fields (Data Ekstra Fleksibel)
CREATE TABLE IF NOT EXISTS public.card_custom_fields (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL REFERENCES public.cards(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  field_label TEXT NOT NULL,
  field_value TEXT NOT NULL,
  is_masked BOOLEAN DEFAULT false,
  sort_order INT DEFAULT 0
);

ALTER TABLE public.card_custom_fields ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'card_custom_fields' AND policyname = 'Users can manage card custom fields') THEN
    CREATE POLICY "Users can manage card custom fields"
      ON public.card_custom_fields FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==============================================================================
-- 5. MODUL DOKUMEN & FOLDER (DOCUMENTS & OCR)
-- ==============================================================================

-- 5.1 Document Folders
CREATE TABLE IF NOT EXISTS public.document_folders (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_folder_id TEXT REFERENCES public.document_folders(id) ON DELETE SET NULL,
  name TEXT NOT NULL,
  icon_name TEXT DEFAULT 'folder',
  color_hex TEXT DEFAULT '#F5F5F3',
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.document_folders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'document_folders' AND policyname = 'Users can manage folders') THEN
    CREATE POLICY "Users can manage folders"
      ON public.document_folders FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 5.2 Tabel Documents Utama
CREATE TABLE IF NOT EXISTS public.documents (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  folder_id TEXT REFERENCES public.document_folders(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  category TEXT NOT NULL,
  masked_number TEXT,
  issuer TEXT,
  issue_date TIMESTAMPTZ,
  expiry_date TIMESTAMPTZ,
  notes TEXT,
  local_file_path TEXT,
  storage_path TEXT,
  file_type TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL DEFAULT 0,
  is_private BOOLEAN NOT NULL DEFAULT false,
  is_ocr_reviewed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id, user_id),
  CONSTRAINT documents_id_unique UNIQUE (id)
);

CREATE INDEX IF NOT EXISTS idx_docs_user_private ON public.documents(user_id, is_private);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can manage their own documents') THEN
    CREATE POLICY "Users can manage their own documents"
      ON public.documents FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 5.3 Document Files (Multi-Page / Lampiran)
CREATE TABLE IF NOT EXISTS public.document_files (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  file_label TEXT DEFAULT 'Halaman 1',
  storage_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  page_number INT DEFAULT 1,
  sha256_checksum TEXT,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.document_files ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'document_files' AND policyname = 'Users can manage document files') THEN
    CREATE POLICY "Users can manage document files"
      ON public.document_files FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 5.4 Document OCR Data (Hasil Ekstraksi Pintar Scanner)
CREATE TABLE IF NOT EXISTS public.document_ocr_data (
  document_id TEXT PRIMARY KEY REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  raw_extracted_text TEXT,
  confidence_score NUMERIC(5,2),
  detected_fields JSONB DEFAULT '{}'::jsonb,
  extracted_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.document_ocr_data ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'document_ocr_data' AND policyname = 'Users can manage OCR data') THEN
    CREATE POLICY "Users can manage OCR data"
      ON public.document_ocr_data FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==============================================================================
-- 6. MODUL PENGINGAT (REMINDERS)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.reminders (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_id TEXT,
  title TEXT NOT NULL,
  reminder_date TIMESTAMPTZ NOT NULL,
  reminder_time TEXT NOT NULL DEFAULT '09:00',
  repetition TEXT NOT NULL DEFAULT 'Tidak berulang',
  lead_time_days INT DEFAULT 7,
  notes TEXT,
  device_notification_active BOOLEAN NOT NULL DEFAULT true,
  hide_title_on_lock_screen BOOLEAN NOT NULL DEFAULT false,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id, user_id),
  CONSTRAINT reminders_id_unique UNIQUE (id)
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_date ON public.reminders(user_id, reminder_date);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'reminders' AND policyname = 'Users can manage their own reminders') THEN
    CREATE POLICY "Users can manage their own reminders"
      ON public.reminders FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==============================================================================
-- 7. MODUL BRANKAS PRIVAT & BACKUP CLOUD
-- ==============================================================================

-- 7.1 Vault Metadata (Zero-Knowledge Key Salt)
CREATE TABLE IF NOT EXISTS public.vault_metadata (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  kdf_salt TEXT NOT NULL,
  kdf_iterations INT DEFAULT 100000,
  vault_status TEXT DEFAULT 'active',
  failed_attempts_count INT DEFAULT 0,
  locked_until TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.vault_metadata ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'vault_metadata' AND policyname = 'Users can manage own vault metadata') THEN
    CREATE POLICY "Users can manage own vault metadata"
      ON public.vault_metadata FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 7.2 Cloud Backups (Snapshot Cadangan Terenkripsi)
CREATE TABLE IF NOT EXISTS public.cloud_backups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  device_name TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  checksum_sha256 TEXT NOT NULL,
  total_items_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.cloud_backups ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'cloud_backups' AND policyname = 'Users can manage own backups') THEN
    CREATE POLICY "Users can manage own backups"
      ON public.cloud_backups FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- ==============================================================================
-- 8. DISTRIBUSI UPDATE & STORAGE BUCKETS
-- ==============================================================================

-- 8.1 App Versions
CREATE TABLE IF NOT EXISTS public.app_versions (
  id BIGSERIAL PRIMARY KEY,
  latest_version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  download_url TEXT NOT NULL,
  changelog JSONB DEFAULT '[]'::jsonb,
  is_force_update BOOLEAN DEFAULT false,
  release_date TEXT DEFAULT to_char(now(), 'YYYY-MM-DD'),
  file_size_bytes BIGINT DEFAULT 0,
  variants JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'app_versions' AND policyname = 'Public read app_versions') THEN
    CREATE POLICY "Public read app_versions" ON public.app_versions FOR SELECT USING (true);
  END IF;
END $$;

-- 8.2 Storage Buckets Setup
INSERT INTO storage.buckets (id, name, public) VALUES ('cardly_documents', 'cardly_documents', false)
ON CONFLICT (id) DO UPDATE SET public = false;

INSERT INTO storage.buckets (id, name, public) VALUES ('cardly_backups', 'cardly_backups', false)
ON CONFLICT (id) DO UPDATE SET public = false;

INSERT INTO storage.buckets (id, name, public) VALUES ('cardly_avatars', 'cardly_avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Storage Policies
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage own documents') THEN
    CREATE POLICY "Users can manage own documents" ON storage.objects FOR ALL
      TO authenticated
      USING (bucket_id = 'cardly_documents' AND (storage.foldername(name))[1] = auth.uid()::text)
      WITH CHECK (bucket_id = 'cardly_documents' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage own backups') THEN
    CREATE POLICY "Users can manage own backups" ON storage.objects FOR ALL
      TO authenticated
      USING (bucket_id = 'cardly_backups' AND (storage.foldername(name))[1] = auth.uid()::text)
      WITH CHECK (bucket_id = 'cardly_backups' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public read avatars') THEN
    CREATE POLICY "Public read avatars" ON storage.objects FOR SELECT
      USING (bucket_id = 'cardly_avatars');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage own avatar') THEN
    CREATE POLICY "Users can manage own avatar" ON storage.objects FOR ALL
      TO authenticated
      USING (bucket_id = 'cardly_avatars' AND (storage.foldername(name))[1] = auth.uid()::text)
      WITH CHECK (bucket_id = 'cardly_avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;
END $$;

-- ==============================================================================
-- 9. TRIGGER: OTOMASI REGISTRASI USER BARU
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public, extensions
LANGUAGE plpgsql
AS $$
BEGIN
  -- 1. Buat Profile Pengguna
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, profiles.full_name);

  -- 2. Buat Pengaturan Pengguna (User Settings)
  INSERT INTO public.user_settings (user_id)
  VALUES (new.id)
  ON CONFLICT (user_id) DO NOTHING;

  -- 3. Inisialisasi Vault Salt (menggunakan fungsi bawaan PostgreSQL yang aman)
  INSERT INTO public.vault_metadata (user_id, kdf_salt)
  VALUES (new.id, md5(random()::text || clock_timestamp()::text))
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
EXCEPTION
  WHEN OTHERS THEN
    -- Safety Shield: Pastikan proses registrasi user TIDAK pernah gagal
    RAISE WARNING 'handle_new_user error: %', SQLERRM;
    RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
