-- This script safely replaces the accept_offer function with a new version.

-- 1. Drop the old function first to allow changing the return type.
DROP FUNCTION IF EXISTS public.accept_offer(UUID, UUID);

-- 2. Create the new version of the function.
-- It now creates a conversation if one doesn't exist and returns the necessary IDs.
CREATE OR REPLACE FUNCTION public.accept_offer(
  offer_id_to_accept UUID,
  shipment_id_to_update UUID
)
RETURNS TABLE (
  conversation_id UUID,
  merchant_id UUID,
  driver_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  merchant_user_id UUID;
  driver_user_id UUID;
  new_conversation_id UUID;
BEGIN
  -- Get merchant and driver IDs
  SELECT s.merchant_id, o.driver_id INTO merchant_user_id, driver_user_id
  FROM public.shipments s
  JOIN public.offers o ON s.id = o.shipment_id
  WHERE o.id = offer_id_to_accept AND s.id = shipment_id_to_update;

  -- Check authorization
  IF auth.uid() != merchant_user_id THEN
    RAISE EXCEPTION 'User is not authorized to accept offers for this shipment';
  END IF;

  -- Update offer and shipment statuses
  UPDATE public.offers SET status = 'accepted' WHERE id = offer_id_to_accept;
  UPDATE public.shipments SET status = 'in_progress' WHERE id = shipment_id_to_update;
  UPDATE public.offers SET status = 'rejected' WHERE shipment_id = shipment_id_to_update AND id != offer_id_to_accept AND status = 'pending';

  -- Create a conversation if it doesn't exist, and get its ID
  INSERT INTO public.conversations (shipment_id, merchant_id, driver_id)
  VALUES (shipment_id_to_update, merchant_user_id, driver_user_id)
  ON CONFLICT (shipment_id) DO NOTHING;
  
  SELECT id INTO new_conversation_id FROM public.conversations WHERE shipment_id = shipment_id_to_update;

  -- Return the necessary IDs to the app
  RETURN QUERY SELECT new_conversation_id, merchant_user_id, driver_user_id;

END;
$$;