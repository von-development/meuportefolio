'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  AlertTriangle, 
  BarChart3, 
  TrendingUp, 
  Crown, 
  Lock, 
  Shield,
  Activity,
  TrendingDown,
  RefreshCw,
  Users,
  PieChart,
  DollarSign,
  ExternalLink
} from 'lucide-react'
import Link from 'next/link'

interface UserRiskSummary {
  user_id: string
  user_name: string
  user_type: string
  total_portfolios: number
  total_investment: number
  maximum_drawdown: number
  sharpe_ratio: number
  risk_level: string
  last_updated: string
}

interface Portfolio {
  portfolio_id: number
  user_id: string
  name: string
  creation_date: string
  current_funds: number
  current_profit_pct: number
  last_updated: string
}

interface RiskAnalysisTabProps {
  userId: string | undefined
  formatCurrency: (amount: number) => string
  isPremium?: boolean
}

export default function RiskAnalysisTab({ userId, formatCurrency, isPremium = false }: RiskAnalysisTabProps) {
  const [userRiskSummary, setUserRiskSummary] = useState<UserRiskSummary | null>(null)
  const [userPortfolios, setUserPortfolios] = useState<Portfolio[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (userId && isPremium) {
      fetchRiskData()
    }
  }, [userId, isPremium])

  const fetchRiskData = async () => {
    if (!userId) return

    setIsLoading(true)
    setError('')

    try {
      // Fetch user's portfolios first
      const portfoliosRes = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${userId}`)
      let portfolios: Portfolio[] = []
      
      if (portfoliosRes.ok) {
        portfolios = await portfoliosRes.json()
        setUserPortfolios(portfolios)
      }

      // Fetch user risk summary
      const userRiskRes = await fetch(`http://localhost:8080/api/v1/risk/metrics/user/${userId}`)
      
      if (userRiskRes.ok) {
        const userRiskData = await userRiskRes.json()
        setUserRiskSummary(userRiskData)
      } else if (userRiskRes.status === 404) {
        setError('Nenhuma análise de risco disponível. Execute algumas transações primeiro.')
      }
      
    } catch (error) {
      console.error('Failed to fetch risk data:', error)
      setError('Erro ao carregar dados de risco')
    } finally {
      setIsLoading(false)
    }
  }

  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'conservative': 
      case 'low': return 'text-green-400'
      case 'moderate': 
      case 'medium': return 'text-yellow-400'
      case 'aggressive': 
      case 'high': return 'text-orange-400'
      case 'very aggressive': 
      case 'very high': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getRiskIcon = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'conservative': 
      case 'low': return <Shield className="h-5 w-5 text-green-400" />
      case 'moderate': 
      case 'medium': return <Activity className="h-5 w-5 text-yellow-400" />
      case 'aggressive': 
      case 'high': return <AlertTriangle className="h-5 w-5 text-orange-400" />
      case 'very aggressive': 
      case 'very high': return <TrendingDown className="h-5 w-5 text-red-400" />
      default: return <BarChart3 className="h-5 w-5 text-gray-400" />
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-PT', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  // Premium users with data
  if (isPremium && (userRiskSummary || userPortfolios.length > 0) && !isLoading) {
    return (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-blue-400" />
            <h2 className="text-2xl font-bold text-white">Análise de Risco</h2>
            <Badge className="bg-yellow-100 text-yellow-800">
              <Crown className="h-3 w-3 mr-1" />
              Premium
            </Badge>
          </div>
          <Button 
            onClick={fetchRiskData} 
            variant="outline" 
            size="sm" 
            className="border-gray-600 text-gray-300"
            disabled={isLoading}
          >
            <RefreshCw className={`h-4 w-4 mr-2 ${isLoading ? 'animate-spin' : ''}`} />
            Atualizar
          </Button>
        </div>

        {/* User Risk Overview */}
        {userRiskSummary && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-gray-400">Nível de Risco</span>
                  {getRiskIcon(userRiskSummary.risk_level)}
                </div>
                <div className={`text-2xl font-bold ${getRiskColor(userRiskSummary.risk_level)}`}>
                  {userRiskSummary.risk_level || 'N/A'}
                </div>
                <p className="text-sm text-gray-500">Perfil de risco atual</p>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-gray-400">Portfólios</span>
                  <PieChart className="h-5 w-5 text-purple-400" />
                </div>
                <div className="text-2xl font-bold text-white">
                  {userRiskSummary.total_portfolios || 0}
                </div>
                <p className="text-sm text-gray-500">Total gerenciados</p>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-gray-400">Valor Total</span>
                  <DollarSign className="h-5 w-5 text-green-400" />
                </div>
                <div className="text-2xl font-bold text-white">
                  {formatCurrency(userRiskSummary.total_investment || 0)}
                </div>
                <p className="text-sm text-gray-500">Sob gestão</p>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-gray-400">Última Atualização</span>
                  <Activity className="h-5 w-5 text-orange-400" />
                </div>
                <div className="text-lg font-bold text-white">
                  {userRiskSummary.last_updated ? formatDate(userRiskSummary.last_updated) : 'N/A'}
                </div>
                <p className="text-sm text-gray-500">Cálculo de risco</p>
              </CardContent>
            </Card>
          </div>
        )}

        {/* User Metrics Summary */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-400" />
              Métricas de Performance
            </CardTitle>
            <CardDescription className="text-gray-400">
              Resumo das métricas de risco do utilizador
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Sharpe Ratio</span>
                  <span className="text-white font-medium">{userRiskSummary?.sharpe_ratio?.toFixed(2) || 'N/A'}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Maximum Drawdown</span>
                  <span className="text-white font-medium">{((userRiskSummary?.maximum_drawdown || 0) * 100).toFixed(1)}%</span>
                </div>
              </div>
              
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Tipo de Utilizador</span>
                  <span className="text-white font-medium">{userRiskSummary?.user_type}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Utilizador</span>
                  <span className="text-gray-300 font-medium">{userRiskSummary?.user_name}</span>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Portfolio Risk Summaries */}
        {userPortfolios.length > 0 && (
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader>
              <CardTitle className="text-white flex items-center gap-2">
                <PieChart className="h-5 w-5 text-blue-400" />
                Portfólios
              </CardTitle>
              <CardDescription className="text-gray-400">
                Clique num portfólio para ver a análise de risco específica
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {userPortfolios.map((portfolio) => (
                  <Link 
                    key={portfolio.portfolio_id}
                    href={`/portfolios/${portfolio.portfolio_id}?tab=risk-analysis`}
                    className="block group"
                  >
                    <Card className="bg-gradient-to-br from-gray-700/60 to-gray-800/60 backdrop-blur-sm border border-gray-600/40 hover:border-blue-500/40 transition-all duration-200 group-hover:scale-[1.02]">
                      <CardContent className="p-4">
                        <div className="flex items-center justify-between mb-3">
                          <h3 className="text-white font-medium group-hover:text-blue-300 transition-colors">
                            {portfolio.name}
                          </h3>
                          <div className="flex items-center gap-2">
                            <Shield className="h-5 w-5 text-blue-400" />
                            <ExternalLink className="h-4 w-4 text-gray-400 group-hover:text-blue-400 transition-colors" />
                          </div>
                        </div>
                        
                        <div className="space-y-2">
                          <div className="flex justify-between">
                            <span className="text-gray-400 text-sm">Fundos Atuais:</span>
                            <span className="text-green-400 text-sm font-medium">
                              {formatCurrency(portfolio.current_funds || 0)}
                            </span>
                          </div>
                          <div className="flex justify-between">
                            <span className="text-gray-400 text-sm">Performance:</span>
                            <span className={`text-sm font-medium ${(portfolio.current_profit_pct || 0) >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                              {(portfolio.current_profit_pct || 0) >= 0 ? '+' : ''}{(portfolio.current_profit_pct || 0).toFixed(2)}%
                            </span>
                          </div>
                        </div>
                        
                        <div className="mt-4 pt-3 border-t border-gray-600">
                          <div className="flex items-center justify-center gap-2 text-blue-300 group-hover:text-blue-200 transition-colors">
                            <Shield className="h-4 w-4" />
                            <span className="text-sm font-medium">Ver Análise de Risco Específica</span>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </Link>
                ))}
              </div>
            </CardContent>
          </Card>
        )}
      </div>
    )
  }

  // Premium users loading or with error
  if (isPremium && (isLoading || error)) {
    return (
      <div className="space-y-6">
        <div className="flex items-center gap-2">
          <Shield className="h-6 w-6 text-blue-400" />
          <h2 className="text-2xl font-bold text-white">Análise de Risco</h2>
          <Badge className="bg-yellow-100 text-yellow-800">
            <Crown className="h-3 w-3 mr-1" />
            Premium
          </Badge>
        </div>

        {isLoading ? (
          <div className="text-center py-12">
            <RefreshCw className="h-12 w-12 animate-spin text-blue-400 mx-auto mb-4" />
            <p className="text-gray-400 text-lg">A carregar análise de risco...</p>
          </div>
        ) : (
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardContent className="p-8 text-center">
              <AlertTriangle className="h-12 w-12 text-yellow-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Dados de Risco Indisponíveis</h3>
              <p className="text-gray-400 mb-6">{error}</p>
              <Button onClick={fetchRiskData} className="bg-blue-600 hover:bg-blue-700">
                <RefreshCw className="h-4 w-4 mr-2" />
                Tentar Novamente
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    )
  }

  // Non-premium users - show premium upsell
  return (
    <div className="space-y-6">
      {/* Premium Feature Notice */}
      <Card className="bg-gradient-to-br from-yellow-900/40 to-orange-900/40 border-yellow-600/40">
        <CardHeader>
          <CardTitle className="text-yellow-300 flex items-center">
            <Crown className="h-5 w-5 mr-2" />
            Funcionalidade Premium
          </CardTitle>
          <CardDescription className="text-yellow-400/80">
            Esta funcionalidade está disponível apenas para utilizadores Premium
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center p-3 rounded-lg bg-yellow-950/30 border border-yellow-800/40">
            <Lock className="h-5 w-5 text-yellow-400 mr-3" />
            <p className="text-yellow-200 text-sm">
              Acesso exclusivo para subscritores Premium. Analise o risco dos seus investimentos com algoritmos avançados.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Risk Analysis Preview */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <AlertTriangle className="h-5 w-5 mr-2" />
            Análise de Risco Avançada
          </CardTitle>
          <CardDescription className="text-gray-400">
            Ferramentas profissionais para análise de risco do portfólio
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {/* Feature List */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <h4 className="text-white font-medium flex items-center">
                  <BarChart3 className="h-4 w-4 mr-2 text-blue-400" />
                  Métricas de Risco
                </h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Score Geral de Risco</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Análise por Portfólio</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Volatilidade e Beta</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Maximum Drawdown</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <h4 className="text-white font-medium flex items-center">
                  <TrendingUp className="h-4 w-4 mr-2 text-green-400" />
                  Análises Avançadas
                </h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Recomendações Personalizadas</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Links Diretos para Portfólios</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Distribuição de Risco</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Histórico de Performance</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                </div>
              </div>
            </div>

            {/* Mock Risk Dashboard */}
            <div className="border-2 border-dashed border-gray-600 rounded-lg p-8 text-center bg-gray-800/20">
              <AlertTriangle className="h-16 w-16 mx-auto mb-4 text-gray-500" />
              <h3 className="text-lg font-medium text-white mb-2">Dashboard de Risco Completo</h3>
              <p className="text-gray-400 mb-6">
                Visualização interativa dos riscos de todos os seus portfólios aparecerá aqui
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Score Geral</p>
                  <p className="text-blue-400 text-2xl font-bold">--/10</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Portfólios</p>
                  <p className="text-green-400 text-2xl font-bold">--</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Valor Total</p>
                  <p className="text-yellow-400 text-2xl font-bold">--</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Risco Médio</p>
                  <p className="text-red-400 text-2xl font-bold">--</p>
                </div>
              </div>
              <Button disabled className="bg-gray-600 text-gray-300">
                <Lock className="h-4 w-4 mr-2" />
                Análise Bloqueada
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 