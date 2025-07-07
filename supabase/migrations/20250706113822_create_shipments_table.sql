-- Creates the shipments table and its specific policies

-- 1. Create the shipments table
CREATE TABLE public.shipments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    merchant_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    pickup_location TEXT NOT NULL,
    destination TEXT NOT NULL,
    suggested_price NUMERIC,
    status TEXT DEFAULT 'open' NOT NULL -- can be 'open', 'in_progress', 'completed'
);

-- 2. Enable Row Level Security (RLS) for the table
ALTER TABLE public.shipments ENABLE ROW LEVEL SECURITY;

-- 3. Create Policies for the shipments table
CREATE POLICY "Merchants can create their own shipments." 
ON public.shipments FOR INSERT 
WITH CHECK (auth.uid() = merchant_id);

CREATE POLICY "Merchants can view their own shipments." 
ON public.shipments FOR SELECT 
USING (auth.uid() = merchant_id);

CREATE POLICY "Merchants can update their own open shipments." 
ON public.shipments FOR UPDATE 
USING (auth.uid() = merchant_id AND status = 'open');

CREATE POLICY "Drivers can view all open shipments." 
ON public.shipments FOR SELECT 
USING (public.get_my_claim('user_type')::text = 'driver' AND status = 'open');