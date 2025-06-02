'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Shield, 
  AlertTriangle, 
  TrendingDown, 
  TrendingUp, 
  Crown,
  Lock,
  BarChart3,
  PieChart,
  Activity,
  Zap,
  Star,
  CheckCircle,
  RefreshCw,
  Target
} from 'lucide-react'
import Link from 'next/link'

interface PortfolioRiskSummary {
  portfolio_id: number
  volatility: number
  beta: number
  sharpe_ratio: number
  max_drawdown: number
  var_95: number
  diversification_ratio: number
  correlation_matrix?: any
  sector_concentration: any[]
  risk_score: number
  risk_level: string
  portfolio_value: number
  asset_count: number
  last_calculated: string
  recommendations: string[]
}

interface RiskAnalysisSectionProps {
  portfolioId: string
  userId: string
  isPremium: boolean
  formatCurrency: (amount: number) => string
}

export default function RiskAnalysisSection({ portfolioId, userId, isPremium, formatCurrency }: RiskAnalysisSectionProps) {
  const [portfolioRisk, setPortfolioRisk] = useState<PortfolioRiskSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    if (isPremium) {
      fetchPortfolioRiskData()
    } else {
      setLoading(false)
    }
  }, [portfolioId, isPremium])

  const fetchPortfolioRiskData = async () => {
    try {
      setLoading(true)
      setError('')
      
      const portfolioRiskRes = await fetch(`http://localhost:8080/api/v1/risk/summary/portfolio/${portfolioId}`)

      if (portfolioRiskRes.ok) {
        const portfolioData = await portfolioRiskRes.json()
        setPortfolioRisk(portfolioData)
      } else if (portfolioRiskRes.status === 404) {
        setError('Nenhuma análise de risco disponível para este portfólio. Execute algumas transações primeiro.')
      } else {
        setError('Erro ao carregar análise de risco do portfólio.')
      }

    } catch (error) {
      console.error('Failed to fetch portfolio risk data:', error)
      setError('Erro ao carregar dados de risco do portfólio.')
    } finally {
      setLoading(false)
    }
  }

  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': 
      case 'conservative': return 'text-green-400'
      case 'medium': 
      case 'moderate': return 'text-yellow-400'
      case 'high': 
      case 'aggressive': return 'text-orange-400'
      case 'very high': 
      case 'very aggressive': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getRiskIcon = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': 
      case 'conservative': return <Shield className="h-5 w-5 text-green-400" />
      case 'medium': 
      case 'moderate': return <Activity className="h-5 w-5 text-yellow-400" />
      case 'high': 
      case 'aggressive': return <AlertTriangle className="h-5 w-5 text-orange-400" />
      case 'very high': 
      case 'very aggressive': return <TrendingDown className="h-5 w-5 text-red-400" />
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

  // Premium Content
  if (isPremium) {
    return (
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Shield className="h-6 w-6 text-blue-400" />
            <h2 className="text-2xl font-bold text-white">Análise de Risco do Portfólio</h2>
            <Badge className="bg-yellow-100 text-yellow-800">
              <Crown className="h-3 w-3 mr-1" />
              Premium
            </Badge>
          </div>
          <div className="flex items-center gap-2">
            <Button 
              onClick={fetchPortfolioRiskData} 
              variant="outline" 
              size="sm" 
              className="border-gray-600 text-gray-300"
              disabled={loading}
            >
              <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              Atualizar
            </Button>
            <Button variant="outline" size="sm" className="border-gray-600 text-gray-300">
              <BarChart3 className="h-4 w-4 mr-2" />
              Relatório Completo
            </Button>
          </div>
        </div>

        {loading ? (
          <div className="text-center py-12">
            <RefreshCw className="h-12 w-12 animate-spin text-blue-400 mx-auto mb-4" />
            <p className="text-gray-400 text-lg">A carregar análise de risco do portfólio...</p>
          </div>
        ) : error ? (
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardContent className="p-8 text-center">
              <AlertTriangle className="h-12 w-12 text-yellow-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Dados de Risco Indisponíveis</h3>
              <p className="text-gray-400 mb-6">{error}</p>
              <Button onClick={fetchPortfolioRiskData} className="bg-blue-600 hover:bg-blue-700">
                <RefreshCw className="h-4 w-4 mr-2" />
                Tentar Novamente
              </Button>
            </CardContent>
          </Card>
        ) : portfolioRisk ? (
          <>
            {/* Risk Overview Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-400">Nível de Risco</span>
                    {getRiskIcon(portfolioRisk.risk_level)}
                  </div>
                  <div className={`text-2xl font-bold ${getRiskColor(portfolioRisk.risk_level)}`}>
                    {portfolioRisk.risk_level || 'N/A'}
                  </div>
                  <p className="text-sm text-gray-500">Score: {portfolioRisk.risk_score?.toFixed(1) || 'N/A'}/10</p>
                </CardContent>
              </Card>

              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-400">Volatilidade</span>
                    <Activity className="h-5 w-5 text-purple-400" />
                  </div>
                  <div className="text-2xl font-bold text-white">
                    {`${((portfolioRisk.volatility || 0) * 100).toFixed(1)}%`}
                  </div>
                  <p className="text-sm text-gray-500">Anualizada</p>
                </CardContent>
              </Card>

              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-400">Sharpe Ratio</span>
                    <TrendingUp className="h-5 w-5 text-green-400" />
                  </div>
                  <div className="text-2xl font-bold text-white">
                    {portfolioRisk.sharpe_ratio?.toFixed(2) || 'N/A'}
                  </div>
                  <p className="text-sm text-gray-500">Risk-adjusted return</p>
                </CardContent>
              </Card>

              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-400">Max Drawdown</span>
                    <TrendingDown className="h-5 w-5 text-red-400" />
                  </div>
                  <div className="text-2xl font-bold text-white">
                    {`${((portfolioRisk.max_drawdown || 0) * 100).toFixed(1)}%`}
                  </div>
                  <p className="text-sm text-gray-500">Maior perda</p>
                </CardContent>
              </Card>
            </div>

            {/* Detailed Analysis */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Portfolio Risk Details */}
              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardHeader>
                  <CardTitle className="text-white flex items-center gap-2">
                    <PieChart className="h-5 w-5 text-blue-400" />
                    Métricas Detalhadas
                  </CardTitle>
                  <CardDescription className="text-gray-400">
                    Análise completa do risco do portfólio
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">Beta</span>
                    <span className="text-white font-medium">{portfolioRisk.beta?.toFixed(2) || 'N/A'}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">VaR (95%)</span>
                    <span className="text-white font-medium">
                      {`${((portfolioRisk.var_95 || 0) * 100).toFixed(1)}%`}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">Diversificação</span>
                    <span className="text-white font-medium">
                      {portfolioRisk.diversification_ratio?.toFixed(2) || 'N/A'}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">Valor do Portfólio</span>
                    <span className="text-green-400 font-medium">
                      {formatCurrency(portfolioRisk.portfolio_value || 0)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">Número de Ativos</span>
                    <span className="text-white font-medium">{portfolioRisk.asset_count || 0}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-400">Última Atualização</span>
                    <span className="text-gray-300 text-sm">{portfolioRisk.last_calculated ? formatDate(portfolioRisk.last_calculated) : 'N/A'}</span>
                  </div>
                </CardContent>
              </Card>

              {/* Risk Recommendations */}
              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardHeader>
                  <CardTitle className="text-white flex items-center gap-2">
                    <Zap className="h-5 w-5 text-yellow-400" />
                    Recomendações
                  </CardTitle>
                  <CardDescription className="text-gray-400">
                    Sugestões para otimizar o risco do portfólio
                  </CardDescription>
                </CardHeader>
                <CardContent>
                  {portfolioRisk.recommendations && portfolioRisk.recommendations.length > 0 ? (
                    <div className="space-y-3">
                      {portfolioRisk.recommendations.slice(0, 4).map((rec, index) => (
                        <div key={index} className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-yellow-900/30 to-gray-800/30 border border-yellow-800/40">
                          <Star className="h-4 w-4 text-yellow-400 mt-0.5 flex-shrink-0" />
                          <p className="text-gray-300 text-sm">{rec}</p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {/* Default recommendations based on risk level */}
                      {portfolioRisk.risk_level?.toLowerCase() === 'low' && (
                        <>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-green-900/30 to-gray-800/30 border border-green-800/40">
                            <Star className="h-4 w-4 text-green-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">✅ Portfólio bem balanceado com risco baixo</p>
                          </div>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-blue-900/30 to-gray-800/30 border border-blue-800/40">
                            <Star className="h-4 w-4 text-blue-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">💡 Considere adicionar alguns ativos de crescimento</p>
                          </div>
                        </>
                      )}
                      {portfolioRisk.risk_level?.toLowerCase() === 'medium' && (
                        <>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-yellow-900/30 to-gray-800/30 border border-yellow-800/40">
                            <Star className="h-4 w-4 text-yellow-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">⚖️ Bom equilíbrio entre risco e retorno</p>
                          </div>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-blue-900/30 to-gray-800/30 border border-blue-800/40">
                            <Star className="h-4 w-4 text-blue-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">💡 Monitore correlações entre ativos</p>
                          </div>
                        </>
                      )}
                      {portfolioRisk.risk_level?.toLowerCase() === 'high' && (
                        <>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-orange-900/30 to-gray-800/30 border border-orange-800/40">
                            <Star className="h-4 w-4 text-orange-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">⚠️ Alto potencial, mas considere diversificar mais</p>
                          </div>
                          <div className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-blue-900/30 to-gray-800/30 border border-blue-800/40">
                            <Star className="h-4 w-4 text-blue-400 mt-0.5 flex-shrink-0" />
                            <p className="text-gray-300 text-sm">💡 Considere estratégias de stop-loss</p>
                          </div>
                        </>
                      )}
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>

            {/* Risk Level Explanation */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Target className="h-5 w-5 text-purple-400" />
                  Interpretação do Nível de Risco
                </CardTitle>
                <CardDescription className="text-gray-400">
                  Entenda o que significa o nível de risco do seu portfólio
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div className="space-y-3">
                    <h4 className="text-white font-medium">Score de Risco: {portfolioRisk.risk_score?.toFixed(1) || 'N/A'}/10</h4>
                    <div className="w-full bg-gray-700 rounded-full h-3">
                      <div 
                        className={`h-3 rounded-full ${
                          (portfolioRisk.risk_score || 0) <= 3 ? 'bg-green-400' :
                          (portfolioRisk.risk_score || 0) <= 6 ? 'bg-yellow-400' :
                          (portfolioRisk.risk_score || 0) <= 8 ? 'bg-orange-400' : 'bg-red-400'
                        }`}
                        style={{ width: `${((portfolioRisk.risk_score || 0) / 10) * 100}%` }}
                      ></div>
                    </div>
                    <div className="text-sm text-gray-400 space-y-1">
                      <p><span className="text-green-400">0-3:</span> Conservador</p>
                      <p><span className="text-yellow-400">4-6:</span> Moderado</p>
                      <p><span className="text-orange-400">7-8:</span> Agressivo</p>
                      <p><span className="text-red-400">9-10:</span> Muito Agressivo</p>
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <h4 className="text-white font-medium">Principais Características</h4>
                    <div className="space-y-2 text-sm">
                      <div className="flex items-center gap-2">
                        <div className={`w-2 h-2 rounded-full ${
                          (portfolioRisk.volatility || 0) < 0.15 ? 'bg-green-400' :
                          (portfolioRisk.volatility || 0) < 0.25 ? 'bg-yellow-400' : 'bg-red-400'
                        }`}></div>
                        <span className="text-gray-300">
                          Volatilidade {(portfolioRisk.volatility || 0) < 0.15 ? 'baixa' : (portfolioRisk.volatility || 0) < 0.25 ? 'moderada' : 'alta'}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <div className={`w-2 h-2 rounded-full ${
                          (portfolioRisk.diversification_ratio || 0) > 0.8 ? 'bg-green-400' :
                          (portfolioRisk.diversification_ratio || 0) > 0.6 ? 'bg-yellow-400' : 'bg-red-400'
                        }`}></div>
                        <span className="text-gray-300">
                          Diversificação {(portfolioRisk.diversification_ratio || 0) > 0.8 ? 'excelente' : (portfolioRisk.diversification_ratio || 0) > 0.6 ? 'boa' : 'limitada'}
                        </span>
                      </div>
                      <div className="flex items-center gap-2">
                        <div className={`w-2 h-2 rounded-full ${
                          (portfolioRisk.sharpe_ratio || 0) > 1.5 ? 'bg-green-400' :
                          (portfolioRisk.sharpe_ratio || 0) > 0.8 ? 'bg-yellow-400' : 'bg-red-400'
                        }`}></div>
                        <span className="text-gray-300">
                          Retorno ajustado ao risco {(portfolioRisk.sharpe_ratio || 0) > 1.5 ? 'excelente' : (portfolioRisk.sharpe_ratio || 0) > 0.8 ? 'bom' : 'a melhorar'}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>
              </CardContent>
            </Card>
          </>
        ) : (
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardContent className="p-8 text-center">
              <AlertTriangle className="h-12 w-12 text-yellow-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">Nenhum Dado Disponível</h3>
              <p className="text-gray-400 mb-6">Não foram encontrados dados de risco para este portfólio.</p>
              <Button onClick={fetchPortfolioRiskData} className="bg-blue-600 hover:bg-blue-700">
                <RefreshCw className="h-4 w-4 mr-2" />
                Tentar Novamente
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    )
  }

  // Basic User - Opaque/Teaser Content
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Shield className="h-6 w-6 text-gray-500" />
          <h2 className="text-2xl font-bold text-gray-400">Análise de Risco do Portfólio</h2>
          <Badge variant="outline" className="border-gray-600 text-gray-400">
            <Lock className="h-3 w-3 mr-1" />
            Premium
          </Badge>
        </div>
      </div>

      {/* Opaque Preview Cards */}
      <div className="relative">
        {/* Overlay */}
        <div className="absolute inset-0 bg-gradient-to-br from-gray-900/95 to-gray-800/95 backdrop-blur-sm z-10 rounded-lg flex items-center justify-center">
          <div className="text-center">
            <div className="bg-gradient-to-r from-yellow-400/20 to-yellow-600/20 rounded-full w-24 h-24 flex items-center justify-center mx-auto mb-6">
              <Crown className="h-12 w-12 text-yellow-400" />
            </div>
            <h3 className="text-2xl font-bold text-white mb-2">Análise de Risco Premium</h3>
            <p className="text-gray-300 mb-6 max-w-md">
              Desbloqueie insights avançados de risco, métricas detalhadas e recomendações personalizadas para este portfólio
            </p>
            <div className="space-y-3 mb-6">
              <div className="flex items-center justify-center gap-2 text-yellow-400">
                <CheckCircle className="h-4 w-4" />
                <span>Métricas específicas do portfólio</span>
              </div>
              <div className="flex items-center justify-center gap-2 text-yellow-400">
                <CheckCircle className="h-4 w-4" />
                <span>Análise de volatilidade e drawdown</span>
              </div>
              <div className="flex items-center justify-center gap-2 text-yellow-400">
                <CheckCircle className="h-4 w-4" />
                <span>Recomendações personalizadas</span>
              </div>
            </div>
            <Button asChild className="bg-gradient-to-r from-yellow-600 to-yellow-700 hover:from-yellow-700 hover:to-yellow-800 text-white">
              <Link href="/dashboard?tab=subscriptions">
                <Crown className="h-4 w-4 mr-2" />
                Upgrade para Premium
              </Link>
            </Button>
          </div>
        </div>

        {/* Blurred Preview Content */}
        <div className="opacity-50 blur-sm pointer-events-none">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
            {[
              { label: 'Nível de Risco', value: 'Medium', color: 'text-yellow-400' },
              { label: 'Volatilidade', value: '18.5%', color: 'text-white' },
              { label: 'Sharpe Ratio', value: '1.24', color: 'text-white' },
              { label: 'Max Drawdown', value: '12.3%', color: 'text-white' }
            ].map((item, index) => (
              <Card key={index} className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardContent className="p-6">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-400">{item.label}</span>
                    <Activity className="h-5 w-5 text-blue-400" />
                  </div>
                  <div className={`text-2xl font-bold ${item.color}`}>
                    {item.value}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white">Métricas Detalhadas</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-4">
                  {['Beta: 1.15', 'VaR (95%): 8.2%', 'Diversificação: 0.78'].map((metric, index) => (
                    <div key={index} className="flex justify-between">
                      <span className="text-gray-400">{metric.split(':')[0]}</span>
                      <span className="text-white">{metric.split(':')[1]}</span>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white">Recomendações</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-3">
                  {['Considere diversificar...', 'Reduza exposição a...', 'Adicione ativos de...'].map((rec, index) => (
                    <div key={index} className="flex items-start gap-3 p-3 rounded-lg bg-gray-700/30">
                      <Star className="h-4 w-4 text-yellow-400 mt-0.5" />
                      <p className="text-gray-300 text-sm">{rec}</p>
                    </div>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
} 