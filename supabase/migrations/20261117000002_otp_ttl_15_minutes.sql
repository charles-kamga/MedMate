-- ==============================================================================
-- Afya-Health - Passage du délai d'expiration OTP à 15 minutes (alignement sécurité)
-- Idempotent : sûr même si 20261022000001 / 20261110000001 ont déjà tourné en base.
-- ==============================================================================

ALTER TABLE public.reservations
  ALTER COLUMN expires_at
  SET DEFAULT (timezone('utc'::text, now()) + interval '15 minutes');

ALTER TABLE public.flash_orders
  ALTER COLUMN expires_at
  SET DEFAULT (timezone('utc'::text, now()) + interval '15 minutes');
