-- This migration adds a unique constraint to the phone_number
-- and updates the handle_new_user function to include more details.

-- 1. Add unique constraint to phone_number
ALTER TABLE public.profiles
ADD CONSTRAINT profiles_phone_number_key UNIQUE (phone_number);

-- 2. Recreate the function to handle new user sign-ups with all details
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET SEARCH_PATH = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, user_type, full_name, phone_number)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'user_type',
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone_number'
  );
  RETURN new;
END;
$$;