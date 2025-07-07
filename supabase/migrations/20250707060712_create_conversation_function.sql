CREATE OR REPLACE FUNCTION create_or_get_conversation(
    recipient_id_input UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conversation_id_result UUID;
    current_user_id UUID := auth.uid();
BEGIN
    -- ابحث عن محادثة حالية بين المستخدمين
    SELECT id INTO conversation_id_result
    FROM public.conversations
    WHERE (merchant_id = current_user_id AND driver_id = recipient_id_input)
       OR (merchant_id = recipient_id_input AND driver_id = current_user_id);

    -- إذا تم العثور على محادثة، أرجع المعرف الخاص بها
    IF conversation_id_result IS NOT NULL THEN
        RETURN conversation_id_result;
    END IF;

    -- إذا لم يتم العثور على محادثة، قم بإنشاء واحدة جديدة
    -- (ملاحظة: هذا الجزء يفترض أن المنشئ هو التاجر، يمكن تحسينه لاحقًا)
    INSERT INTO public.conversations (merchant_id, driver_id)
    VALUES (current_user_id, recipient_id_input)
    RETURNING id INTO conversation_id_result;

    RETURN conversation_id_result;
END;
$$;