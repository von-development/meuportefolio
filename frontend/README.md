# meuPortfolio - Frontend

## Descrição

O **meuPortfolio Frontend** é uma aplicação web moderna desenvolvida em **React** com **Next.js 15**, projetada para fornecer uma interface intuitiva e responsiva para o gerenciamento de portfólios de investimento. A aplicação conecta-se ao backend API em Rust para oferecer funcionalidades completas de trading, análise de risco e gestão de ativos.

## Funcionalidades Principais

### **Interface de Usuário**
- Design moderno e responsivo com Tailwind CSS
- Componentes acessíveis usando Radix UI
- Tema consistente e experiência de usuário otimizada
- Suporte completo para dispositivos mobile e desktop

### **Autenticação e Gestão de Usuários**
- Sistema de login/logout seguro
- Registro de novos usuários
- Gestão de perfil e configurações
- Persistência de sessão com JWT

### **Dashboard e Analytics**
- Visão geral de todos os portfólios
- Gráficos interativos de performance
- Métricas de risco em tempo real
- Sumários financeiros detalhados

### **Gestão de Portfólios**
- Criação e edição de portfólios
- Visualização de holdings e balanços
- Histórico de transações
- Análise de rentabilidade

### **Sistema de Trading**
- Interface intuitiva para compra/venda de ativos
- Cotações em tempo real
- Validação de ordens
- Confirmações de transações

### **Gestão de Ativos**
- Listagem completa de ativos disponíveis
- Filtros por tipo (Stocks, Crypto, Commodities, Índices)
- Histórico de preços com gráficos
- Informações detalhadas de cada ativo

### **Análise de Risco**
- Visualização de métricas de risco
- Gráficos de volatilidade
- Tendências de performance
- Relatórios de análise

## Stack Tecnológica

### Tecnologias Principais
```json
"next": "15.3.3"              // Framework React com SSR
"react": "^19.0.0"            // Library core
"typescript": "^5"            // Tipagem estática
"tailwindcss": "^4"           // CSS framework
```

### UI e Componentes
```json
"@radix-ui/*": "^1.x"         // Componentes acessíveis
"lucide-react": "^0.511.0"    // Ícones SVG
"class-variance-authority": "^0.7.1"  // Variações de componentes
"clsx": "^2.1.1"              // Utilitário CSS
```

### Forms e Validação
```json
"react-hook-form": "^7.56.4"  // Gestão de formulários
"@hookform/resolvers": "^5.0.1"  // Resolvers para validação
"zod": "^3.25.42"             // Schema validation
```

### Visualização de Dados
```json
"recharts": "^2.15.3"         // Gráficos e charts
"sonner": "^2.0.4"            // Notificações toast
```

## Estrutura do Projeto

```
frontend/
├── app/                    # App Router (Next.js 13+)
│   ├── page.tsx           # Homepage principal
│   ├── layout.tsx         # Layout raiz da aplicação
│   ├── globals.css        # Estilos globais
│   ├── login/             # Páginas de autenticação
│   ├── signup/            # Registo de utilizadores
│   ├── dashboard/         # Dashboard principal
│   ├── portfolios/        # Gestão de portfolios
│   ├── trading/           # Interface de trading
│   ├── assets/            # Visualização de ativos
│   └── not-found.tsx      # Página 404
├── components/            # Componentes reutilizáveis
│   ├── ui/               # Componentes base (Radix UI)
│   ├── dashboard/        # Componentes do dashboard
│   ├── portfolio/        # Componentes de portfolio
│   ├── assets/           # Componentes de ativos
│   └── layout/           # Componentes de layout
├── contexts/             # Contextos React (estado global)
│   └── AuthContext.tsx   # Contexto de autenticação
├── lib/                  # Utilities e configurações
│   ├── api.ts           # Cliente API para backend
│   ├── auth.ts          # Utilitários de autenticação
│   ├── config.ts        # Configurações da aplicação
│   └── utils.ts         # Funções utilitárias
├── public/              # Assets estáticos
│   └── *.svg           # Ícones e imagens
├── package.json         # Dependências e scripts
├── Dockerfile          # Container configuration
├── next.config.ts      # Configuração Next.js
└── tailwind.config.js  # Configuração Tailwind CSS
```

## Pré-requisitos

**IMPORTANTE**: Antes de executar o frontend, certifique-se de que o backend está rodando:

### Opção 1: Backend com Docker
```bash
cd backend
docker-compose up --build backend
# Ou: docker run -p 8080:8080 --env-file .env meuportefolio-backend
```

### Opção 2: Backend com Rust
```bash
cd backend
cp .env.example .env
# Configure suas variáveis de ambiente no .env
cargo run
```

Verifique se o backend está rodando em: `http://localhost:8080`

### Para o Frontend
- **Node.js 18+** (para desenvolvimento local)
- **npm, yarn, pnpm ou bun** (gerenciador de pacotes)
- **Docker** (opcional, para containerização)

## Configuração

### Variáveis de Ambiente

O frontend pode ser configurado através de variáveis de ambiente:

```env
# Configuração da API (opcional - tem fallback)
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1

# Configurações de build (opcional)
NEXT_TELEMETRY_DISABLED=1
NODE_ENV=development
```

## Executar o Frontend

### Método 1: Desenvolvimento Local (Recomendado)

1. **Instale as dependências:**
```bash
cd frontend
npm install
# ou
yarn install
# ou
pnpm install
```

2. **Execute o servidor de desenvolvimento:**
```bash
npm run dev
# ou
yarn dev
# ou
pnpm dev
```

3. **Acesse a aplicação:**
```
http://localhost:3000
```

### Método 2: Docker para Desenvolvimento

1. **Build e execute com Docker:**
```bash
cd frontend
docker build --target dev -t meuportefolio-frontend-dev .
docker run -p 3000:3000 -v $(pwd):/app meuportefolio-frontend-dev
```

### Método 3: Docker para Produção

1. **Build da imagem de produção:**
```bash
cd frontend
docker build --target production -t meuportefolio-frontend .
```

2. **Execute o container:**
```bash
docker run -p 3000:3000 meuportefolio-frontend
```

### Método 4: Docker Compose (Ambiente Completo)

Na raiz do projeto:
```bash
docker-compose up --build
```

Isso executará tanto o backend quanto o frontend automaticamente.


## Conexão com o Backend

O frontend está configurado para conectar-se automaticamente ao backend:

- **URL padrão**: `http://localhost:8080/api/v1`
- **Configuração**: `frontend/lib/config.ts`
- **Override**: Variável `NEXT_PUBLIC_API_URL`

### Verificação de Conectividade
1. Acesse `http://localhost:3000`
2. Tente fazer login ou acessar o dashboard
3. Verifique o console do browser para erros de API

## Funcionalidades Implementadas

### Páginas Principais
- **/** - Homepage com apresentação
- **/login** - Autenticação de usuários
- **/signup** - Registo de novos usuários
- **/dashboard** - Dashboard principal com métricas
- **/portfolios** - Gestão de portfólios
- **/portfolios/[id]** - Detalhes de portfólio específico
- **/trading** - Interface de trading
- **/assets** - Listagem e detalhes de ativos

### Componentes Principais
- **AuthContext** - Gestão de estado de autenticação
- **Layout components** - Header, Sidebar, Footer
- **UI components** - Buttons, Forms, Cards, Tables
- **Chart components** - Gráficos de performance e risco
- **Form components** - Formulários validados com Zod

#

## Build e Deploy

### Build Local
```bash
npm run build
npm run start
```

### Build com Docker
```bash
docker build -t meuportefolio-frontend .
docker run -p 3000:3000 meuportefolio-frontend
```

## Troubleshooting

### Problemas Comuns

1. **Erro de conexão com API:**
   - Verifique se o backend está rodando em `http://localhost:8080`
   - Confirme as configurações em `lib/config.ts`

2. **Erro de dependências:**
   - Delete `node_modules` e `package-lock.json`
   - Execute `npm install` novamente

3. **Erro de build:**
   - Verifique se todas as tipagens TypeScript estão corretas
   - Execute `npm run lint` para verificar problemas

4. **Problemas de CORS:**
   - Certifique-se de que o backend tem CORS configurado
   - Verifique se a URL da API está correta

### Logs e Debug
```bash
# Ver logs de desenvolvimento
npm run dev

# Ver logs de produção
npm run start

# Debug com Docker
docker logs container_name
```

## Próximos Passos

1. Configure o arquivo `.env.local` se necessário
2. Certifique-se de que o backend está rodando
3. Execute `npm install && npm run dev`
4. Acesse `http://localhost:3000`
5. Teste a funcionalidade de login/registo

---

**Desenvolvido com Next.js e React**
