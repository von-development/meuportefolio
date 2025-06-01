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
  CheckCircle
} from 'lucide-react'
import Link from 'next/link'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, RadialBarChart, RadialBar } from 'recharts'

interface PortfolioRiskMetrics {
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
}

interface UserRiskSummary {
  user_id: string
  overall_risk_score: number
  portfolio_count: number
  total_value: number
  risk_distribution: any[]
  recommendations: string[]
}

interface RiskAnalysisSectionProps {
  portfolioId: string
  userId: string
  isPremium: boolean
  formatCurrency: (amount: number) => string
}

export default function RiskAnalysisSection({ portfolioId, userId, isPremium, formatCurrency }: RiskAnalysisSectionProps) {
  const [portfolioRisk, setPortfolioRisk] = useState<PortfolioRiskMetrics | null>(null)
  const [userRisk, setUserRisk] = useState<UserRiskSummary | null>(null)
  const [loading, setLoading] = useState(true)
  const [isUsingMockData, setIsUsingMockData] = useState(false)

  useEffect(() => {
    if (isPremium) {
      fetchRiskData()
    } else {
      // For non-premium users, also generate mock data instead of showing empty
      setPortfolioRisk(generateMockPortfolioRisk())
      setUserRisk(generateMockUserRisk())
      setIsUsingMockData(true)
      setLoading(false)
    }
  }, [portfolioId, userId, isPremium])

  const fetchRiskData = async () => {
    try {
      setLoading(true)
      
      const [portfolioRiskRes, userRiskRes] = await Promise.all([
        fetch(`http://localhost:8080/api/v1/risk/summary/portfolio/${portfolioId}`),
        fetch(`http://localhost:8080/api/v1/risk/summary/user/${userId}`)
      ])

      let portfolioData = null
      let userData = null

      if (portfolioRiskRes.ok) {
        portfolioData = await portfolioRiskRes.json()
      }

      if (userRiskRes.ok) {
        userData = await userRiskRes.json()
      }

      // Generate mock data if API returns null or empty data
      if (!portfolioData || Object.keys(portfolioData).length === 0) {
        portfolioData = generateMockPortfolioRisk()
        setIsUsingMockData(true)
      }

      if (!userData || Object.keys(userData).length === 0) {
        userData = generateMockUserRisk()
        setIsUsingMockData(true)
      }

      setPortfolioRisk(portfolioData)
      setUserRisk(userData)

    } catch (error) {
      console.error('Failed to fetch risk data:', error)
      // On error, also generate mock data instead of showing error
      setPortfolioRisk(generateMockPortfolioRisk())
      setUserRisk(generateMockUserRisk())
      setIsUsingMockData(true)
    } finally {
      setLoading(false)
    }
  }

  const generateMockPortfolioRisk = (): PortfolioRiskMetrics => {
    const riskLevels = ['Low', 'Medium', 'High']
    const randomRiskLevel = riskLevels[Math.floor(Math.random() * riskLevels.length)]
    
    return {
      portfolio_id: parseInt(portfolioId),
      volatility: 0.15 + Math.random() * 0.25, // 15% to 40%
      beta: 0.8 + Math.random() * 0.8, // 0.8 to 1.6
      sharpe_ratio: 0.5 + Math.random() * 1.5, // 0.5 to 2.0
      max_drawdown: -(0.05 + Math.random() * 0.25), // -5% to -30%
      var_95: -(0.02 + Math.random() * 0.15), // -2% to -17%
      diversification_ratio: 0.6 + Math.random() * 0.35, // 0.6 to 0.95
      correlation_matrix: {},
      sector_concentration: [],
      risk_score: 3 + Math.random() * 5, // 3 to 8
      risk_level: randomRiskLevel
    }
  }

  const generateMockUserRisk = (): UserRiskSummary => {
    const recommendations = [
      'Considere diversificar mais entre diferentes setores',
      'Reduza a exposição a ativos de alta volatilidade',
      'Adicione ativos de baixo risco ao seu portfólio',
      'Rebalanceie periodicamente para manter a diversificação',
      'Considere investir em ETFs para maior diversificação',
      'Monitore regularmente a correlação entre os seus ativos'
    ]

    return {
      user_id: userId,
      overall_risk_score: 4 + Math.random() * 4, // 4 to 8
      portfolio_count: 1,
      total_value: 10000 + Math.random() * 40000, // €10k to €50k
      risk_distribution: [],
      recommendations: recommendations.slice(0, 3 + Math.floor(Math.random() * 3)) // 3-5 recommendations
    }
  }

  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': return 'text-green-400'
      case 'medium': return 'text-yellow-400'
      case 'high': return 'text-orange-400'
      case 'very high': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getRiskIcon = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'low': return <Shield className="h-5 w-5 text-green-400" />
      case 'medium': return <Activity className="h-5 w-5 text-yellow-400" />
      case 'high': return <AlertTriangle className="h-5 w-5 text-orange-400" />
      case 'very high': return <TrendingDown className="h-5 w-5 text-red-400" />
      default: return <BarChart3 className="h-5 w-5 text-gray-400" />
    }
  }

  // Premium Content
  if (isPremium) {
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
            {isUsingMockData && (
              <Badge variant="outline" className="border-orange-600 text-orange-400">
                Demo Data
              </Badge>
            )}
          </div>
          <Button variant="outline" size="sm" className="border-gray-600 text-gray-300">
            <BarChart3 className="h-4 w-4 mr-2" />
            Relatório Completo
          </Button>
        </div>

        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <Card key={i} className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40 animate-pulse">
                <CardContent className="p-6">
                  <div className="h-24 bg-gray-700/50 rounded"></div>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <>
            {/* Risk Overview Cards */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {portfolioRisk && (
                <>
                  <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-gray-400">Nível de Risco</span>
                        {getRiskIcon(portfolioRisk.risk_level)}
                      </div>
                      <div className={`text-2xl font-bold ${getRiskColor(portfolioRisk.risk_level)}`}>
                        {portfolioRisk.risk_level}
                      </div>
                      <p className="text-sm text-gray-500">Score: {portfolioRisk.risk_score?.toFixed(1)}/10</p>
                    </CardContent>
                  </Card>

                  <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                    <CardContent className="p-6">
                      <div className="flex items-center justify-between mb-2">
                        <span className="text-gray-400">Volatilidade</span>
                        <Activity className="h-5 w-5 text-purple-400" />
                      </div>
                      <div className="text-2xl font-bold text-white">
                        {`${(portfolioRisk.volatility * 100).toFixed(1)}%`}
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
                        {portfolioRisk.sharpe_ratio?.toFixed(2)}
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
                        {`${(portfolioRisk.max_drawdown * 100).toFixed(1)}%`}
                      </div>
                      <p className="text-sm text-gray-500">Maior perda</p>
                    </CardContent>
                  </Card>
                </>
              )}
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
                </CardHeader>
                <CardContent className="space-y-4">
                  {portfolioRisk && (
                    <>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">Beta</span>
                        <span className="text-white font-medium">{portfolioRisk.beta?.toFixed(2)}</span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">VaR (95%)</span>
                        <span className="text-white font-medium">
                          {`${(portfolioRisk.var_95 * 100).toFixed(1)}%`}
                        </span>
                      </div>
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400">Diversificação</span>
                        <span className="text-white font-medium">
                          {portfolioRisk.diversification_ratio?.toFixed(2)}
                        </span>
                      </div>
                    </>
                  )}
                </CardContent>
              </Card>

              {/* Risk Recommendations */}
              <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                <CardHeader>
                  <CardTitle className="text-white flex items-center gap-2">
                    <Zap className="h-5 w-5 text-yellow-400" />
                    Recomendações
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {userRisk?.recommendations && userRisk.recommendations.length > 0 ? (
                    <div className="space-y-3">
                      {userRisk.recommendations.slice(0, 3).map((rec, index) => (
                        <div key={index} className="flex items-start gap-3 p-3 rounded-lg bg-gradient-to-r from-yellow-900/30 to-gray-800/30">
                          <Star className="h-4 w-4 text-yellow-400 mt-0.5 flex-shrink-0" />
                          <p className="text-gray-300 text-sm">{rec}</p>
                        </div>
                      ))}
                    </div>
                  ) : (
                    <div className="text-center py-8">
                      <Zap className="h-12 w-12 mx-auto mb-2 text-gray-600" />
                      <p className="text-gray-400">Nenhuma recomendação disponível</p>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </>
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
          <h2 className="text-2xl font-bold text-gray-400">Análise de Risco</h2>
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
              Desbloqueie insights avançados de risco, métricas detalhadas e recomendações personalizadas
            </p>
            <div className="space-y-3 mb-6">
              <div className="flex items-center justify-center gap-2 text-yellow-400">
                <CheckCircle className="h-4 w-4" />
                <span>Métricas de volatilidade e Sharpe ratio</span>
              </div>
              <div className="flex items-center justify-center gap-2 text-yellow-400">
                <CheckCircle className="h-4 w-4" />
                <span>Análise de diversificação</span>
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