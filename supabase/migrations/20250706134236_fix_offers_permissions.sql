-- This policy allows merchants to update the status of offers on their own shipments.

CREATE POLICY "Merchants can update offers on their shipments."
ON public.offers FOR UPDATE
USING (auth.uid() = (SELECT merchant_id FROM public.shipments WHERE id = shipment_id));