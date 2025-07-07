-- Drop all existing policies on the shipments table to ensure a clean slate
DROP POLICY IF EXISTS "Merchants can manage their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view relevant shipments." ON public.shipments;
DROP POLICY IF EXISTS "Users can view shipments they are part of." ON public.shipments;
DROP POLICY IF EXISTS "Authenticated users can view shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can insert shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can update their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can update their open shipments." ON public.shipments;

-- Create one simple policy for viewing shipments
CREATE POLICY "Authenticated users can view all shipments."
ON public.shipments FOR SELECT
USING ( auth.role() = 'authenticated' );

-- Re-create the necessary insert/update policies
CREATE POLICY "Merchants can insert new shipments."
ON public.shipments FOR INSERT
WITH CHECK ( auth.uid() = merchant_id );

CREATE POLICY "Merchants can update their shipments."
ON public.shipments FOR UPDATE
USING ( auth.uid() = merchant_id );