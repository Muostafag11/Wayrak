CREATE OR REPLACE FUNCTION get_shipment_history_with_user(
    other_user_id UUID
)
RETURNS TABLE (
    id UUID,
    created_at TIMESTAMPTZ,
    title TEXT,
    status TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    current_user_id UUID := auth.uid();
BEGIN
    RETURN QUERY
    SELECT
        s.id,
        s.created_at,
        s.title,
        s.status
    FROM
        public.shipments s
    WHERE
        -- Find shipments where the two users are the merchant and the accepted driver
        s.id IN (
            SELECT o.shipment_id
            FROM public.offers o
            WHERE o.status = 'accepted'
              AND (
                    (s.merchant_id = current_user_id AND o.driver_id = other_user_id) OR
                    (s.merchant_id = other_user_id AND o.driver_id = current_user_id)
                  )
        );
END;
$$;