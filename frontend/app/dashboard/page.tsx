'use client'

import { useEffect, useState } from 'react'
import { useAuth } from '@/contexts/AuthContext'
import { useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  Wallet, 
  TrendingUp, 
  PieChart,
  Crown,
  Eye,
  DollarSign,
  Plus,
  CreditCard,
  AlertTriangle
} from 'lucide-react'
import Link from 'next/link'
import Navbar from '@/components/layout/Navbar'

// Import dashboard components
import OverviewTab from '@/components/dashboard/OverviewTab'
import AddFundsTab from '@/components/dashboard/AddFundsTab'
import PortfoliosTab from '@/components/dashboard/PortfoliosTab'
import TradingTab from '@/components/dashboard/TradingTab'
import PaymentsTab from '@/components/dashboard/PaymentsTab'
import SubscriptionsTab from '@/components/dashboard/SubscriptionsTab'
import RiskAnalysisTab from '@/components/dashboard/RiskAnalysisTab'

// Updated interface to match the complete endpoint response (ExtendedUser)
interface ExtendedUser {
  user_id: string
  name: string
  email: string
  country_of_residence: string
  iban: string
  user_type: string
  account_balance: number
  payment_method_type?: string
  payment_method_details?: string
  payment_method_expiry?: string
  payment_method_active: boolean
  is_premium: boolean
  premium_start_date?: string
  premium_end_date?: string
  monthly_subscription_rate?: number
  auto_renew_subscription: boolean
  last_subscription_payment?: string
  next_subscription_payment?: string
  days_remaining_in_subscription: number
  subscription_expired: boolean
  created_at: string
  updated_at: string
}

export default function DashboardPage() {
  const { user, loading } = useAuth()
  const router = useRouter()
  const [userComplete, setUserComplete] = useState<ExtendedUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('overview')
  
  // Portfolio aggregated data
  const [portfolioStats, setPortfolioStats] = useState({
    totalPortfolios: 0,
    totalPortfolioValue: 0,
    totalCash: 0,
    totalHoldings: 0
  })

  useEffect(() => {
    if (!loading && !user) {
      router.push('/login')
      return
    }

    if (user) {
      fetchCompleteUser()
      fetchPortfolioStats()
    }
  }, [user, loading, router])

  useEffect(() => {
    // Debug log to check userComplete data
    console.log('Dashboard userComplete data:', userComplete)
    console.log('Is premium?', userComplete?.is_premium)
  }, [userComplete])

  const fetchCompleteUser = async () => {
    try {
      setIsLoading(true)
      
      console.log('Attempting to fetch user data for user:', user?.user_id)
      console.log('Full URL:', `http://localhost:8080/api/v1/users/${user?.user_id}/complete`)
      
      if (!user?.user_id) {
        console.error('No user ID available')
        return
      }
      
      // Add a timeout to the fetch request
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 10000) // 10 second timeout
      
      const response = await fetch(`http://localhost:8080/api/v1/users/${user.user_id}/complete`, {
        method: 'GET',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json'
        }
      })
      
      clearTimeout(timeoutId)
      console.log('Response status:', response.status, response.statusText)
      console.log('Response headers:', response.headers)
      
      if (response.ok) {
        const data = await response.json()
        console.log('Fetched user data:', data) // Debug log
        setUserComplete(data)
      } else {
        console.error('Failed to fetch user data:', response.status, response.statusText)
        const errorText = await response.text()
        console.error('Error response:', errorText)
      }
    } catch (error) {
      console.error('Failed to fetch complete user data:', error)
      console.error('Error details:', {
        message: error instanceof Error ? error.message : 'Unknown error',
        name: error instanceof Error ? error.name : 'Unknown',
        stack: error instanceof Error ? error.stack : 'No stack trace'
      })
      
      // Check for specific error types
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          console.error('Request timed out after 10 seconds')
        } else if (error.message.includes('Failed to fetch')) {
          console.error('Network connectivity issue - backend might be unreachable')
        }
      }
    } finally {
      setIsLoading(false)
    }
  }

  const fetchPortfolioStats = async () => {
    try {
      // Fetch portfolios for the user
      const response = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${user?.user_id}`)
      if (response.ok) {
        const portfolios = await response.json()
        
        // Fetch balance for each portfolio to calculate totals
        const portfolioBalances = await Promise.all(
          portfolios.map(async (portfolio: any) => {
            try {
              const balanceResponse = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolio.portfolio_id}/balance`)
              if (balanceResponse.ok) {
                const balance = await balanceResponse.json()
                return balance
              }
              return null
            } catch (error) {
              console.error(`Failed to fetch balance for portfolio ${portfolio.portfolio_id}:`, error)
              return null
            }
          })
        )
        
        // Calculate aggregated stats
        const stats = portfolioBalances.reduce((acc, balance) => {
          if (balance) {
            acc.totalPortfolioValue += balance.total_portfolio_value
            acc.totalCash += balance.cash_balance
            acc.totalHoldings += balance.holdings_value
          }
          return acc
        }, {
          totalPortfolios: portfolios.length,
          totalPortfolioValue: 0,
          totalCash: 0,
          totalHoldings: 0
        })
        
        setPortfolioStats(stats)
      }
    } catch (error) {
      console.error('Failed to fetch portfolio stats:', error)
    }
  }

  const refreshDashboardData = async () => {
    await Promise.all([
      fetchCompleteUser(),
      fetchPortfolioStats()
    ])
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('pt-PT', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  if (loading || isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <p className="text-gray-400 mt-4">A carregar dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex justify-between items-start">
            <div>
              <h1 className="text-3xl font-bold text-white">
                Bem-vindo, {userComplete?.name || user?.name}
              </h1>
              <p className="text-gray-400 mt-1">
                Gestão inteligente do seu portfólio de investimentos
              </p>
              {/* Debug info */}
              <p className="text-gray-500 text-sm mt-1">
                Premium Status: {userComplete?.is_premium ? 'TRUE' : 'FALSE'} | 
                Data Loaded: {userComplete ? 'YES' : 'NO'}
              </p>
            </div>
            <div className="flex items-center gap-3">
              {userComplete?.is_premium ? (
                <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
                  <Crown className="h-4 w-4 mr-1" />
                  Premium
                </Badge>
              ) : (
                <Badge variant="outline" className="border-gray-600 text-gray-300">
                  Básico
                </Badge>
              )}
              <Button 
                onClick={refreshDashboardData}
                size="sm" 
                variant="outline"
                className="border-gray-600 text-gray-300 hover:bg-gray-600"
              >
                🔄 Refresh
              </Button>
              <Button asChild size="sm" className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800">
                <Link href="/portfolios/create">
                  <Plus className="h-4 w-4 mr-2" />
                  Criar Portfólio
                </Link>
              </Button>
            </div>
          </div>
        </div>

        {/* Financial Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Saldo da Conta</CardTitle>
              <Wallet className="h-5 w-5 text-blue-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">
                {formatCurrency(userComplete?.account_balance || 0)}
              </div>
              <p className="text-xs text-gray-400 mt-1">
                Disponível para investimento
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Valor dos Portfólios</CardTitle>
              <PieChart className="h-5 w-5 text-green-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">
                {formatCurrency(portfolioStats.totalPortfolioValue)}
              </div>
              <p className="text-xs text-gray-400 mt-1">
                {portfolioStats.totalPortfolios} {portfolioStats.totalPortfolios === 1 ? 'portfólio ativo' : 'portfólios ativos'}
              </p>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium text-gray-300">Património Líquido</CardTitle>
              <TrendingUp className="h-5 w-5 text-purple-400" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold text-white">
                {formatCurrency((userComplete?.account_balance || 0) + portfolioStats.totalPortfolioValue)}
              </div>
              <p className="text-xs text-gray-400 mt-1">
                Conta + Portfólios
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Main Content with Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="bg-gray-800/60 backdrop-blur-sm border border-gray-700">
            <TabsTrigger value="overview" className="text-gray-300 data-[state=active]:text-white">
              <Eye className="h-4 w-4 mr-2" />
              Visão Geral
            </TabsTrigger>
            <TabsTrigger value="funds" className="text-gray-300 data-[state=active]:text-white">
              <DollarSign className="h-4 w-4 mr-2" />
              Adicionar Fundos
            </TabsTrigger>
            <TabsTrigger value="portfolios" className="text-gray-300 data-[state=active]:text-white">
              <PieChart className="h-4 w-4 mr-2" />
              Portfólios
            </TabsTrigger>
            <TabsTrigger value="trading" className="text-gray-300 data-[state=active]:text-white">
              <TrendingUp className="h-4 w-4 mr-2" />
              Trading
            </TabsTrigger>
            <TabsTrigger value="payments" className="text-gray-300 data-[state=active]:text-white">
              <CreditCard className="h-4 w-4 mr-2" />
              Pagamentos
            </TabsTrigger>
            <TabsTrigger value="subscriptions" className="text-gray-300 data-[state=active]:text-white">
              <Crown className="h-4 w-4 mr-2" />
              Subscrições
            </TabsTrigger>
            {userComplete?.is_premium && (
              <TabsTrigger value="risk" className="text-gray-300 data-[state=active]:text-white">
                <AlertTriangle className="h-4 w-4 mr-2" />
                Análise de Risco
              </TabsTrigger>
            )}
          </TabsList>

          {/* Tab Contents */}
          <TabsContent value="overview">
            <OverviewTab 
              userComplete={userComplete} 
              onRefresh={refreshDashboardData}
              formatCurrency={formatCurrency}
            />
          </TabsContent>

          <TabsContent value="funds">
            <AddFundsTab 
              userId={user?.user_id}
              currentBalance={userComplete?.account_balance || 0}
              onRefresh={refreshDashboardData}
              formatCurrency={formatCurrency}
            />
          </TabsContent>

          <TabsContent value="portfolios">
            <PortfoliosTab 
              userId={user?.user_id}
              formatCurrency={formatCurrency}
              onRefresh={refreshDashboardData}
            />
          </TabsContent>

          <TabsContent value="trading">
            <TradingTab 
              userId={user?.user_id}
              formatCurrency={formatCurrency}
              onRefresh={refreshDashboardData}
            />
          </TabsContent>

          <TabsContent value="payments">
            <PaymentsTab 
              userId={user?.user_id}
              userComplete={userComplete}
              onRefresh={refreshDashboardData}
            />
          </TabsContent>

          <TabsContent value="subscriptions">
            <SubscriptionsTab 
              userComplete={userComplete}
              onRefresh={refreshDashboardData}
              formatCurrency={formatCurrency}
            />
          </TabsContent>

          {userComplete?.is_premium && (
            <TabsContent value="risk">
              <RiskAnalysisTab 
                userId={user?.user_id}
                formatCurrency={formatCurrency}
              />
            </TabsContent>
          )}
        </Tabs>

        {/* Premium Upgrade CTA - Only show if not premium */}
        {!userComplete?.is_premium && (
          <Card className="mt-8 bg-gradient-to-r from-yellow-900/40 to-orange-900/40 border-yellow-600/40">
            <CardHeader>
              <div className="flex items-center">
                <Crown className="h-6 w-6 text-yellow-400 mr-2" />
                <CardTitle className="text-yellow-300">Upgrade para Premium</CardTitle>
              </div>
              <CardDescription className="text-yellow-400/80">
                Desbloqueie análise de risco avançada, relatórios detalhados e muito mais
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button 
                onClick={() => setActiveTab('subscriptions')}
                className="bg-gradient-to-r from-yellow-600 to-yellow-700 hover:from-yellow-700 hover:to-yellow-800"
              >
                <Crown className="h-4 w-4 mr-2" />
                Upgrade Agora - €50.00/mês
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </div>
  )
}