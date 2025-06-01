'use client'

import React, { useEffect, useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { 
  TrendingUp, 
  TrendingDown, 
  Wallet, 
  PieChart,
  BarChart3,
  Calendar,
  Target,
  Activity,
  DollarSign,
  AlertCircle,
  CheckCircle,
  Briefcase,
  Plus,
  Shield,
  Crown,
  Lock,
  RefreshCw
} from 'lucide-react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart as RechartsPieChart, Cell, Pie } from 'recharts'
import Link from 'next/link'

interface Portfolio {
  portfolio_id: number
  user_id: string
  name: string
  creation_date: string
  current_funds: number
  current_profit_pct: number
  last_updated: string
}

interface PortfolioBalance {
  portfolio_id: number
  portfolio_name: string
  cash_balance: number
  holdings_value: number
  total_portfolio_value: number
  holdings_count?: number
}

interface PortfolioSummary {
  portfolio_id: number
  portfolio_name: string
  owner: string
  current_funds: number
  current_profit_pct: number
  creation_date: string
  total_trades: number
}

interface AssetHolding {
  portfolio_id: number
  portfolio_name: string
  asset_id: number
  asset_name: string
  symbol: string
  asset_type: string
  quantity_held: number
  current_price: number
  market_value: number
}

interface PortfolioRiskMetrics {
  portfolio_id: number
  portfolio_name: string
  current_funds: number
  current_profit_pct: number
  maximum_drawdown: number
  beta: number
  sharpe_ratio: number
  risk_level: string
}

interface PortfolioOverviewProps {
  portfolio: Portfolio
  balance: PortfolioBalance | null
  summary: PortfolioSummary | null
  holdings: AssetHolding[]
  userComplete?: any // Add user data for premium check
  formatCurrency: (amount: number) => string
  formatDate: (dateString: string) => string
  formatPercentage: (percentage: number) => string
}

export default function PortfolioOverview({ 
  portfolio, 
  balance, 
  summary, 
  holdings, 
  userComplete,
  formatCurrency, 
  formatDate, 
  formatPercentage 
}: PortfolioOverviewProps) {

  const [riskMetrics, setRiskMetrics] = useState<PortfolioRiskMetrics | null>(null)
  const [riskLoading, setRiskLoading] = useState(false)
  const [isUsingMockRisk, setIsUsingMockRisk] = useState(false)

  const isPremium = userComplete?.is_premium || false

  useEffect(() => {
    if (portfolio?.portfolio_id && isPremium) {
      fetchRiskMetrics()
    }
  }, [portfolio?.portfolio_id, isPremium])

  const fetchRiskMetrics = async () => {
    try {
      setRiskLoading(true)
      const response = await fetch(`http://localhost:8080/api/v1/risk/metrics/portfolio/${portfolio.portfolio_id}`)
      
      if (response.ok) {
        const data = await response.json()
        if (data && Object.keys(data).length > 0) {
          setRiskMetrics(data)
          setIsUsingMockRisk(false)
        } else {
          // Generate mock data if API returns empty
          setRiskMetrics(generateMockRiskMetrics())
          setIsUsingMockRisk(true)
        }
      } else {
        // Generate mock data if API fails
        setRiskMetrics(generateMockRiskMetrics())
        setIsUsingMockRisk(true)
      }
    } catch (error) {
      console.error('Failed to fetch risk metrics:', error)
      // Generate mock data on error
      setRiskMetrics(generateMockRiskMetrics())
      setIsUsingMockRisk(true)
    } finally {
      setRiskLoading(false)
    }
  }

  const generateMockRiskMetrics = (): PortfolioRiskMetrics => {
    const riskLevels = ['Conservative', 'Moderate', 'Aggressive', 'Very Aggressive']
    const randomRiskLevel = riskLevels[Math.floor(Math.random() * riskLevels.length)]
    
    return {
      portfolio_id: portfolio.portfolio_id,
      portfolio_name: portfolio.name,
      current_funds: portfolio.current_funds,
      current_profit_pct: portfolio.current_profit_pct,
      maximum_drawdown: -(Math.random() * 25), // -0% to -25%
      beta: 0.8 + Math.random() * 1.2, // 0.8 to 2.0
      sharpe_ratio: Math.random() * 2, // 0 to 2.0
      risk_level: randomRiskLevel
    }
  }

  const getRiskColor = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'conservative': return 'text-green-400'
      case 'moderate': return 'text-yellow-400'
      case 'aggressive': return 'text-orange-400'
      case 'very aggressive': return 'text-red-400'
      default: return 'text-gray-400'
    }
  }

  const getRiskIcon = (riskLevel: string) => {
    switch (riskLevel?.toLowerCase()) {
      case 'conservative': return <Shield className="h-5 w-5 text-green-400" />
      case 'moderate': return <Activity className="h-5 w-5 text-yellow-400" />
      case 'aggressive': return <AlertCircle className="h-5 w-5 text-orange-400" />
      case 'very aggressive': return <TrendingDown className="h-5 w-5 text-red-400" />
      default: return <BarChart3 className="h-5 w-5 text-gray-400" />
    }
  }

  // Calculate portfolio metrics
  const totalValue = balance?.total_portfolio_value || 0
  const cashPercentage = balance ? (balance.cash_balance / totalValue) * 100 : 0
  const holdingsPercentage = balance ? (balance.holdings_value / totalValue) * 100 : 0
  
  // Generate allocation data for pie chart
  const allocationData = [
    { name: 'Dinheiro', value: cashPercentage, color: '#10B981' },
    { name: 'Investimentos', value: holdingsPercentage, color: '#3B82F6' }
  ]

  // Group holdings by asset type
  const holdingsByType = holdings.reduce((acc, holding) => {
    if (!acc[holding.asset_type]) {
      acc[holding.asset_type] = { count: 0, value: 0 }
    }
    acc[holding.asset_type].count += 1
    acc[holding.asset_type].value += holding.market_value
    return acc
  }, {} as Record<string, { count: number; value: number }>)

  // Mock performance data (in real app, this would come from an API)
  const performanceData = [
    { date: '30 dias', value: totalValue * 0.95 },
    { date: '25 dias', value: totalValue * 0.97 },
    { date: '20 dias', value: totalValue * 0.94 },
    { date: '15 dias', value: totalValue * 0.99 },
    { date: '10 dias', value: totalValue * 1.02 },
    { date: '5 dias', value: totalValue * 0.98 },
    { date: 'Hoje', value: totalValue }
  ]

  const getAssetTypeIcon = (type: string) => {
    switch (type?.toLowerCase()) {
      case 'stock': return '📈'
      case 'cryptocurrency': return '₿'
      case 'commodity': return '🥇'
      case 'index': return '📊'
      default: return '📋'
    }
  }

  const getAssetTypeColor = (type: string) => {
    switch (type?.toLowerCase()) {
      case 'stock': return 'text-blue-400'
      case 'cryptocurrency': return 'text-orange-400'
      case 'commodity': return 'text-yellow-400'
      case 'index': return 'text-purple-400'
      default: return 'text-gray-400'
    }
  }

  return (
    <div className="space-y-6">
      {/* Portfolio Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">{portfolio.name}</h1>
          <p className="text-gray-400">Criado em {formatDate(portfolio.creation_date)}</p>
        </div>
        <div className="text-right">
          <p className="text-gray-400 text-sm">Última atualização</p>
          <p className="text-white font-medium">{formatDate(portfolio.last_updated)}</p>
        </div>
      </div>

      {/* Key Metrics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-gray-400">Valor Total</span>
              <Wallet className="h-5 w-5 text-blue-400" />
            </div>
            <div className="text-2xl font-bold text-white">
              {formatCurrency(totalValue)}
            </div>
            <p className="text-sm text-gray-500">
              {balance?.holdings_count || holdings.length} {holdings.length === 1 ? 'ativo' : 'ativos'}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-gray-400">Rentabilidade</span>
              {portfolio.current_profit_pct >= 0 ? (
                <TrendingUp className="h-5 w-5 text-green-400" />
              ) : (
                <TrendingDown className="h-5 w-5 text-red-400" />
              )}
            </div>
            <div className={`text-2xl font-bold ${portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
              {formatPercentage(portfolio.current_profit_pct)}
            </div>
            <p className="text-sm text-gray-500">Total acumulado</p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-gray-400">Dinheiro</span>
              <DollarSign className="h-5 w-5 text-green-400" />
            </div>
            <div className="text-2xl font-bold text-white">
              {formatCurrency(balance?.cash_balance || portfolio.current_funds)}
            </div>
            <p className="text-sm text-gray-500">
              {cashPercentage.toFixed(1)}% do portfólio
            </p>
          </CardContent>
        </Card>

        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardContent className="p-6">
            <div className="flex items-center justify-between mb-2">
              <span className="text-gray-400">Investido</span>
              <PieChart className="h-5 w-5 text-purple-400" />
            </div>
            <div className="text-2xl font-bold text-white">
              {formatCurrency(balance?.holdings_value || 0)}
            </div>
            <p className="text-sm text-gray-500">
              {holdingsPercentage.toFixed(1)}% do portfólio
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-1 gap-6">
        {/* Performance Chart */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <BarChart3 className="h-5 w-5 text-blue-400" />
              Performance (30 dias)
            </CardTitle>
            <CardDescription className="text-gray-400">
              Evolução do valor do portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={performanceData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                  <XAxis 
                    dataKey="date" 
                    stroke="#9CA3AF"
                    fontSize={12}
                  />
                  <YAxis 
                    stroke="#9CA3AF"
                    fontSize={12}
                    tickFormatter={(value) => `€${(value/1000).toFixed(0)}k`}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      backgroundColor: '#1F2937', 
                      border: '1px solid #374151',
                      borderRadius: '8px',
                      color: '#F9FAFB'
                    }}
                    formatter={(value: any) => [formatCurrency(value), 'Valor']}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="value" 
                    stroke="#3B82F6" 
                    strokeWidth={3}
                    dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Portfolio Risk Metrics - Premium Feature */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <Shield className="h-5 w-5 text-blue-400" />
            Métricas de Risco do Portfólio
            <Badge className="bg-yellow-100 text-yellow-800">
              <Crown className="h-3 w-3 mr-1" />
              Premium
            </Badge>
            {isUsingMockRisk && isPremium && (
              <Badge variant="outline" className="border-orange-600 text-orange-400">
                Demo Data
              </Badge>
            )}
          </CardTitle>
          <CardDescription className="text-gray-400">
            Análise de risco avançada baseada na composição do portfólio
          </CardDescription>
        </CardHeader>
        <CardContent>
          {!isPremium ? (
            // Non-premium user view
            <div className="relative">
              <div className="absolute inset-0 bg-gradient-to-br from-gray-900/95 to-gray-800/95 backdrop-blur-sm z-10 rounded-lg flex items-center justify-center">
                <div className="text-center">
                  <div className="bg-gradient-to-r from-yellow-400/20 to-yellow-600/20 rounded-full w-16 h-16 flex items-center justify-center mx-auto mb-4">
                    <Crown className="h-8 w-8 text-yellow-400" />
                  </div>
                  <h3 className="text-xl font-bold text-white mb-2">Premium Feature</h3>
                  <p className="text-gray-300 mb-4 max-w-sm">
                    Desbloqueie métricas avançadas de risco para otimizar seu portfólio
                  </p>
                  <Button asChild className="bg-gradient-to-r from-yellow-600 to-yellow-700 hover:from-yellow-700 hover:to-yellow-800 text-white">
                    <Link href="/dashboard?tab=subscriptions">
                      <Crown className="h-4 w-4 mr-2" />
                      Upgrade
                    </Link>
                  </Button>
                </div>
              </div>
              
              {/* Blurred preview */}
              <div className="opacity-50 blur-sm pointer-events-none">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  {[
                    { label: 'Nível de Risco', value: 'Moderate', icon: Shield },
                    { label: 'Beta', value: '1.42', icon: Activity },
                    { label: 'Sharpe Ratio', value: '0.47', icon: TrendingUp },
                    { label: 'Max Drawdown', value: '-8.5%', icon: TrendingDown }
                  ].map((item, index) => {
                    const Icon = item.icon
                    return (
                      <div key={index} className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                        <div className="flex items-center justify-between mb-2">
                          <span className="text-gray-400 text-sm">{item.label}</span>
                          <Icon className="h-4 w-4 text-blue-400" />
                        </div>
                        <div className="text-white font-bold text-lg">{item.value}</div>
                      </div>
                    )
                  })}
                </div>
              </div>
            </div>
          ) : (
            // Premium user view
            <>
              {riskLoading ? (
                <div className="flex items-center justify-center py-8">
                  <RefreshCw className="h-8 w-8 animate-spin text-blue-400" />
                </div>
              ) : riskMetrics ? (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-gray-400 text-sm">Nível de Risco</span>
                      {getRiskIcon(riskMetrics.risk_level)}
                    </div>
                    <div className={`font-bold text-lg ${getRiskColor(riskMetrics.risk_level)}`}>
                      {riskMetrics.risk_level}
                    </div>
                  </div>

                  <div className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-gray-400 text-sm">Beta</span>
                      <Activity className="h-4 w-4 text-purple-400" />
                    </div>
                    <div className="text-white font-bold text-lg">
                      {riskMetrics.beta.toFixed(2)}
                    </div>
                    <p className="text-gray-500 text-xs">vs. mercado</p>
                  </div>

                  <div className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-gray-400 text-sm">Sharpe Ratio</span>
                      <TrendingUp className="h-4 w-4 text-green-400" />
                    </div>
                    <div className="text-white font-bold text-lg">
                      {riskMetrics.sharpe_ratio.toFixed(2)}
                    </div>
                    <p className="text-gray-500 text-xs">risk-adjusted</p>
                  </div>

                  <div className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-gray-400 text-sm">Max Drawdown</span>
                      <TrendingDown className="h-4 w-4 text-red-400" />
                    </div>
                    <div className="text-white font-bold text-lg">
                      {riskMetrics.maximum_drawdown.toFixed(1)}%
                    </div>
                    <p className="text-gray-500 text-xs">maior perda</p>
                  </div>
                </div>
              ) : (
                <div className="text-center py-8">
                  <AlertCircle className="h-12 w-12 mx-auto mb-2 text-gray-600" />
                  <p className="text-gray-400">Dados de risco não disponíveis</p>
                </div>
              )}
            </>
          )}
        </CardContent>
      </Card>

      {/* Holdings by Type - Enhanced with Allocation Chart */}
      {Object.keys(holdingsByType).length > 0 && (
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Target className="h-5 w-5 text-cyan-400" />
              Distribuição & Alocação de Ativos
            </CardTitle>
            <CardDescription className="text-gray-400">
              Diversificação entre diferentes classes de ativos e distribuição do portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
              {/* Asset Type Distribution */}
              <div>
                <h3 className="text-white font-semibold mb-4">Por Tipo de Ativo</h3>
                <div className="grid grid-cols-1 gap-3">
                  {Object.entries(holdingsByType).map(([type, data]) => (
                    <div key={type} className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <span className="text-2xl">{getAssetTypeIcon(type)}</span>
                          <div>
                            <h4 className={`font-medium ${getAssetTypeColor(type)}`}>
                              {type === 'Stock' ? 'Ações' :
                               type === 'Cryptocurrency' ? 'Cripto' :
                               type === 'Commodity' ? 'Commodities' :
                               type === 'Index' ? 'Índices' : type}
                            </h4>
                            <p className="text-gray-400 text-sm">{data.count} {data.count === 1 ? 'ativo' : 'ativos'}</p>
                          </div>
                        </div>
                        <div className="text-right">
                          <p className="text-white font-bold text-lg">{formatCurrency(data.value)}</p>
                          <p className="text-gray-500 text-sm">
                            {((data.value / totalValue) * 100).toFixed(1)}% do portfólio
                          </p>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Allocation Pie Chart */}
              <div>
                <h3 className="text-white font-semibold mb-4">Alocação Visual</h3>
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <RechartsPieChart>
                      <Pie
                        data={Object.entries(holdingsByType).map(([type, data], index) => ({
                          name: type === 'Stock' ? 'Ações' :
                                type === 'Cryptocurrency' ? 'Cripto' :
                                type === 'Commodity' ? 'Commodities' :
                                type === 'Index' ? 'Índices' : type,
                          value: (data.value / totalValue) * 100,
                          color: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][index % 5]
                        }))}
                        cx="50%"
                        cy="50%"
                        outerRadius={80}
                        dataKey="value"
                      >
                        {Object.entries(holdingsByType).map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][index % 5]} />
                        ))}
                      </Pie>
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: '#1F2937', 
                          border: '1px solid #374151',
                          borderRadius: '8px',
                          color: '#F9FAFB'
                        }}
                        formatter={(value: any) => [`${value.toFixed(1)}%`, 'Percentagem']}
                      />
                    </RechartsPieChart>
                  </ResponsiveContainer>
                </div>
                <div className="grid grid-cols-1 gap-2 mt-4">
                  {Object.entries(holdingsByType).map(([type, data], index) => (
                    <div key={type} className="flex items-center gap-2">
                      <div 
                        className="w-3 h-3 rounded-full" 
                        style={{ backgroundColor: ['#3B82F6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6'][index % 5] }}
                      ></div>
                      <span className="text-gray-300 text-sm">
                        {type === 'Stock' ? 'Ações' :
                         type === 'Cryptocurrency' ? 'Cripto' :
                         type === 'Commodity' ? 'Commodities' :
                         type === 'Index' ? 'Índices' : type}
                      </span>
                      <span className="text-white font-medium text-sm">
                        {((data.value / totalValue) * 100).toFixed(1)}%
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Individual Portfolio Assets */}
      {holdings.length > 0 && (
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Briefcase className="h-5 w-5 text-cyan-400" />
              Assets do Portfólio
            </CardTitle>
            <CardDescription className="text-gray-400">
              Todos os ativos presentes neste portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {holdings.map((holding) => (
                <div key={holding.asset_id} className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50 hover:border-blue-600/50 transition-all">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className="bg-blue-600/20 rounded-lg p-2">
                        <span className="text-lg">
                          {holding.asset_type === 'Stock' ? '📈' :
                           holding.asset_type === 'Cryptocurrency' ? '₿' :
                           holding.asset_type === 'Commodity' ? '🥇' :
                           holding.asset_type === 'Index' ? '📊' : '📋'}
                        </span>
                      </div>
                      <div>
                        <h3 className="text-white font-semibold">{holding.asset_name}</h3>
                        <p className="text-gray-400 text-sm">{holding.symbol}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-white font-bold">{formatCurrency(holding.market_value)}</p>
                      <p className="text-gray-400 text-sm">{holding.quantity_held} shares</p>
                    </div>
                  </div>
                  
                  <div className="grid grid-cols-3 gap-3 pt-3 border-t border-gray-700/50">
                    <div>
                      <p className="text-gray-400 text-xs">Preço</p>
                      <p className="text-white text-sm font-medium">{formatCurrency(holding.current_price)}</p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-xs">Quantidade</p>
                      <p className="text-white text-sm font-medium">{holding.quantity_held}</p>
                    </div>
                    <div>
                      <p className="text-gray-400 text-xs">% Portfolio</p>
                      <p className="text-white text-sm font-medium">
                        {((holding.market_value / (balance?.total_portfolio_value || 1)) * 100).toFixed(1)}%
                      </p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
            
            {/* Quick Action for More Assets */}
            <div className="mt-6 pt-6 border-t border-gray-700/50">
              <div className="text-center">
                <p className="text-gray-400 text-sm mb-4">Quer adicionar mais ativos ao seu portfólio?</p>
                <Button asChild className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800">
                  <Link href="/dashboard?tab=trading">
                    <Plus className="h-4 w-4 mr-2" />
                    Explorar Ativos
                  </Link>
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Portfolio Statistics */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <Activity className="h-5 w-5 text-green-400" />
            Estatísticas do Portfólio
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">
                {summary?.total_trades || 0}
              </div>
              <p className="text-gray-400">Total de Transações</p>
            </div>
            
            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">
                {Math.floor((Date.now() - new Date(portfolio.creation_date).getTime()) / (1000 * 60 * 60 * 24))}
              </div>
              <p className="text-gray-400">Dias Ativos</p>
            </div>

            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">
                {Object.keys(holdingsByType).length}
              </div>
              <p className="text-gray-400">Tipos de Ativos</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Quick Insights */}
      <Card className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 rounded-xl border border-blue-800/30">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <CheckCircle className="h-5 w-5 text-green-400" />
            Insights Rápidos
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {cashPercentage > 50 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-yellow-900/30 border border-yellow-600/30">
                <AlertCircle className="h-5 w-5 text-yellow-400 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-yellow-300 font-medium">Alto valor em dinheiro</p>
                  <p className="text-yellow-200 text-sm">
                    {cashPercentage.toFixed(1)}% do seu portfólio está em dinheiro. Considere investir parte destes fundos.
                  </p>
                </div>
              </div>
            )}
            
            {holdings.length < 3 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-blue-900/30 border border-blue-600/30">
                <CheckCircle className="h-5 w-5 text-blue-400 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-blue-300 font-medium">Diversificação limitada</p>
                  <p className="text-blue-200 text-sm">
                    Considere adicionar mais ativos para melhorar a diversificação do seu portfólio.
                  </p>
                </div>
              </div>
            )}

            {portfolio.current_profit_pct > 10 && (
              <div className="flex items-start gap-3 p-3 rounded-lg bg-green-900/30 border border-green-600/30">
                <TrendingUp className="h-5 w-5 text-green-400 mt-0.5 flex-shrink-0" />
                <div>
                  <p className="text-green-300 font-medium">Excelente performance!</p>
                  <p className="text-green-200 text-sm">
                    O seu portfólio está a ter uma performance muito positiva com {formatPercentage(portfolio.current_profit_pct)} de rentabilidade.
                  </p>
                </div>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 