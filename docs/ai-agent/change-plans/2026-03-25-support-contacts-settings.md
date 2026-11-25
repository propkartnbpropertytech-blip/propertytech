# Change Plan — Dynamic Support Contacts

## Objective
Admin can edit WhatsApp / phone / email shown on Support page from Settings → Support Contacts. Values persist per organization in `public.settings`.

## Scope
- Backend: `/config/support-contacts` GET/PUT + migration `124_support_contacts_settings.sql`
- Flutter: `SupportContactsManager`, Settings section, Support page wiring
- Forbidden: unrelated pages, platform Super Admin marketing hotlines table

## Verification
- Analyzer on changed Flutter files
- Restart backend so additive migration + routes load
