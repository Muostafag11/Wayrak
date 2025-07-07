-- This script provides the simplest possible RLS rules to avoid all recursion.

-- Drop all potentially conflicting policies
DROP POLICY IF EXISTS "Merchants can manage their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view relevant shipments." ON public.shipments;
DROP POLICY IF EXISTS "Users can view shipments they are part of." ON public.shipments;

-- NEW, ULTRA-SIMPLE POLICIES FOR SHIPMENTS
-- Anyone logged in can see any shipment. We will filter in the app.
CREATE POLICY "Authenticated users can view shipments." ON public.shipments
FOR SELECT USING (auth.role() = 'authenticated');

-- Only merchants can insert.
CREATE POLICY "Merchants can insert shipments." ON public.shipments
FOR INSERT WITH CHECK (auth.uid() = merchant_id);

-- Only merchants can update their own shipments.
CREATE POLICY "Merchants can update their own shipments." ON public.shipments
FOR UPDATE USING (auth.uid() = merchant_id);