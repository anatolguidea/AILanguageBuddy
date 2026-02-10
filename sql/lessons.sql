-- Create lessons table
CREATE TABLE IF NOT EXISTS public.lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_code TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    content_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    order_index INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user_lesson_progress table
CREATE TABLE IF NOT EXISTS public.user_lesson_progress (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'started', -- started, completed
    completed_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (user_id, lesson_id)
);

-- Enable RLS
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_lesson_progress ENABLE ROW LEVEL SECURITY;

-- Policies for lessons (readable by everyone authenticated)
CREATE POLICY "Lessons are viewable by authenticated users" 
ON public.lessons FOR SELECT 
TO authenticated 
USING (true);

-- Policies for progress (users can read/write their own)
CREATE POLICY "Users can view their own progress" 
ON public.user_lesson_progress FOR SELECT 
TO authenticated 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own progress" 
ON public.user_lesson_progress FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" 
ON public.user_lesson_progress FOR UPDATE 
TO authenticated 
USING (auth.uid() = user_id);

-- Insert sample lessons
INSERT INTO public.lessons (language_code, title, description, order_index, content_json) VALUES
('es', 'Intro to Spanish', 'Basic greetings', 1, '{"sections": [{"type": "text", "content": "Hola means Hello."}]}'),
('es', 'At the Restaurant', 'Ordering food', 2, '{"sections": [{"type": "text", "content": "La cuenta, por favor."}]}'),
('fr', 'Bonjour!', 'French basics', 1, '{"sections": [{"type": "text", "content": "Bonjour means Hello."}]}');
