-- ═══════════════════════════════════════════════════════════════════════════
-- Supabase Database Schema for Noor Islamic App
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ═══════════════════════════════════════════════════════════════════════════
-- QURAN TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Surahs
CREATE TABLE surahs (
    number INTEGER PRIMARY KEY,
    name_arabic VARCHAR(100) NOT NULL,
    name_english VARCHAR(100) NOT NULL,
    name_transliteration VARCHAR(100) NOT NULL,
    verses_count INTEGER NOT NULL,
    revelation_type VARCHAR(10) NOT NULL CHECK (revelation_type IN ('makki', 'madani')),
    page INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Verses
CREATE TABLE verses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    surah_number INTEGER REFERENCES surahs(number),
    verse_number INTEGER NOT NULL,
    text_uthmani TEXT NOT NULL,
    text_simple TEXT,
    page INTEGER NOT NULL,
    juz INTEGER NOT NULL,
    hizb INTEGER NOT NULL,
    quarter INTEGER NOT NULL,
    sajdah BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(surah_number, verse_number)
);

-- Tafsir
CREATE TABLE tafsir (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    surah_number INTEGER REFERENCES surahs(number),
    verse_number INTEGER NOT NULL,
    brief_text TEXT NOT NULL,
    detailed_text TEXT,
    source VARCHAR(100) NOT NULL,
    author VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Revelation Causes
CREATE TABLE revelation_causes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    surah_number INTEGER REFERENCES surahs(number),
    verse_number INTEGER NOT NULL,
    brief_summary TEXT NOT NULL,
    full_story TEXT,
    cause_type VARCHAR(50) NOT NULL CHECK (cause_type IN ('event', 'question', 'personal_incident', 'legislation')),
    source VARCHAR(200) NOT NULL,
    historical_context TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- HADITH TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Hadiths
CREATE TABLE hadiths (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_arabic TEXT NOT NULL,
    text_english TEXT,
    narrator VARCHAR(200) NOT NULL,
    source VARCHAR(100) NOT NULL,
    book_name VARCHAR(100) NOT NULL,
    hadith_number INTEGER,
    grade VARCHAR(50) NOT NULL CHECK (grade IN ('sahih', 'hasan', 'daif', 'mawdu', 'sahih_li_ghairihi', 'hasan_li_ghairihi')),
    grading_reason TEXT,
    explanation TEXT,
    topics TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hadith Categories
CREATE TABLE hadith_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name_arabic VARCHAR(100) NOT NULL,
    name_english VARCHAR(100) NOT NULL,
    hadith_count INTEGER DEFAULT 0,
    icon_name VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ADHKAR TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Adhkar
CREATE TABLE adhkar (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    text_arabic TEXT NOT NULL,
    text_english TEXT,
    transliteration TEXT,
    target_count INTEGER NOT NULL DEFAULT 1,
    reward TEXT,
    source VARCHAR(200),
    category VARCHAR(50) NOT NULL CHECK (category IN ('morning', 'evening', 'after_prayer', 'sleep', 'wake_up', 'general', 'mood_based')),
    mood_type VARCHAR(50) CHECK (mood_type IN ('anxiety', 'sadness', 'joy', 'fear', 'anger', 'gratitude')),
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- USER DATA TABLES
-- ═══════════════════════════════════════════════════════════════════════════

-- Reading Progress
CREATE TABLE reading_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    surah_number INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    page INTEGER NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Bookmarks
CREATE TABLE bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL CHECK (type IN ('verse', 'hadith', 'dhikr')),
    item_id VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, type, item_id)
);

-- Tadabbur (Personal Reflections) - Note: Encrypted content
CREATE TABLE tadabbur (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    surah_number INTEGER NOT NULL,
    verse_number INTEGER NOT NULL,
    encrypted_note TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Qada Records
CREATE TABLE qada_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('prayer', 'fasting')),
    total_count INTEGER NOT NULL,
    completed_count INTEGER DEFAULT 0,
    start_date DATE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════

-- Enable RLS
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE tadabbur ENABLE ROW LEVEL SECURITY;
ALTER TABLE qada_records ENABLE ROW LEVEL SECURITY;

-- Policies for user data
CREATE POLICY "Users can only access their own reading progress" ON reading_progress
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own bookmarks" ON bookmarks
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own tadabbur" ON tadabbur
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can only access their own qada records" ON qada_records
    FOR ALL USING (auth.uid() = user_id);

-- Public read access for content tables
CREATE POLICY "Public read access for surahs" ON surahs FOR SELECT USING (true);
CREATE POLICY "Public read access for verses" ON verses FOR SELECT USING (true);
CREATE POLICY "Public read access for tafsir" ON tafsir FOR SELECT USING (true);
CREATE POLICY "Public read access for revelation_causes" ON revelation_causes FOR SELECT USING (true);
CREATE POLICY "Public read access for hadiths" ON hadiths FOR SELECT USING (true);
CREATE POLICY "Public read access for hadith_categories" ON hadith_categories FOR SELECT USING (true);
CREATE POLICY "Public read access for adhkar" ON adhkar FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════════════════════
-- INDEXES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE INDEX idx_verses_surah ON verses(surah_number);
CREATE INDEX idx_verses_page ON verses(page);
CREATE INDEX idx_verses_juz ON verses(juz);
CREATE INDEX idx_tafsir_verse ON tafsir(surah_number, verse_number);
CREATE INDEX idx_revelation_causes_verse ON revelation_causes(surah_number, verse_number);
CREATE INDEX idx_hadiths_grade ON hadiths(grade);
CREATE INDEX idx_hadiths_topics ON hadiths USING GIN(topics);
CREATE INDEX idx_adhkar_category ON adhkar(category);
