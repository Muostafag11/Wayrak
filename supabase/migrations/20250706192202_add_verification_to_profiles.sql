-- This migration adds columns to the profiles table for driver verification.

ALTER TABLE public.profiles
ADD COLUMN id_card_url TEXT,         -- To store the URL of the ID card image
ADD COLUMN vehicle_license_url TEXT, -- To store the URL of the vehicle license image
ADD COLUMN is_verified BOOLEAN DEFAULT FALSE; -- To track the verification status