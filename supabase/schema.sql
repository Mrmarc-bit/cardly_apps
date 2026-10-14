-- ==============================================================================
-- CARDLY SUPABASE CLOUD DATABASE SCHEMA
-- Skema PostgreSQL resmi untuk Sinkronisasi Cloud Cardly
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABEL PROFILES (Tautkan dengan Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can view and edit own profile'
  ) THEN
    CREATE POLICY "Users can view and edit own profile"
      ON public.profiles FOR ALL
      USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- 3. TABEL CARDS (Katalog Kartu Pengguna)
-- Mengikuti aturan zero-leakage AGENTS.md: Hanya menampung last_four_digits VARCHAR(4)
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
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_cards_user_fav ON public.cards(user_id, is_favorite);
CREATE INDEX IF NOT EXISTS idx_cards_user_archived ON public.cards(user_id, is_archived);

ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'cards' AND policyname = 'Users can manage their own cards'
  ) THEN
    CREATE POLICY "Users can manage their own cards"
      ON public.cards FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 4. TABEL DOCUMENTS (Katalog Berkas Dokumen & Identitas)
CREATE TABLE IF NOT EXISTS public.documents (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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
  PRIMARY KEY (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_docs_user_private ON public.documents(user_id, is_private);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can manage their own documents'
  ) THEN
    CREATE POLICY "Users can manage their own documents"
      ON public.documents FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 5. TABEL REMINDERS (Pengingat Masa Berlaku Dokumen/Kartu)
CREATE TABLE IF NOT EXISTS public.reminders (
  id TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_id TEXT,
  title TEXT NOT NULL,
  reminder_date TIMESTAMPTZ NOT NULL,
  reminder_time TEXT NOT NULL,
  repetition TEXT NOT NULL,
  notes TEXT,
  device_notification_active BOOLEAN NOT NULL DEFAULT true,
  hide_title_on_lock_screen BOOLEAN NOT NULL DEFAULT false,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_reminders_user_date ON public.reminders(user_id, reminder_date);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'reminders' AND policyname = 'Users can manage their own reminders'
  ) THEN
    CREATE POLICY "Users can manage their own reminders"
      ON public.reminders FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- 6. STORAGE BUCKET: cardly_documents
-- Menyiapkan bucket penyimpanan berkas dokumen terenkripsi jika belum ada
INSERT INTO storage.buckets (id, name, public)
VALUES ('cardly_documents', 'cardly_documents', false)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Setiap pengguna hanya dapat melihat dan mengunggah berkas di foldernya sendiri (auth.uid()/*)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Users can manage their own document files'
  ) THEN
    CREATE POLICY "Users can manage their own document files"
      ON storage.objects FOR ALL
      TO authenticated
      USING (bucket_id = 'cardly_documents' AND (storage.foldername(name))[1] = auth.uid()::text)
      WITH CHECK (bucket_id = 'cardly_documents' AND (storage.foldername(name))[1] = auth.uid()::text);
  END IF;
END $$;

-- 7. TRIGGER: Auto-create Profile saat User Baru Mendaftar di Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', 'Pengguna Cardly')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- APP VERSIONS (Untuk In-App Update Distribution Tanpa Google Play Store)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  latest_version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  download_url TEXT NOT NULL,
  changelog JSONB DEFAULT '[]'::jsonb,
  is_force_update BOOLEAN DEFAULT false,
  release_date TEXT DEFAULT to_char(now(), 'YYYY-MM-DD'),
  file_size_bytes BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS: Publik diperbolehkan membaca versi terbaru aplikasi
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read app_versions" ON public.app_versions
  FOR SELECT USING (true);

