CREATE TABLE public.offers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    shipment_id UUID REFERENCES public.shipments(id) ON DELETE CASCADE NOT NULL,
    driver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    price NUMERIC NOT NULL,
    notes TEXT,
    status TEXT DEFAULT 'pending' NOT NULL -- pending, accepted, rejected
);

ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;

-- Drivers can create offers.
CREATE POLICY "Drivers can create offers."
ON public.offers FOR INSERT
WITH CHECK (public.get_my_user_type() = 'driver');

-- Users can see offers related to them (their shipments or their offers).
CREATE POLICY "Users can see offers related to them."
ON public.offers FOR SELECT
USING (
    auth.uid() = driver_id OR
    auth.uid() = (SELECT merchant_id FROM public.shipments WHERE id = shipment_id)
);