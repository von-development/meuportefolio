'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import Navbar from '@/components/layout/Navbar'
import TradingTab from '@/components/dashboard/TradingTab'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Activity, BarChart3, TrendingUp, Target, DollarSign, Zap } from 'lucide-react'

export default function TradingPage() {
  const { user, isAuthenticated } = useAuth()
  const router = useRouter()
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/login')
      return
    }
    setLoading(false)
  }, [isAuthenticated, router])

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('pt-PT', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  const handleRefresh = () => {
    // This will be called when trades are executed to refresh data
    window.location.reload()
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <div className="text-center">
            <Activity className="h-12 w-12 animate-pulse text-blue-400 mx-auto" />
            <p className="text-gray-400 mt-4 text-lg">A carregar plataforma de trading...</p>
          </div>
        </div>
      </div>
    )
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <Card className="max-w-md">
            <CardHeader>
              <CardTitle className="text-white">Acesso Negado</CardTitle>
              <CardDescription>É necessário estar autenticado para aceder ao trading.</CardDescription>
            </CardHeader>
          </Card>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Header Section */}
        <div className="mb-8">
          <div className="flex items-center gap-3 mb-4">
            <div className="bg-gradient-to-r from-blue-600/20 to-purple-600/20 rounded-xl p-3">
              <Activity className="h-8 w-8 text-blue-400" />
            </div>
            <div>
              <h1 className="text-4xl font-bold text-white">Trading Center</h1>
              <p className="text-gray-400 text-lg">Plataforma profissional de negociação de ativos</p>
            </div>
          </div>

          {/* Quick Stats/Features */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Card className="bg-gradient-to-br from-blue-900/30 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <BarChart3 className="h-6 w-6 text-blue-400" />
                  <div>
                    <p className="text-white font-semibold">Análise Avançada</p>
                    <p className="text-gray-400 text-sm">Gráficos em tempo real</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-green-900/30 to-gray-900/60 backdrop-blur-sm border border-green-800/40">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <TrendingUp className="h-6 w-6 text-green-400" />
                  <div>
                    <p className="text-white font-semibold">Multi-Asset</p>
                    <p className="text-gray-400 text-sm">Ações, Cripto, Commodities</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-purple-900/30 to-gray-900/60 backdrop-blur-sm border border-purple-800/40">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <Target className="h-6 w-6 text-purple-400" />
                  <div>
                    <p className="text-white font-semibold">Gestão de Risco</p>
                    <p className="text-gray-400 text-sm">Ordens inteligentes</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-yellow-900/30 to-gray-900/60 backdrop-blur-sm border border-yellow-800/40">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <Zap className="h-6 w-6 text-yellow-400" />
                  <div>
                    <p className="text-white font-semibold">Execução Rápida</p>
                    <p className="text-gray-400 text-sm">Trading instantâneo</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Trading Interface */}
        <TradingTab 
          userId={user.user_id} 
          formatCurrency={formatCurrency}
          onRefresh={handleRefresh}
        />
      </div>
    </div>
  )
} 