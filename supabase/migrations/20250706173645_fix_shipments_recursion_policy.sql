-- This script fixes the infinite recursion error by simplifying the driver's select policy on shipments.

-- 1. Drop the problematic policy first
DROP POLICY IF EXISTS "Drivers can view shipments they have an accepted offer on." ON public.shipments;

-- 2. Re-create the policies for drivers to view shipments without recursion
-- This policy allows drivers to see OPEN shipments (which is the main Browse view)
DROP POLICY IF EXISTS "Drivers can view all open shipments." ON public.shipments;
CREATE POLICY "Drivers can view all open shipments."
ON public.shipments FOR SELECT
USING (public.get_my_user_type() = 'driver' AND status = 'open');

-- This policy allows drivers to see shipments that are IN PROGRESS if they are the accepted driver
CREATE POLICY "Drivers can see their in-progress shipments."
ON public.shipments FOR SELECT
USING (
  public.get_my_user_type() = 'driver'
  AND status = 'in_progress'
  AND id IN (
    SELECT shipment_id FROM public.offers WHERE driver_id = auth.uid() AND status = 'accepted'
  )
);