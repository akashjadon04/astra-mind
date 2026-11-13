-- ==============================================================================
-- Astra Mind: Supabase Telemetry & Research Persistence Schema
-- ==============================================================================

-- 1. Research Briefings & Logs Table
CREATE TABLE IF NOT EXISTS public.research_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    research_topic TEXT NOT NULL,
    research_content TEXT DEFAULT 'N/A',
    additional_datasets TEXT DEFAULT 'N/A',
    user_id TEXT,
    telegram_chat_id BIGINT,
    search_queries JSONB DEFAULT '[]'::jsonb,
    structured_sources JSONB DEFAULT '[]'::jsonb,
    execution_status TEXT DEFAULT 'in_progress' CHECK (execution_status IN ('in_progress', 'completed', 'failed')),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 2. Structured Datasets & Extracted Quantitative Entities
CREATE TABLE IF NOT EXISTS public.research_datasets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    research_log_id UUID REFERENCES public.research_logs(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    dataset_name TEXT NOT NULL,
    dataset_url TEXT,
    provider TEXT,
    format TEXT,
    description TEXT,
    schema_definition JSONB DEFAULT '{}'::jsonb
);

-- 3. High-Performance Indexes
CREATE INDEX IF NOT EXISTS idx_research_logs_topic ON public.research_logs USING gin (to_tsvector('english', research_topic));
CREATE INDEX IF NOT EXISTS idx_research_logs_created ON public.research_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_research_datasets_log ON public.research_datasets (research_log_id);

-- 4. Automatic Timestamp Update Trigger
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_research_logs_timestamp ON public.research_logs;
CREATE TRIGGER set_research_logs_timestamp
    BEFORE UPDATE ON public.research_logs
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 5. Row Level Security (RLS) Configuration
ALTER TABLE public.research_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.research_datasets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow authenticated read and write access"
    ON public.research_logs
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Allow service_role full access"
    ON public.research_logs
    FOR ALL
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');
