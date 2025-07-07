ALTER TABLE public.profiles
ADD COLUMN vehicle_type TEXT,
ADD COLUMN rating NUMERIC(2, 1) DEFAULT 5.0;