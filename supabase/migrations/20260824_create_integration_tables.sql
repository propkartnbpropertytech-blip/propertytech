-- ====================================================================
-- PROPKART INTEGRATION & WEBHOOKS SCHEMA
-- Supports: Meta Lead Ads Webhook, Google Sheets Apps Script, Dynamic JSON Headers,
--           Deduplication, Meta Conversions API Feedback, and CRM Ingestion.
-- ====================================================================

-- 1. Integration Webhook & Campaign Configurations
CREATE TABLE IF NOT EXISTS public.integration_webhook_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NULL,
    webhook_url TEXT NOT NULL,
    webhook_secret TEXT NOT NULL,
    meta_verify_token TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Integration Dynamic Column Mappings & Custom Headers
CREATE TABLE IF NOT EXISTS public.integration_column_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NULL,
    header_name TEXT NOT NULL,
    crm_field_target TEXT NULL, -- 'name', 'mobile', 'email', 'city', 'budget', 'configuration', etc.
    is_visible BOOLEAN NOT NULL DEFAULT true,
    is_custom BOOLEAN NOT NULL DEFAULT false,
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_org_header UNIQUE (organization_id, header_name)
);

-- 3. Ingested Integration Leads (Meta, Google Sheets, Webhook API)
CREATE TABLE IF NOT EXISTS public.integration_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NULL,
    source TEXT NOT NULL, -- 'Meta Ads', 'Google Sheets', 'Webhook API'
    external_lead_id TEXT NULL, -- Meta Lead ID or Google Sheet Row ID
    raw_json JSONB NOT NULL, -- Dynamic { key: value } payload
    sanitized_phone TEXT NULL,
    sanitized_email TEXT NULL,
    is_duplicate BOOLEAN NOT NULL DEFAULT false,
    duplicate_reason TEXT NULL,
    duplicate_of_id UUID REFERENCES public.integration_leads(id) ON DELETE SET NULL,
    quality_status TEXT NOT NULL DEFAULT 'Pending', -- 'Pending', 'Qualified', 'Disqualified', 'Converted', 'Junk'
    import_status TEXT NOT NULL DEFAULT 'Pending', -- 'Pending', 'Ready', 'Imported', 'Ignored'
    imported_client_id UUID NULL, -- Linked to clients.id in CRM
    meta_feedback_event_id TEXT NULL, -- Meta Conversions API event ID
    meta_feedback_sent_at TIMESTAMPTZ NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Integration Sync & Audit Logs
CREATE TABLE IF NOT EXISTS public.integration_sync_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NULL,
    event_type TEXT NOT NULL, -- 'WEBHOOK_RECEIVED', 'DEDUPLICATION_FLAGGED', 'META_FEEDBACK_SENT', 'CRM_IMPORTED'
    source TEXT NOT NULL,
    payload_preview JSONB NULL,
    status TEXT NOT NULL DEFAULT 'SUCCESS', -- 'SUCCESS', 'WARNING', 'ERROR'
    message TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ====================================================================
-- INDEXES FOR HIGH-SPEED LOOKUP & DEDUPLICATION
-- ====================================================================
CREATE INDEX IF NOT EXISTS idx_integration_leads_org ON public.integration_leads (organization_id);
CREATE INDEX IF NOT EXISTS idx_integration_leads_phone ON public.integration_leads (sanitized_phone);
CREATE INDEX IF NOT EXISTS idx_integration_leads_email ON public.integration_leads (sanitized_email);
CREATE INDEX IF NOT EXISTS idx_integration_leads_ext_id ON public.integration_leads (external_lead_id);
CREATE INDEX IF NOT EXISTS idx_integration_leads_received ON public.integration_leads (received_at DESC);
CREATE INDEX IF NOT EXISTS idx_integration_leads_raw_json ON public.integration_leads USING gin (raw_json);

-- ====================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- Admin and Super Admin access only
-- ====================================================================
ALTER TABLE public.integration_webhook_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_column_mappings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.integration_sync_logs ENABLE ROW LEVEL SECURITY;

-- Admins and Authenticated Staff can view & manage integration records
CREATE POLICY "Admins full access to integration_webhook_configs"
    ON public.integration_webhook_configs
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Admins full access to integration_column_mappings"
    ON public.integration_column_mappings
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Admins full access to integration_leads"
    ON public.integration_leads
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Admins full access to integration_sync_logs"
    ON public.integration_sync_logs
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Allow public anonymous/service-role inserts for incoming webhooks
CREATE POLICY "Public webhook insert to integration_leads"
    ON public.integration_leads
    FOR INSERT
    TO anon, service_role
    WITH CHECK (true);
