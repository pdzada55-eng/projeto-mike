-- Projeto Mike - Schema Completo do Banco de Dados
-- PostgreSQL 12+

-- ============================================================================
-- EXTENSÕES
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABELAS DE CONFIGURAÇÃO
-- ============================================================================

-- Tabela de Estados/Polícias Militares
CREATE TABLE IF NOT EXISTS states (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    abbreviation VARCHAR(2) NOT NULL UNIQUE,
    region VARCHAR(50),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Matérias
CREATE TABLE IF NOT EXISTS subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    color_code VARCHAR(7),
    icon_name VARCHAR(100),
    display_order INTEGER,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela de Assuntos (relacionados às Matérias)
CREATE TABLE IF NOT EXISTS topics (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    display_order INTEGER,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subject_id, name)
);

-- ============================================================================
-- TABELAS DE QUESTÕES
-- ============================================================================

-- Tabela de Questões
CREATE TABLE IF NOT EXISTS questions (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    state_id INTEGER NOT NULL REFERENCES states(id) ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    topic_id INTEGER NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
    enunciation TEXT NOT NULL,
    explanation TEXT,
    difficulty_level VARCHAR(20) CHECK (difficulty_level IN ('fácil', 'médio', 'difícil')),
    exam_year INTEGER,
    banca VARCHAR(255),
    source VARCHAR(255),
    question_number INTEGER,
    correct_answer CHAR(1) CHECK (correct_answer IN ('A', 'B', 'C', 'D', 'E')),
    image_url TEXT,
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'em_revisão')),
    views_count INTEGER DEFAULT 0,
    correct_count INTEGER DEFAULT 0,
    wrong_count INTEGER DEFAULT 0,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_questions_state_id ON questions(state_id);
CREATE INDEX idx_questions_subject_id ON questions(subject_id);
CREATE INDEX idx_questions_topic_id ON questions(topic_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty_level);
CREATE INDEX idx_questions_year ON questions(exam_year);
CREATE INDEX idx_questions_status ON questions(status);

-- Tabela de Alternativas
CREATE TABLE IF NOT EXISTS alternatives (
    id SERIAL PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    letter CHAR(1) NOT NULL CHECK (letter IN ('A', 'B', 'C', 'D', 'E')),
    content TEXT NOT NULL,
    image_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(question_id, letter)
);

CREATE INDEX idx_alternatives_question_id ON alternatives(question_id);

-- ============================================================================
-- TABELAS DE USUÁRIOS
-- ============================================================================

-- Tabela de Usuários
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    cpf VARCHAR(11) UNIQUE,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20),
    preferred_state_id INTEGER REFERENCES states(id),
    bio TEXT,
    profile_image_url TEXT,
    role VARCHAR(20) DEFAULT 'student' CHECK (role IN ('student', 'admin', 'moderator')),
    is_verified BOOLEAN DEFAULT false,
    last_login TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'inativo', 'bloqueado')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- Tabela de Sessões
CREATE TABLE IF NOT EXISTS sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(500) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_token ON sessions(token);

-- ============================================================================
-- TABELAS DE RESPOSTAS E DESEMPENHO
-- ============================================================================

-- Tabela de Respostas dos Usuários
CREATE TABLE IF NOT EXISTS user_answers (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    selected_answer CHAR(1) NOT NULL CHECK (selected_answer IN ('A', 'B', 'C', 'D', 'E')),
    is_correct BOOLEAN NOT NULL,
    time_spent_seconds INTEGER,
    attempt_number INTEGER DEFAULT 1,
    source VARCHAR(50) CHECK (source IN ('study', 'mock_exam', 'review')),
    answered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para performance
CREATE INDEX idx_user_answers_user_id ON user_answers(user_id);
CREATE INDEX idx_user_answers_question_id ON user_answers(question_id);
CREATE INDEX idx_user_answers_is_correct ON user_answers(is_correct);
CREATE INDEX idx_user_answers_answered_at ON user_answers(answered_at);

-- Tabela de Questões Favoritas
CREATE TABLE IF NOT EXISTS favorites (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, question_id)
);

CREATE INDEX idx_favorites_user_id ON favorites(user_id);
CREATE INDEX idx_favorites_question_id ON favorites(question_id);

-- Tabela de Desempenho por Matéria
CREATE TABLE IF NOT EXISTS user_subject_performance (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject_id INTEGER NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    total_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    wrong_answers INTEGER DEFAULT 0,
    accuracy_percentage DECIMAL(5, 2) DEFAULT 0,
    last_studied TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, subject_id)
);

CREATE INDEX idx_user_subject_performance_user_id ON user_subject_performance(user_id);

-- ============================================================================
-- TABELAS DE SIMULADOS
-- ============================================================================

-- Tabela de Simulados
CREATE TABLE IF NOT EXISTS mock_exams (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state_id INTEGER NOT NULL REFERENCES states(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    total_questions INTEGER NOT NULL,
    time_limit_minutes INTEGER,
    status VARCHAR(20) DEFAULT 'rascunho' CHECK (status IN ('rascunho', 'em_progresso', 'finalizado', 'corrigido')),
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mock_exams_user_id ON mock_exams(user_id);
CREATE INDEX idx_mock_exams_state_id ON mock_exams(state_id);
CREATE INDEX idx_mock_exams_status ON mock_exams(status);

-- Tabela de Questões no Simulado
CREATE TABLE IF NOT EXISTS mock_exam_questions (
    id SERIAL PRIMARY KEY,
    mock_exam_id INTEGER NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
    question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
    question_order INTEGER NOT NULL,
    selected_answer CHAR(1) CHECK (selected_answer IN ('A', 'B', 'C', 'D', 'E', null)),
    is_answered BOOLEAN DEFAULT false,
    time_spent_seconds INTEGER DEFAULT 0,
    marked_for_review BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(mock_exam_id, question_id)
);

CREATE INDEX idx_mock_exam_questions_mock_exam_id ON mock_exam_questions(mock_exam_id);

-- Tabela de Resultados dos Simulados
CREATE TABLE IF NOT EXISTS mock_exam_results (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    mock_exam_id INTEGER NOT NULL REFERENCES mock_exams(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    total_questions INTEGER NOT NULL,
    correct_answers INTEGER NOT NULL,
    wrong_answers INTEGER NOT NULL,
    not_answered INTEGER NOT NULL,
    accuracy_percentage DECIMAL(5, 2) NOT NULL,
    total_time_seconds INTEGER,
    average_time_per_question_seconds DECIMAL(10, 2),
    estimated_score DECIMAL(5, 2),
    performance_level VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_mock_exam_results_user_id ON mock_exam_results(user_id);
CREATE INDEX idx_mock_exam_results_mock_exam_id ON mock_exam_results(mock_exam_id);

-- ============================================================================
-- TABELAS DE METAS E PLANEJAMENTO
-- ============================================================================

-- Tabela de Metas de Estudo
CREATE TABLE IF NOT EXISTS study_goals (
    id SERIAL PRIMARY KEY,
    uuid UUID DEFAULT uuid_generate_v4() UNIQUE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_accuracy DECIMAL(5, 2),
    target_questions_per_week INTEGER,
    start_date DATE NOT NULL,
    target_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'ativo' CHECK (status IN ('ativo', 'concluído', 'cancelado')),
    progress_percentage DECIMAL(5, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_goals_user_id ON study_goals(user_id);

-- Tabela de Histórico de Estudo
CREATE TABLE IF NOT EXISTS study_history (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    state_id INTEGER REFERENCES states(id),
    subject_id INTEGER REFERENCES subjects(id),
    questions_studied INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    wrong_answers INTEGER DEFAULT 0,
    study_duration_minutes INTEGER,
    study_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_study_history_user_id ON study_history(user_id);
CREATE INDEX idx_study_history_study_date ON study_history(study_date);

-- ============================================================================
-- TABELAS DE AUDITORIA E LOGS
-- ============================================================================

-- Tabela de Logs de Atividade
CREATE TABLE IF NOT EXISTS activity_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100),
    entity_id INTEGER,
    details JSONB,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_activity_logs_user_id ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_created_at ON activity_logs(created_at);

-- Tabela de Logs de Questões (para auditoria)
CREATE TABLE IF NOT EXISTS question_change_logs (
    id SERIAL PRIMARY KEY,
    question_id INTEGER NOT NULL REFERENCES questions(id),
    changed_by INTEGER REFERENCES users(id),
    change_type VARCHAR(20) CHECK (change_type IN ('create', 'update', 'delete')),
    old_data JSONB,
    new_data JSONB,
    change_reason TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_question_change_logs_question_id ON question_change_logs(question_id);

-- ============================================================================
-- INSERÇÃO DE DADOS INICIAIS
-- ============================================================================

-- Estados/Polícias Militares
INSERT INTO states (name, abbreviation, region) VALUES
('Acre', 'AC', 'Norte'),
('Alagoas', 'AL', 'Nordeste'),
('Amapá', 'AP', 'Norte'),
('Amazonas', 'AM', 'Norte'),
('Bahia', 'BA', 'Nordeste'),
('Ceará', 'CE', 'Nordeste'),
('Distrito Federal', 'DF', 'Centro-Oeste'),
('Espírito Santo', 'ES', 'Sudeste'),
('Goiás', 'GO', 'Centro-Oeste'),
('Maranhão', 'MA', 'Nordeste'),
('Mato Grosso', 'MT', 'Centro-Oeste'),
('Mato Grosso do Sul', 'MS', 'Centro-Oeste'),
('Minas Gerais', 'MG', 'Sudeste'),
('Pará', 'PA', 'Norte'),
('Paraíba', 'PB', 'Nordeste'),
('Paraná', 'PR', 'Sul'),
('Pernambuco', 'PE', 'Nordeste'),
('Piauí', 'PI', 'Nordeste'),
('Rio de Janeiro', 'RJ', 'Sudeste'),
('Rio Grande do Norte', 'RN', 'Nordeste'),
('Rio Grande do Sul', 'RS', 'Sul'),
('Rondônia', 'RO', 'Norte'),
('Roraima', 'RR', 'Norte'),
('Santa Catarina', 'SC', 'Sul'),
('São Paulo', 'SP', 'Sudeste'),
('Sergipe', 'SE', 'Nordeste'),
('Tocantins', 'TO', 'Norte')
ON CONFLICT (name) DO NOTHING;

-- Matérias
INSERT INTO subjects (name, description, color_code, icon_name, display_order) VALUES
('Língua Portuguesa', 'Interpretação de texto, gramática, ortografia e redação', '#FF5252', 'book', 1),
('Matemática', 'Aritmética, álgebra, geometria e cálculos', '#2196F3', 'calculator', 2),
('Raciocínio Lógico', 'Lógica, análise, deduções e argumentação', '#9C27B0', 'brain', 3),
('Direito Constitucional', 'Constituição Federal e direitos fundamentais', '#FF9800', 'scale', 4),
('Direito Administrativo', 'Lei de direito administrativo e processo administrativo', '#F44336', 'briefcase', 5),
('Direito Penal', 'Código Penal e criminal', '#795548', 'gavel', 6),
('Processo Penal', 'Procedimento criminal e processual', '#607D8B', 'legal', 7),
('Direitos Humanos', 'Direitos fundamentais e humanos', '#4CAF50', 'heart', 8),
('Informática', 'Noções de informática, Windows, Office', '#00BCD4', 'laptop', 9),
('Atualidades', 'Notícias, política, economia e cultura', '#FFC107', 'newspaper', 10),
('Legislação Específica', 'Leis específicas para Polícias Militares', '#673AB7', 'shield', 11)
ON CONFLICT (name) DO NOTHING;

-- Assuntos (Tópicos) para Língua Portuguesa
INSERT INTO topics (subject_id, name, description, display_order) VALUES
((SELECT id FROM subjects WHERE name = 'Língua Portuguesa'), 'Interpretação de Texto', 'Compreensão e análise de textos', 1),
((SELECT id FROM subjects WHERE name = 'Língua Portuguesa'), 'Gramática', 'Classes de palavras, sintaxe e morfologia', 2),
((SELECT id FROM subjects WHERE name = 'Língua Portuguesa'), 'Ortografia', 'Escrita correta das palavras', 3),
((SELECT id FROM subjects WHERE name = 'Língua Portuguesa'), 'Redação', 'Produção de texto e estrutura', 4),
((SELECT id FROM subjects WHERE name = 'Língua Portuguesa'), 'Pontuação', 'Uso correto de sinais de pontuação', 5)
ON CONFLICT (subject_id, name) DO NOTHING;

-- Assuntos para Matemática
INSERT INTO topics (subject_id, name, description, display_order) VALUES
((SELECT id FROM subjects WHERE name = 'Matemática'), 'Aritmética', 'Operações básicas e cálculos', 1),
((SELECT id FROM subjects WHERE name = 'Matemática'), 'Álgebra', 'Equações, sistemas e expressões', 2),
((SELECT id FROM subjects WHERE name = 'Matemática'), 'Geometria', 'Figuras, áreas e perímetros', 3),
((SELECT id FROM subjects WHERE name = 'Matemática'), 'Trigonometria', 'Seno, cosseno e funções trigonométricas', 4),
((SELECT id FROM subjects WHERE name = 'Matemática'), 'Estatística', 'Média, moda, mediana e análise de dados', 5)
ON CONFLICT (subject_id, name) DO NOTHING;

-- Assuntos para Direito Constitucional
INSERT INTO topics (subject_id, name, description, display_order) VALUES
((SELECT id FROM subjects WHERE name = 'Direito Constitucional'), 'Constituição Federal', 'Artigos e disposições constitucionais', 1),
((SELECT id FROM subjects WHERE name = 'Direito Constitucional'), 'Direitos Fundamentais', 'Direitos e deveres dos cidadãos', 2),
((SELECT id FROM subjects WHERE name = 'Direito Constitucional'), 'Separação de Poderes', 'Executivo, legislativo e judiciário', 3),
((SELECT id FROM subjects WHERE name = 'Direito Constitucional'), 'Emendas Constitucionais', 'Processo de modificação constitucional', 4)
ON CONFLICT (subject_id, name) DO NOTHING;

-- ============================================================================
-- VIEWS ÚTEIS
-- ============================================================================

-- View: Desempenho Geral do Usuário
CREATE OR REPLACE VIEW user_general_performance AS
SELECT 
    u.id,
    u.uuid,
    u.full_name,
    u.email,
    COUNT(DISTINCT ua.id) as total_questions_answered,
    SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) as correct_answers,
    SUM(CASE WHEN NOT ua.is_correct THEN 1 ELSE 0 END) as wrong_answers,
    ROUND(
        (SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::DECIMAL / 
         NULLIF(COUNT(DISTINCT ua.id), 0)) * 100, 2
    ) as overall_accuracy,
    MAX(ua.answered_at) as last_activity
FROM users u
LEFT JOIN user_answers ua ON u.id = ua.user_id
GROUP BY u.id, u.uuid, u.full_name, u.email;

-- View: Questões por Dificuldade
CREATE OR REPLACE VIEW questions_by_difficulty AS
SELECT 
    state_id,
    subject_id,
    difficulty_level,
    COUNT(*) as question_count,
    ROUND(AVG(correct_count::DECIMAL / NULLIF(views_count, 0)) * 100, 2) as average_accuracy
FROM questions
WHERE status = 'ativo'
GROUP BY state_id, subject_id, difficulty_level;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger nas tabelas principais
CREATE TRIGGER update_states_timestamp
BEFORE UPDATE ON states
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_subjects_timestamp
BEFORE UPDATE ON subjects
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_questions_timestamp
BEFORE UPDATE ON questions
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_users_timestamp
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

-- ============================================================================
-- COMENTÁRIOS SOBRE TABELAS
-- ============================================================================

COMMENT ON TABLE users IS 'Tabela principal de usuários da plataforma';
COMMENT ON TABLE questions IS 'Banco de questões da plataforma';
COMMENT ON TABLE user_answers IS 'Registro de respostas de usuários às questões';
COMMENT ON TABLE mock_exams IS 'Simulados criados pelos usuários';
COMMENT ON TABLE mock_exam_results IS 'Resultados dos simulados';
COMMENT ON TABLE user_subject_performance IS 'Desempenho do usuário por matéria';
