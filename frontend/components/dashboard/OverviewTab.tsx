'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { 
  Wallet, 
  TrendingUp, 
  TrendingDown, 
  PieChart,
  Crown,
  Eye,
  Activity,
  History,
  Calendar,
  MapPin,
  User,
  CreditCard,
  Shield
} from 'lucide-react'
import Link from 'next/link'

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

interface PortfolioStats {
  totalPortfolios: number
  totalPortfolioValue: number
  totalCash: number
  totalHoldings: number
  averageProfit: number
}

interface OverviewTabProps {
  userComplete: ExtendedUser | null
  onRefresh: () => void
  formatCurrency: (amount: number) => string
}

export default function OverviewTab({ userComplete, onRefresh, formatCurrency }: OverviewTabProps) {
  const [portfolioStats, setPortfolioStats] = useState<PortfolioStats>({
    totalPortfolios: 0,
    totalPortfolioValue: 0,
    totalCash: 0,
    totalHoldings: 0,
    averageProfit: 0
  })
  const [isLoadingPortfolios, setIsLoadingPortfolios] = useState(true)

  useEffect(() => {
    if (userComplete?.user_id) {
      fetchPortfolioStats()
    }
  }, [userComplete?.user_id])

  const fetchPortfolioStats = async () => {
    try {
      setIsLoadingPortfolios(true)
      
      // Fetch portfolios for the user
      const response = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${userComplete?.user_id}`)
      if (response.ok) {
        const portfolios: Portfolio[] = await response.json()
        
        // Fetch balance for each portfolio to calculate totals
        const portfolioBalances = await Promise.all(
          portfolios.map(async (portfolio) => {
            try {
              const balanceResponse = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolio.portfolio_id}/balance`)
              if (balanceResponse.ok) {
                const balance: PortfolioBalance = await balanceResponse.json()
                return { portfolio, balance }
              }
              return { portfolio, balance: null }
            } catch (error) {
              console.error(`Failed to fetch balance for portfolio ${portfolio.portfolio_id}:`, error)
              return { portfolio, balance: null }
            }
          })
        )
        
        // Calculate aggregated stats
        const stats = portfolioBalances.reduce((acc, { portfolio, balance }) => {
          if (balance) {
            acc.totalPortfolioValue += balance.total_portfolio_value
            acc.totalCash += balance.cash_balance
            acc.totalHoldings += balance.holdings_value
          }
          acc.averageProfit += portfolio.current_profit_pct
          return acc
        }, {
          totalPortfolios: portfolios.length,
          totalPortfolioValue: 0,
          totalCash: 0,
          totalHoldings: 0,
          averageProfit: 0
        })
        
        // Calculate average profit
        if (portfolios.length > 0) {
          stats.averageProfit = stats.averageProfit / portfolios.length
        }
        
        setPortfolioStats(stats)
      }
    } catch (error) {
      console.error('Failed to fetch portfolio stats:', error)
    } finally {
      setIsLoadingPortfolios(false)
    }
  }

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleDateString('pt-PT')
  }

  const formatDateTime = (dateString?: string) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleString('pt-PT')
  }

  if (!userComplete) {
    return (
      <div className="text-center py-8">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
        <p className="text-gray-400 mt-4">A carregar dados...</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Account Information */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <User className="h-5 w-5 mr-2" />
            Informações da Conta
          </CardTitle>
          <CardDescription className="text-gray-400">
            Detalhes da sua conta e perfil
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div className="space-y-2">
              <p className="text-sm text-gray-400">Nome</p>
              <p className="text-white font-medium">{userComplete.name}</p>
            </div>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">Email</p>
              <p className="text-white font-medium">{userComplete.email}</p>
            </div>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">País de Residência</p>
              <div className="flex items-center">
                <MapPin className="h-4 w-4 text-gray-400 mr-2" />
                <p className="text-white font-medium">{userComplete.country_of_residence}</p>
              </div>
            </div>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">Tipo de Utilizador</p>
              <Badge variant={userComplete.is_premium ? "secondary" : "outline"} 
                className={userComplete.is_premium ? "bg-yellow-100 text-yellow-800" : "border-gray-600 text-gray-300"}>
                {userComplete.is_premium ? (
                  <>
                    <Crown className="h-4 w-4 mr-1" />
                    Premium
                  </>
                ) : (
                  'Básico'
                )}
              </Badge>
            </div>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">Conta criada em</p>
              <div className="flex items-center">
                <Calendar className="h-4 w-4 text-gray-400 mr-2" />
                <p className="text-white font-medium">{formatDate(userComplete.created_at)}</p>
              </div>
            </div>
            <div className="space-y-2">
              <p className="text-sm text-gray-400">Última atualização</p>
              <div className="flex items-center">
                <Activity className="h-4 w-4 text-gray-400 mr-2" />
                <p className="text-white font-medium">{formatDateTime(userComplete.updated_at)}</p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Financial Overview */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Account Balance */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Wallet className="h-5 w-5 mr-2" />
              Saldo da Conta
            </CardTitle>
            <CardDescription className="text-gray-400">
              Fundos disponíveis para investimento
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="text-center py-6">
              <div className="text-4xl font-bold text-white mb-2">
                {formatCurrency(userComplete.account_balance)}
              </div>
              <p className="text-gray-400">Disponível para investimento</p>
            </div>
          </CardContent>
        </Card>

        {/* Portfolio Overview */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <PieChart className="h-5 w-5 mr-2" />
              Portfólios
            </CardTitle>
            <CardDescription className="text-gray-400">
              Resumo dos seus investimentos
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {isLoadingPortfolios ? (
              <div className="text-center py-6">
                <div className="inline-block animate-spin rounded-full h-6 w-6 border-b-2 border-blue-400"></div>
                <p className="text-gray-400 mt-2">A carregar portfólios...</p>
              </div>
            ) : (
              <div className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div className="text-center">
                    <div className="text-2xl font-bold text-white">{portfolioStats.totalPortfolios}</div>
                    <p className="text-gray-400 text-sm">Portfólios</p>
                  </div>
                  <div className="text-center">
                    <div className="text-2xl font-bold text-green-400">{formatCurrency(portfolioStats.totalPortfolioValue)}</div>
                    <p className="text-gray-400 text-sm">Valor Total</p>
                  </div>
                </div>
                
                {portfolioStats.totalPortfolios === 0 ? (
                  <div className="text-center py-4">
                    <Button asChild className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800">
                      <Link href="/portfolios/create">
                        <PieChart className="h-4 w-4 mr-2" />
                        Criar Primeiro Portfólio
                      </Link>
                    </Button>
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">Dinheiro:</span>
                      <span className="text-blue-300">{formatCurrency(portfolioStats.totalCash)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">Holdings:</span>
                      <span className="text-green-300">{formatCurrency(portfolioStats.totalHoldings)}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-400">Performance Média:</span>
                      <span className={`flex items-center ${portfolioStats.averageProfit >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                        {portfolioStats.averageProfit >= 0 ? (
                          <TrendingUp className="h-3 w-3 mr-1" />
                        ) : (
                          <TrendingDown className="h-3 w-3 mr-1" />
                        )}
                        {portfolioStats.averageProfit.toFixed(2)}%
                      </span>
                    </div>
                  </div>
                )}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Payment & Subscription Status */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Payment Method Status */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <CreditCard className="h-5 w-5 mr-2" />
              Método de Pagamento
            </CardTitle>
            <CardDescription className="text-gray-400">
              Estado do seu método de pagamento
            </CardDescription>
          </CardHeader>
          <CardContent>
            {userComplete.payment_method_active && userComplete.payment_method_type ? (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Tipo</span>
                  <span className="text-white font-medium">{userComplete.payment_method_type}</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Detalhes</span>
                  <span className="text-white font-medium">{userComplete.payment_method_details}</span>
                </div>
                {userComplete.payment_method_expiry && (
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Validade</span>
                    <span className="text-white font-medium">{formatDate(userComplete.payment_method_expiry)}</span>
                  </div>
                )}
                <Badge className="bg-green-100 text-green-800 mt-2">
                  <Shield className="h-4 w-4 mr-1" />
                  Ativo
                </Badge>
              </div>
            ) : (
              <div className="text-center py-6">
                <CreditCard className="h-12 w-12 mx-auto mb-4 text-gray-500" />
                <p className="text-gray-400 mb-4">Nenhum método de pagamento configurado</p>
                <Badge variant="outline" className="border-gray-600 text-gray-400">
                  Não configurado
                </Badge>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Subscription Status */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Crown className="h-5 w-5 mr-2" />
              Estado da Subscrição
            </CardTitle>
            <CardDescription className="text-gray-400">
              Detalhes da sua subscrição premium
            </CardDescription>
          </CardHeader>
          <CardContent>
            {userComplete.is_premium ? (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Plano</span>
                  <Badge className="bg-yellow-100 text-yellow-800">
                    <Crown className="h-4 w-4 mr-1" />
                    Premium
                  </Badge>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Valor Mensal</span>
                  <span className="text-white font-medium">
                    {formatCurrency(userComplete.monthly_subscription_rate || 50)}
                  </span>
                </div>
                {userComplete.premium_end_date && (
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Renova em</span>
                    <span className="text-white font-medium">{formatDate(userComplete.premium_end_date)}</span>
                  </div>
                )}
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Dias restantes</span>
                  <span className="text-white font-medium">{userComplete.days_remaining_in_subscription} dias</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="text-gray-300">Renovação automática</span>
                  <Badge variant={userComplete.auto_renew_subscription ? "secondary" : "outline"}>
                    {userComplete.auto_renew_subscription ? 'Ativa' : 'Inativa'}
                  </Badge>
                </div>
              </div>
            ) : (
              <div className="text-center py-6">
                <Crown className="h-12 w-12 mx-auto mb-4 text-gray-500" />
                <p className="text-gray-400 mb-4">Plano básico ativo</p>
                <Badge variant="outline" className="border-gray-600 text-gray-400">
                  Básico - Gratuito
                </Badge>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Recent Activity */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <History className="h-5 w-5 mr-2" />
            Atividade Recente
          </CardTitle>
          <CardDescription className="text-gray-400">
            Últimas movimentações na sua conta
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {userComplete.last_subscription_payment && (
              <div className="flex items-center justify-between p-3 rounded-lg border border-gray-700 bg-gray-800/40">
                <div className="flex items-center">
                  <Crown className="h-4 w-4 text-yellow-400 mr-3" />
                  <span className="text-white">Último pagamento de subscrição</span>
                </div>
                <span className="text-gray-400">{formatDateTime(userComplete.last_subscription_payment)}</span>
              </div>
            )}
            {!userComplete.last_subscription_payment && (
              <div className="text-center py-6 text-gray-400">
                <Activity className="h-12 w-12 mx-auto mb-4 opacity-50" />
                <p>Nenhuma atividade recente</p>
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 