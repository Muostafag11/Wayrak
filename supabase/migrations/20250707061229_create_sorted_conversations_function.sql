CREATE OR REPLACE FUNCTION get_sorted_conversations()
RETURNS TABLE (
    id uuid,
    created_at timestamptz,
    shipment_id uuid,
    merchant_id uuid,
    driver_id uuid,
    last_message_time timestamptz,
    shipment json,
    merchant json,
    driver json
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.created_at,
        c.shipment_id,
        c.merchant_id,
        c.driver_id,
        (SELECT MAX(m.created_at) FROM public.messages m WHERE m.conversation_id = c.id) as last_message_time,
        json_build_object('title', s.title) as shipment,
        json_build_object('id', m_profile.id, 'full_name', m_profile.full_name) as merchant,
        json_build_object('id', d_profile.id, 'full_name', d_profile.full_name) as driver
    FROM
        public.conversations c
    LEFT JOIN public.shipments s ON c.shipment_id = s.id
    LEFT JOIN public.profiles m_profile ON c.merchant_id = m_profile.id
    LEFT JOIN public.profiles d_profile ON c.driver_id = d_profile.id
    WHERE
        c.merchant_id = auth.uid() OR c.driver_id = auth.uid()
    ORDER BY
        last_message_time DESC NULLS LAST;
END;
$$;