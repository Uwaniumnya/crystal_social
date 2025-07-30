-- Create storage bucket for glimmer images
INSERT INTO storage.buckets (id, name, public)
VALUES ('glimmer-images', 'glimmer-images', true);

-- Create storage policies
CREATE POLICY "Public can view glimmer images" ON storage.objects 
FOR SELECT USING (bucket_id = 'glimmer-images');

CREATE POLICY "Authenticated users can upload glimmer images" ON storage.objects 
FOR INSERT WITH CHECK (
    bucket_id = 'glimmer-images' 
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update their own glimmer images" ON storage.objects 
FOR UPDATE USING (
    bucket_id = 'glimmer-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own glimmer images" ON storage.objects 
FOR DELETE USING (
    bucket_id = 'glimmer-images' 
    AND auth.uid()::text = (storage.foldername(name))[1]
);
