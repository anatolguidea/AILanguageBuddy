-- Ensure lessons table exists (Flyway runs before Hibernate; match JPA schema).
CREATE TABLE IF NOT EXISTS lessons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_code VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    content_json JSONB,
    order_index INTEGER,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

-- Seed Spanish lessons (es). Same logic as existing: content_json NULL so LessonService
-- generates challenges from lexemes. Only runs when no Spanish lessons exist.
INSERT INTO lessons (id, language_code, title, description, content_json, order_index, created_at, updated_at)
SELECT gen_random_uuid(), 'es', t.title, t.description, NULL, t.ord, NOW(), NOW()
FROM (VALUES
    (1,  'Saludos y presentaciones', 'Aprende a saludar y presentarte en español'),
    (2,  'Números del 1 al 10', 'Cuenta y usa los números básicos'),
    (3,  'Colores básicos', 'Nombra los colores en español'),
    (4,  'La familia', 'Vocabulario de los miembros de la familia'),
    (5,  'Comida y bebida', 'Palabras para comer y beber'),
    (6,  'En el café', 'Pedir en un café o bar'),
    (7,  'Días de la semana', 'Los siete días de la semana'),
    (8,  'El tiempo y las estaciones', 'Hablar del clima'),
    (9,  'En la tienda', 'Compras y precios'),
    (10, 'Rutina diaria', 'Verbos y frases del día a día'),
    (11, 'Partes del cuerpo', 'El cuerpo humano'),
    (12, 'En el restaurante', 'Pedir platos y pagar'),
    (13, 'Transporte', 'Medios de transporte y direcciones'),
    (14, 'En el hotel', 'Registro y habitaciones'),
    (15, 'Ocio y aficiones', 'Hablar de hobbies'),
    (16, 'En el trabajo', 'Vocabulario laboral básico'),
    (17, 'Entrevista de trabajo', 'Frases para una entrevista'),
    (18, 'En el médico', 'Síntomas y consulta'),
    (19, 'En el banco', 'Abrir cuenta y operaciones'),
    (20, 'Tecnología e internet', 'Términos digitales'),
    (21, 'Expresar opiniones', 'Estar de acuerdo o en desacuerdo'),
    (22, 'Dar consejos', 'Recomendar y aconsejar'),
    (23, 'El pasado reciente', 'Qué hiciste ayer'),
    (24, 'Planes futuros', 'Qué vas a hacer'),
    (25, 'Comparaciones', 'Más que, menos que, tan como'),
    (26, 'Condicional y cortesía', 'Pedidos educados'),
    (27, 'Cocina y recetas', 'Ingredientes y verbos de cocina'),
    (28, 'Cine y cultura', 'Hablar de películas y series'),
    (29, 'Noticias y medios', 'Comentar la actualidad'),
    (30, 'Repaso general', 'Consolida lo aprendido')
) AS t(ord, title, description)
WHERE NOT EXISTS (SELECT 1 FROM lessons WHERE language_code = 'es' LIMIT 1);
