export const config = {
  api: {
    baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080',
  },
  app: {
    name: 'meuPortefólio',
    version: '1.0.0',
    description: 'Plataforma de Gestão de Portfólio - Projeto Universitário',
  },
  auth: {
    tokenKey: 'meuportefolio_token',
    userKey: 'meuportefolio_user',
  },
} as const 