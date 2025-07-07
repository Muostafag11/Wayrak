-- This script fixes the RLS policies for the messages and conversations tables.

-- 1. Drop the old, incorrect policies for messages.
DROP POLICY IF EXISTS "Users can view messages in conversations they are part of." ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages in conversations they are part of." ON public.messages;

-- 2. Create the new, correct SELECT policy for messages.
-- Allows users to see messages if they are part of the conversation.
CREATE POLICY "Users can view messages in their conversations."
ON public.messages FOR SELECT
USING (
  conversation_id IN (
    SELECT id FROM public.conversations
    WHERE auth.uid() = merchant_id OR auth.uid() = driver_id
  )
);

-- 3. Create the new, correct INSERT policy for messages.
-- Allows users to send messages if they are the sender and part of the conversation.
CREATE POLICY "Users can send messages in their conversations."
ON public.messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id AND
  conversation_id IN (
    SELECT id FROM public.conversations
    WHERE auth.uid() = merchant_id OR auth.uid() = driver_id
  )
);