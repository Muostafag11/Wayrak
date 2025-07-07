-- This script simplifies all major RLS policies to fix recursion and visibility issues.

-- Drop all old policies for shipments to start clean
DROP POLICY IF EXISTS "Merchants can create their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can view their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can update their own open shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view all open shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can see their in-progress shipments." ON public.shipments;

-- Drop all old policies for conversations
DROP POLICY IF EXISTS "Users can view conversations they are part of." ON public.conversations;


-- Create NEW, SIMPLER policies for shipments
CREATE POLICY "Users can view shipments they are part of."
ON public.shipments FOR SELECT
USING (
    -- Merchants can see their own shipments
    (auth.uid() = merchant_id) OR
    -- Drivers can see open shipments
    (public.get_my_user_type() = 'driver' AND status = 'open') OR
    -- Drivers can see shipments they have an accepted offer on
    (id IN (SELECT shipment_id FROM public.offers WHERE driver_id = auth.uid() AND status = 'accepted'))
);

CREATE POLICY "Merchants can insert shipments."
ON public.shipments FOR INSERT
WITH CHECK (auth.uid() = merchant_id);

CREATE POLICY "Merchants can update their open shipments."
ON public.shipments FOR UPDATE
USING (auth.uid() = merchant_id AND status = 'open');


-- Create NEW, SIMPLER policy for conversations
CREATE POLICY "Users can access conversations they are a part of."
ON public.conversations FOR SELECT
USING (auth.uid() = merchant_id OR auth.uid() = driver_id);