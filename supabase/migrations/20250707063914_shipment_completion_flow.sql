-- This script creates a shipment status type and functions to manage the shipment lifecycle.

-- 1. Create a new ENUM type for shipment statuses for better data integrity.
CREATE TYPE public.shipment_status AS ENUM ('open', 'in_progress', 'pending_completion', 'completed', 'cancelled');

-- 2. Drop the old RLS policies that use the old text-based status.
DROP POLICY IF EXISTS "Merchants can update their open shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view relevant shipments." ON public.shipments;

-- 3. Alter the shipments table to use the new ENUM type.
-- This requires dropping the default and then setting the new type and default.
ALTER TABLE public.shipments ALTER COLUMN status DROP DEFAULT;
ALTER TABLE public.shipments ALTER COLUMN status TYPE public.shipment_status USING status::public.shipment_status;
ALTER TABLE public.shipments ALTER COLUMN status SET DEFAULT 'open';

-- 4. Re-create the policies using the new ENUM type.
CREATE POLICY "Merchants can update their open shipments."
ON public.shipments FOR UPDATE
USING (auth.uid() = merchant_id AND status = 'open');

CREATE POLICY "Drivers can view relevant shipments."
ON public.shipments FOR SELECT
USING (
  (public.get_my_user_type() = 'driver' AND status = 'open') OR
  (public.get_my_user_type() = 'driver' AND id IN (
    SELECT shipment_id FROM public.offers WHERE driver_id = auth.uid() AND status = 'accepted'
  ))
);

-- 5. Create a function for the driver to mark a shipment as delivered.
CREATE OR REPLACE FUNCTION public.mark_shipment_delivered(p_shipment_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER AS $$
BEGIN
  UPDATE public.shipments
  SET status = 'pending_completion'
  WHERE id = p_shipment_id
  AND status = 'in_progress'
  AND id IN (
    SELECT shipment_id FROM public.offers WHERE driver_id = auth.uid() AND status = 'accepted'
  );
END;
$$;

-- 6. Create a function for the merchant to confirm receipt.
CREATE OR REPLACE FUNCTION public.confirm_shipment_receipt(p_shipment_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER AS $$
BEGIN
  UPDATE public.shipments
  SET status = 'completed'
  WHERE id = p_shipment_id
  AND status = 'pending_completion'
  AND merchant_id = auth.uid();
END;
$$;