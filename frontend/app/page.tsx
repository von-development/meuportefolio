'use client'

import { useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { TrendingUp, BarChart3, PieChart, Search, Briefcase } from 'lucide-react'
import Navbar from '@/components/layout/Navbar'
import { useAuth } from '@/contexts/AuthContext'

export default function HeroPage() {
  const { isAuthenticated, loading } = useAuth()
  const router = useRouter()

  useEffect(() => {
    if (!loading && isAuthenticated) {
      router.push('/dashboard')
    }
  }, [isAuthenticated, loading, router])

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <p className="text-gray-400 mt-4">A carregar...</p>
        </div>
      </div>
    )
  }

  if (isAuthenticated) {
    return null // Will redirect to dashboard
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      {/* Navbar Superior */}
      <Navbar />

      {/* Hero Section */}
      <section className="px-6 py-32 text-center">
        <div className="max-w-6xl mx-auto">
          {/* Título Principal */}
          <div className="mb-16">
            <h1 className="text-7xl md:text-9xl font-bold text-white mb-6 tracking-tight">
              meu<span className="text-blue-400">Portfólio</span>
            </h1>
            
            {/* Subtítulo */}
            <p className="text-2xl md:text-3xl text-gray-300 mb-8 max-w-4xl mx-auto leading-relaxed font-light">
              Plataforma completa para gestão inteligente do seu portfólio de investimentos
            </p>
            
            <div className="w-24 h-1 bg-gradient-to-r from-blue-400 to-blue-600 mx-auto mb-16 rounded-full"></div>
          </div>

          {/* Call to Action Buttons */}
          <div className="mb-20">
            <div className="flex flex-col sm:flex-row items-center justify-center gap-6">
              <Button 
                asChild
                size="lg" 
                className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white text-xl px-12 py-6 rounded-xl transition-all hover:shadow-xl hover:shadow-blue-600/30 hover:scale-105 flex items-center gap-3"
              >
                <Link href="/signup">
                  <Briefcase className="h-6 w-6" />
                  Criar Conta Gratuita
                </Link>
              </Button>
              
              <Button 
                asChild
                size="lg" 
                variant="outline"
                className="bg-transparent border-2 border-blue-500 text-blue-400 hover:bg-blue-500 hover:text-white text-xl px-12 py-6 rounded-xl transition-all hover:scale-105 flex items-center gap-3"
              >
                <Link href="/assets">
                  <Search className="h-6 w-6" />
                  Explorar Ativos
                </Link>
              </Button>
            </div>
          </div>
          
          {/* Cards de Funcionalidades */}
          <div className="grid md:grid-cols-3 gap-8 mb-20 max-w-5xl mx-auto">
            <div className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm rounded-2xl p-10 border border-blue-800/40 hover:border-blue-500/60 transition-all duration-500 hover:bg-gradient-to-br hover:from-gray-800/80 hover:to-gray-900/80 group hover:scale-105 hover:shadow-2xl hover:shadow-blue-600/20">
              <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                <PieChart className="h-10 w-10 text-blue-400" />
              </div>
              <h3 className="text-2xl font-bold text-white mb-4">Análise de Portfólio</h3>
              <p className="text-gray-400 leading-relaxed">Visualize a distribuição dos seus investimentos com gráficos detalhados e métricas avançadas</p>
            </div>
            
            <div className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm rounded-2xl p-10 border border-blue-800/40 hover:border-blue-500/60 transition-all duration-500 hover:bg-gradient-to-br hover:from-gray-800/80 hover:to-gray-900/80 group hover:scale-105 hover:shadow-2xl hover:shadow-blue-600/20">
              <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                <TrendingUp className="h-10 w-10 text-blue-400" />
              </div>
              <h3 className="text-2xl font-bold text-white mb-4">Acompanhamento</h3>
              <p className="text-gray-400 leading-relaxed">Monitore a performance dos seus investimentos em tempo real com alertas personalizados</p>
            </div>
            
            <div className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm rounded-2xl p-10 border border-blue-800/40 hover:border-blue-500/60 transition-all duration-500 hover:bg-gradient-to-br hover:from-gray-800/80 hover:to-gray-900/80 group hover:scale-105 hover:shadow-2xl hover:shadow-blue-600/20">
              <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-6 group-hover:scale-110 transition-transform duration-300">
                <BarChart3 className="h-10 w-10 text-blue-400" />
              </div>
              <h3 className="text-2xl font-bold text-white mb-4">Relatórios</h3>
              <p className="text-gray-400 leading-relaxed">Gere relatórios completos e análises para tomada de decisões estratégicas</p>
            </div>
          </div>
        </div>
      </section>
          
      {/* Benefits Section */}
      <section className="px-6 py-20 bg-gradient-to-br from-gray-800/30 to-gray-900/30">
        <div className="max-w-6xl mx-auto text-center">
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-8">
            Porquê escolher o meuPortfólio?
          </h2>
          <p className="text-xl text-gray-300 mb-12 max-w-3xl mx-auto">
            Junte-se a milhares de investidores que já confiam na nossa plataforma
          </p>
          
          {/* Benefits Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8 mb-12">
            <div className="text-center group">
              <div className="text-4xl font-bold bg-gradient-to-r from-blue-400 to-blue-600 bg-clip-text text-transparent mb-3 group-hover:scale-110 transition-transform">100%</div>
              <div className="text-gray-400 text-lg font-medium">Gratuito</div>
              <div className="text-gray-500 text-sm mt-1">Sem taxas ocultas</div>
          </div>
            <div className="text-center group">
              <div className="text-4xl font-bold bg-gradient-to-r from-green-400 to-green-600 bg-clip-text text-transparent mb-3 group-hover:scale-110 transition-transform">24/7</div>
              <div className="text-gray-400 text-lg font-medium">Suporte</div>
              <div className="text-gray-500 text-sm mt-1">Sempre disponível</div>
            </div>
            <div className="text-center group">
              <div className="text-4xl font-bold bg-gradient-to-r from-purple-400 to-purple-600 bg-clip-text text-transparent mb-3 group-hover:scale-110 transition-transform">Bank</div>
              <div className="text-gray-400 text-lg font-medium">Segurança</div>
              <div className="text-gray-500 text-sm mt-1">Nível bancário</div>
            </div>
            <div className="text-center group">
              <div className="text-4xl font-bold bg-gradient-to-r from-orange-400 to-orange-600 bg-clip-text text-transparent mb-3 group-hover:scale-110 transition-transform">AI</div>
              <div className="text-gray-400 text-lg font-medium">Inteligência</div>
              <div className="text-gray-500 text-sm mt-1">Algoritmos avançados</div>
            </div>
          </div>
          
          <Button 
            asChild
            size="lg" 
            className="bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white text-xl px-12 py-6 rounded-xl transition-all hover:scale-105"
          >
            <Link href="/signup">
              Começar Agora - É Grátis
            </Link>
          </Button>
        </div>
      </section>
    </div>
  )
}
