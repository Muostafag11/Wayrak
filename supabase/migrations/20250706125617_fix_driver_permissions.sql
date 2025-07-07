-- This script fixes the row level security policy for drivers.

-- 1. Create a helper function to get the user_type from the profiles table.
CREATE OR REPLACE FUNCTION public.get_my_user_type()
RETURNS TEXT
LANGUAGE sql STABLE
AS $$
  SELECT user_type FROM public.profiles WHERE id = auth.uid();
$$;

-- 2. Drop the old, non-working policy.
DROP POLICY IF EXISTS "Drivers can view all open shipments." ON public.shipments;

-- 3. Create the new, correct policy using the helper function.
CREATE POLICY "Drivers can view all open shipments."
ON public.shipments FOR SELECT
USING (public.get_my_user_type() = 'driver' AND status = 'open');