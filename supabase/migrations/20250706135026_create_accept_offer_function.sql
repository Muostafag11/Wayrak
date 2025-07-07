-- This function accepts an offer and updates the shipment status in a single transaction.
CREATE OR REPLACE FUNCTION public.accept_offer(
  offer_id_to_accept UUID,
  shipment_id_to_update UUID
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  merchant_user_id UUID;
BEGIN
  -- 1. Get the merchant_id from the shipment
  SELECT merchant_id INTO merchant_user_id
  FROM public.shipments
  WHERE id = shipment_id_to_update;

  -- 2. Check if the current user is the owner of the shipment
  IF auth.uid() != merchant_user_id THEN
    RAISE EXCEPTION 'User is not authorized to accept offers for this shipment';
  END IF;

  -- 3. Update the offer status to 'accepted'
  UPDATE public.offers
  SET status = 'accepted'
  WHERE id = offer_id_to_accept;

  -- 4. Update the shipment status to 'in_progress'
  UPDATE public.shipments
  SET status = 'in_progress'
  WHERE id = shipment_id_to_update;

  -- 5. (Optional but good practice) Reject all other pending offers for this shipment
  UPDATE public.offers
  SET status = 'rejected'
  WHERE shipment_id = shipment_id_to_update AND id != offer_id_to_accept AND status = 'pending';

END;
$$;