CREATE TABLE public.vouchers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE,
  discount_percent smallint NOT NULL DEFAULT 5 CHECK (discount_percent = 5),
  used_order_id text,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT vouchers_use_pair CHECK ((used_at IS NULL) = (used_order_id IS NULL))
);
GRANT SELECT ON public.vouchers TO authenticated;
GRANT ALL ON public.vouchers TO service_role;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "read own voucher" ON public.vouchers FOR SELECT TO authenticated USING (user_id = auth.uid());

ALTER TABLE public.orders
  ADD COLUMN subtotal numeric,
  ADD COLUMN discount_amount numeric,
  ADD COLUMN voucher_code text;

CREATE OR REPLACE FUNCTION public.issue_signup_voucher() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.vouchers(user_id, code)
  VALUES (NEW.id, 'CQ5-' || upper(replace(gen_random_uuid()::text, '-', '')))
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE TRIGGER issue_voucher_after_profile_insert
AFTER INSERT ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.issue_signup_voucher();

INSERT INTO public.vouchers(user_id, code)
SELECT p.id, 'CQ5-' || upper(replace(gen_random_uuid()::text, '-', ''))
FROM public.profiles AS p
ON CONFLICT (user_id) DO NOTHING;

CREATE OR REPLACE FUNCTION public.apply_account_voucher_to_order() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_id uuid;
  v_code text;
  v_discount_percent smallint;
BEGIN
  NEW.subtotal := NEW.total;
  NEW.discount_amount := 0;
  NEW.voucher_code := NULL;

  IF NEW.total > 0 THEN
    SELECT v.id, v.code, v.discount_percent
    INTO v_id, v_code, v_discount_percent
    FROM public.vouchers AS v
    WHERE v.user_id = NEW.user_id AND v.used_at IS NULL
    FOR UPDATE;

    IF FOUND THEN
      NEW.discount_amount := round(NEW.subtotal * v_discount_percent / 100.0);
      NEW.total := NEW.subtotal - NEW.discount_amount;
      NEW.voucher_code := v_code;
      UPDATE public.vouchers
      SET used_at = clock_timestamp(), used_order_id = NEW.id
      WHERE id = v_id AND used_at IS NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;
CREATE TRIGGER apply_account_voucher_before_order_insert
BEFORE INSERT ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.apply_account_voucher_to_order();