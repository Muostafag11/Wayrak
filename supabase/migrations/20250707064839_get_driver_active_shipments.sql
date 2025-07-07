CREATE OR REPLACE FUNCTION public.get_my_active_shipments_as_driver()
RETURNS SETOF public.shipments
LANGUAGE sql
STABLE
AS $$
  SELECT *
  FROM public.shipments
  WHERE
    status IN ('in_progress', 'pending_completion') AND
    id IN (
      SELECT shipment_id FROM public.offers
      WHERE driver_id = auth.uid() AND status = 'accepted'
    );
$$;