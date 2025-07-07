-- This script RESETS all critical RLS policies to fix recursion and visibility issues.

-- Step 1: Drop ALL old policies from the problematic tables to ensure a clean slate.
DROP POLICY IF EXISTS "Merchants can create their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can view their own shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can update their own open shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view all open shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can see their in-progress shipments." ON public.shipments;
DROP POLICY IF EXISTS "Drivers can view shipments they have an accepted offer on." ON public.shipments;
DROP POLICY IF EXISTS "Users can view shipments they are part of." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can insert shipments." ON public.shipments;
DROP POLICY IF EXISTS "Merchants can update their open shipments." ON public.shipments;

DROP POLICY IF EXISTS "Users can view conversations they are part of." ON public.conversations;
DROP POLICY IF EXISTS "Users can access conversations they are a part of." ON public.conversations;

-- ***** هذا هو السطر الجديد الذي يحل المشكلة *****
-- حذف القواعد القديمة من جدول العروض لتجنب التعارض
DROP POLICY IF EXISTS "Users can see offers related to them." ON public.offers;
DROP POLICY IF EXISTS "Drivers can create offers." ON public.offers;
DROP POLICY IF EXISTS "Merchants can update offers on their shipments." ON public.offers;


-- Step 2: Create new, simple, and correct policies.

-- Policy for PROFILES: Allow any logged-in user to see other profiles.
DROP POLICY IF EXISTS "Authenticated users can view all profiles." ON public.profiles;
CREATE POLICY "Authenticated users can view all profiles."
ON public.profiles FOR SELECT
USING ( auth.role() = 'authenticated' );


-- Policies for SHIPMENTS
CREATE POLICY "Merchants can manage their own shipments."
ON public.shipments FOR ALL
USING (auth.uid() = merchant_id)
WITH CHECK (auth.uid() = merchant_id);

CREATE POLICY "Drivers can view relevant shipments."
ON public.shipments FOR SELECT
USING (
    (public.get_my_user_type() = 'driver' AND status = 'open') OR
    (public.get_my_user_type() = 'driver' AND id IN (
        SELECT shipment_id FROM public.offers WHERE driver_id = auth.uid() AND status = 'accepted'
    ))
);


-- Policies for OFFERS
CREATE POLICY "Users can see offers related to them."
ON public.offers FOR SELECT
USING (
    (auth.uid() = driver_id) OR
    (auth.uid() = (SELECT merchant_id FROM public.shipments WHERE id = offers.shipment_id))
);

-- Policies for CONVERSATIONS
CREATE POLICY "Users can access their own conversations."
ON public.conversations FOR SELECT
USING (auth.uid() = merchant_id OR auth.uid() = driver_id);