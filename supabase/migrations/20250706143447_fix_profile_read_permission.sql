-- This policy allows any authenticated user to view all public profiles.
-- This is necessary so merchants can see driver names, and vice-versa.

CREATE POLICY "Authenticated users can view all profiles."
ON public.profiles FOR SELECT
USING ( auth.role() = 'authenticated' );