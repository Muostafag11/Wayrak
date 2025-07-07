-- This policy allows drivers to create new offers.

CREATE POLICY "Drivers can create offers."
ON public.offers FOR INSERT
WITH CHECK (public.get_my_user_type() = 'driver');