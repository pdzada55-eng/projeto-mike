# Projeto Mike - Plataforma de Preparação para Concursos das Polícias Militares

Uma plataforma web completa, profissional e responsiva para candidatos às Polícias Militares do Brasil.

## 🎯 Objetivo

Banco de questões interativo para estudar por estado, matéria, assunto e realizar simulados com acompanhamento de desempenho.

## 🚀 Características Principais

- ✅ Banco de questões com filtros avançados
- ✅ Simulados com cronômetro
- ✅ Painel de desempenho em tempo real
- ✅ Questões favoritas e revisão de erros
- ✅ Autenticação segura com JWT
- ✅ Painel administrativo protegido
- ✅ Interface responsiva (mobile-first)
- ✅ Design militar/policial profissional

## 📁 Estrutura do Projeto

```
projeto-mike/
├── backend/              # API Node.js + Express
│   ├── src/
│   │   ├── config/      # Configurações (BD, JWT, etc)
│   │   ├── controllers/ # Lógica das rotas
│   │   ├── models/      # Schemas do banco
│   │   ├── routes/      # Definição de rotas
│   │   ├── middleware/  # Autenticação, validações
│   │   ├── utils/       # Funções auxiliares
│   │   └── server.js    # Entrada da aplicação
│   ├── .env.example
│   └── package.json
│
├── frontend/            # React + TypeScript
│   ├── src/
│   │   ├── components/  # Componentes reutilizáveis
│   │   ├── pages/       # Páginas principais
│   │   ├── services/    # API calls
│   │   ├── store/       # State management
│   │   ├── styles/      # Tailwind + custom
│   │   ├── utils/       # Funções auxiliares
│   │   └── App.tsx      # Entrada da aplicação
│   ├── .env.example
│   └── package.json
│
├── database/            # Scripts SQL
│   └── schema.sql       # Estrutura completa do BD
│
└── docs/               # Documentação técnica
```

## 🛠️ Stack Tecnológico

**Backend:**
- Node.js 18+
- Express.js
- PostgreSQL
- JWT para autenticação
- Bcrypt para hash de senhas

**Frontend:**
- React 18+
- TypeScript
- Tailwind CSS
- React Router
- Axios para requisições

## 📋 Requisitos

- Node.js 18+
- PostgreSQL 12+
- npm ou yarn

## 🚀 Instalação

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Configure as variáveis de ambiente
npm run dev
```

### Frontend

```bash
cd frontend
npm install
cp .env.example .env
# Configure a URL da API
npm start
```

### Banco de Dados

```bash
psql -U postgres -f database/schema.sql
```

## 📝 Variáveis de Ambiente

Ver `.env.example` em cada pasta.

## 👨‍💼 Painel Administrativo

Acesso em `/admin` com credenciais de administrador.

Funcionalidades:
- Adicionar/editar/deletar questões
- Gerenciar estados e matérias
- Visualizar estatísticas
- Importar questões em lote

## 📊 Banco de Dados

Tabelas principais:
- `users` - Usuários e candidatos
- `states` - Estados/Polícias Militares
- `subjects` - Matérias (Português, Matemática, etc)
- `topics` - Assuntos dentro de matérias
- `questions` - Questões completas
- `alternatives` - Alternativas das questões
- `user_answers` - Histórico de respostas
- `favorites` - Questões favoritas
- `mock_exams` - Simulados
- `mock_exam_questions` - Questões em simulados
- `mock_exam_results` - Resultados dos simulados

## 🔐 Segurança

- Senhas hash com bcrypt
- JWT para autenticação
- Validação de entrada em todas as rotas
- Proteção CORS
- Rate limiting nas APIs

## 📱 Responsividade

- Mobile-first design
- Breakpoints: 320px, 768px, 1024px, 1280px
- Testes em dispositivos reais

## 📄 Licença

MIT

## 👥 Contribuições

Projeto em desenvolvimento. Contribuições bem-vindas!

---

**Desenvolvido com ❤️ para candidatos às Polícias Militares**
