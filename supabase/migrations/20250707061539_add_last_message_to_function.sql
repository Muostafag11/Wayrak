-- This script safely replaces the get_sorted_conversations function
-- with a new version that includes the last message content.

-- Step 1: Drop the old version of the function to avoid conflicts.
DROP FUNCTION IF EXISTS public.get_sorted_conversations();

-- Step 2: Create the new, updated version of the function.
CREATE OR REPLACE FUNCTION public.get_sorted_conversations()
RETURNS TABLE (
    id uuid,
    created_at timestamptz,
    shipment_id uuid,
    merchant_id uuid,
    driver_id uuid,
    last_message_time timestamptz,
    last_message_content text, -- The new column
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
        (SELECT m.content FROM public.messages m WHERE m.conversation_id = c.id ORDER BY m.created_at DESC LIMIT 1) as last_message_content,
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