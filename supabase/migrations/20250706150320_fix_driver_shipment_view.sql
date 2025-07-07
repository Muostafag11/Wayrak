-- This policy allows a driver to see shipments for which they have an accepted offer.
CREATE POLICY "Drivers can view shipments they have an accepted offer on."
ON public.shipments FOR SELECT
USING (
  id IN (
    SELECT shipment_id FROM public.offers
    WHERE driver_id = auth.uid() AND status = 'accepted'
  )
);