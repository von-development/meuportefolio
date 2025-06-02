'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { 
  ArrowLeft,
  Edit,
  Trash2,
  Wallet,
  TrendingUp,
  TrendingDown,
  PieChart,
  BarChart3,
  Calendar,
  AlertCircle,
  CheckCircle,
  Plus,
  Eye,
  DollarSign,
  Shield,
  Zap,
  Settings,
  RefreshCw,
  Search,
  ArrowDownCircle,
  X
} from 'lucide-react'
import Link from 'next/link'
import Navbar from '@/components/layout/Navbar'
import PortfolioOverview from '@/components/portfolio/PortfolioOverview'
import RiskAnalysisSection from '@/components/portfolio/RiskAnalysisSection'
import QuickActionsSection from '@/components/portfolio/QuickActionsSection'
import { toast } from 'sonner'
import { useAuth } from '@/contexts/AuthContext'

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

export default function PortfolioDetailsPage() {
  const { user } = useAuth()
  const params = useParams()
  const router = useRouter()
  const portfolioId = params.portfolio_id as string
  
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null)
  const [balance, setBalance] = useState<PortfolioBalance | null>(null)
  const [summary, setSummary] = useState<PortfolioSummary | null>(null)
  const [holdings, setHoldings] = useState<AssetHolding[]>([])
  const [userComplete, setUserComplete] = useState<ExtendedUser | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('overview')
  
  // Edit state
  const [isEditing, setIsEditing] = useState(false)
  const [editName, setEditName] = useState('')
  const [editError, setEditError] = useState('')
  const [editSuccess, setEditSuccess] = useState('')
  
  // Delete state
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState('')

  // Buy/Sell Modal states
  const [showBuyModal, setShowBuyModal] = useState(false)
  const [showSellModal, setShowSellModal] = useState(false)
  const [showDeallocateModal, setShowDeallocateModal] = useState(false)
  const [deallocateAmount, setDeallocateAmount] = useState('')
  const [isDeallocating, setIsDeallocating] = useState(false)
  const [selectedAsset, setSelectedAsset] = useState<AssetHolding | null>(null)
  const [tradeQuantity, setTradeQuantity] = useState('')
  const [isTrading, setIsTrading] = useState(false)

  useEffect(() => {
    if (portfolioId && user) {
      fetchAllData()
    }
  }, [portfolioId, user])

  const fetchAllData = async () => {
    try {
      setIsLoading(true)
      
      // Fetch all data in parallel
      const [portfolioRes, balanceRes, summaryRes, holdingsRes, userRes] = await Promise.all([
        fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}`),
        fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}/balance`),
        fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}/summary`),
        fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}/holdings`),
        fetch(`http://localhost:8080/api/v1/users/${user?.user_id}/complete`)
      ])
      
      if (portfolioRes.ok) {
        const portfolioData = await portfolioRes.json()
        setPortfolio(portfolioData)
        setEditName(portfolioData.name)
      }
      
      if (balanceRes.ok) {
        const balanceData = await balanceRes.json()
        setBalance(balanceData)
      }
      
      if (summaryRes.ok) {
        const summaryData = await summaryRes.json()
        setSummary(summaryData)
      }
      
      if (holdingsRes.ok) {
        const holdingsData = await holdingsRes.json()
        setHoldings(holdingsData)
      }

      if (userRes.ok) {
        const userData = await userRes.json()
        setUserComplete(userData)
      }
      
    } catch (error) {
      console.error('Failed to fetch portfolio data:', error)
      toast.error('Erro ao carregar dados do portfólio')
    } finally {
      setIsLoading(false)
    }
  }

  const handleUpdatePortfolio = async () => {
    if (!editName.trim()) {
      setEditError('Nome do portfólio é obrigatório')
      return
    }

    try {
      const response = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: editName
        }),
      })

      if (response.ok) {
        const updatedPortfolio = await response.json()
        setPortfolio(updatedPortfolio)
        toast.success('Portfólio atualizado com sucesso!')
        setIsEditing(false)
        setEditError('')
      } else {
        const errorData = await response.text()
        setEditError(`Erro ao atualizar portfólio: ${errorData}`)
      }
    } catch (error) {
      console.error('Update failed:', error)
      setEditError('Erro de conexão. Tente novamente.')
    }
  }

  const handleDeletePortfolio = async () => {
    try {
      setIsDeleting(true)
      setDeleteError('')

      const response = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}`, {
        method: 'DELETE',
      })

      if (response.ok) {
        toast.success('Portfólio eliminado com sucesso!')
        router.push('/dashboard?tab=portfolios')
      } else {
        const errorData = await response.text()
        setDeleteError(`Erro ao eliminar portfólio: ${errorData}`)
      }
    } catch (error) {
      console.error('Delete failed:', error)
      setDeleteError('Erro de conexão. Tente novamente.')
    } finally {
      setIsDeleting(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('pt-PT', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-PT')
  }

  const formatPercentage = (percentage: number) => {
    return `${percentage >= 0 ? '+' : ''}${percentage.toFixed(2)}%`
  }

  const handleBuyAsset = (asset: AssetHolding) => {
    setSelectedAsset(asset)
    setTradeQuantity('')
    setShowBuyModal(true)
  }

  const handleSellAsset = (asset: AssetHolding) => {
    setSelectedAsset(asset)
    setTradeQuantity('')
    setShowSellModal(true)
  }

  const executeBuyTrade = async () => {
    if (!selectedAsset || !tradeQuantity) {
      toast.error('Por favor insira uma quantidade válida')
      return
    }

    const quantity = parseFloat(tradeQuantity)
    if (quantity <= 0) {
      toast.error('Quantidade deve ser maior que zero')
      return
    }

    const totalCost = quantity * selectedAsset.current_price
    if (totalCost > (portfolio?.current_funds || 0)) {
      toast.error('Fundos insuficientes para esta compra')
      return
    }

    const buyRequest = {
      portfolio_id: parseInt(portfolioId),
      asset_id: selectedAsset.asset_id,
      quantity: quantity,
      unit_price: selectedAsset.current_price
    }

    try {
      setIsTrading(true)
      const response = await fetch('http://localhost:8080/api/v1/portfolios/buy', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(buyRequest),
      })

      if (response.ok) {
        const result = await response.json()
        toast.success(`✅ Compra realizada! ${result.quantity_purchased} ${selectedAsset.symbol} por ${formatCurrency(result.total_cost)}`)
        setShowBuyModal(false)
        setTradeQuantity('')
        fetchAllData() // Refresh data
      } else {
        const error = await response.text()
        toast.error(`❌ Falha na compra: ${error}`)
      }
    } catch (error) {
      console.error('Buy asset error:', error)
      toast.error('❌ Erro ao executar compra')
    } finally {
      setIsTrading(false)
    }
  }

  const executeSellTrade = async () => {
    if (!selectedAsset || !tradeQuantity) {
      toast.error('Por favor insira uma quantidade válida')
      return
    }

    const quantity = parseFloat(tradeQuantity)
    if (quantity <= 0) {
      toast.error('Quantidade deve ser maior que zero')
      return
    }

    if (quantity > selectedAsset.quantity_held) {
      toast.error('Quantidade superior às suas holdings')
      return
    }

    const sellRequest = {
      portfolio_id: parseInt(portfolioId),
      asset_id: selectedAsset.asset_id,
      quantity: quantity,
      unit_price: selectedAsset.current_price
    }

    try {
      setIsTrading(true)
      const response = await fetch('http://localhost:8080/api/v1/portfolios/sell', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(sellRequest),
      })

      if (response.ok) {
        const result = await response.json()
        toast.success(`✅ Venda realizada! ${result.quantity_sold} ${selectedAsset.symbol} por ${formatCurrency(result.total_proceeds)}`)
        setShowSellModal(false)
        setTradeQuantity('')
        fetchAllData() // Refresh data
      } else {
        const error = await response.text()
        toast.error(`❌ Falha na venda: ${error}`)
      }
    } catch (error) {
      console.error('Sell asset error:', error)
      toast.error('❌ Erro ao executar venda')
    } finally {
      setIsTrading(false)
    }
  }

  const handleDeallocateFunds = async () => {
    if (!deallocateAmount || parseFloat(deallocateAmount) <= 0) {
      toast.error('Por favor insira um valor válido')
      return
    }

    if (!portfolio || parseFloat(deallocateAmount) > portfolio.current_funds) {
      toast.error('Fundos insuficientes no portfólio')
      return
    }

    setIsDeallocating(true)
    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${user?.user_id}/deallocate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          amount: parseFloat(deallocateAmount),
          portfolio_id: parseInt(portfolioId)
        })
      })

      if (response.ok) {
        const result = await response.json()
        setShowDeallocateModal(false)
        setDeallocateAmount('')
        
        toast.success(`${formatCurrency(result.amount)} desalocado com sucesso! Novo saldo da conta: ${formatCurrency(result.new_balance)}`)
        
        // Add delay to let user see the success message before refreshing
        setTimeout(async () => {
          await fetchAllData()
        }, 2000) // 2 second delay
      } else {
        const errorData = await response.text()
        toast.error(`Erro ao desalocar fundos: ${errorData}`)
      }
    } catch (error) {
      console.error('Deallocation failed:', error)
      toast.error('Erro de conexão durante a desalocação')
    } finally {
      setIsDeallocating(false)
    }
  }

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <div className="text-center">
            <RefreshCw className="h-12 w-12 animate-spin text-blue-400 mx-auto" />
            <p className="text-gray-400 mt-4 text-lg">A carregar portfólio...</p>
          </div>
        </div>
      </div>
    )
  }

  if (!portfolio) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
        <Navbar />
        <div className="flex items-center justify-center py-32">
          <div className="text-center">
            <AlertCircle className="h-12 w-12 text-red-400 mx-auto mb-4" />
            <h1 className="text-2xl font-bold text-white mb-2">Portfólio não encontrado</h1>
            <p className="text-gray-400 mb-8">O portfólio solicitado não existe ou não tem acesso.</p>
            <Button asChild className="bg-blue-600 hover:bg-blue-700">
              <Link href="/dashboard?tab=portfolios">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Voltar aos Portfólios
              </Link>
            </Button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      <Navbar />
      
      <div className="max-w-7xl mx-auto px-6 py-8">
        {/* Header with Back Button and Actions */}
        <div className="flex items-center justify-between mb-8">
            <div className="flex items-center gap-4">
            <Button asChild variant="outline" size="sm" className="border-gray-600 text-gray-300">
                <Link href="/dashboard?tab=portfolios">
                  <ArrowLeft className="h-4 w-4 mr-2" />
                  Voltar
                </Link>
              </Button>
              <div>
                  <h1 className="text-3xl font-bold text-white">{portfolio.name}</h1>
              <p className="text-gray-400">
                {formatCurrency(balance?.total_portfolio_value || portfolio.current_funds)} • 
                <span className={`ml-2 ${portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                  {formatPercentage(portfolio.current_profit_pct)}
                </span>
                </p>
              </div>
            </div>

            <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsEditing(true)}
              className="border-gray-600 text-gray-300 hover:bg-gray-600"
            >
                  <Edit className="h-4 w-4 mr-2" />
                  Editar
                </Button>
              <Button 
              variant="outline"
                size="sm" 
                onClick={() => setShowDeleteConfirm(true)}
              className="border-red-600 text-red-400 hover:bg-red-600/20"
              >
                <Trash2 className="h-4 w-4 mr-2" />
                Eliminar
              </Button>
            </div>
        </div>

        {/* Main Content Tabs */}
        <Tabs value={activeTab} onValueChange={setActiveTab} className="space-y-6">
          <TabsList className="bg-gray-800/60 backdrop-blur-sm border border-gray-700 w-full justify-start">
            <TabsTrigger value="overview" className="text-gray-300 data-[state=active]:bg-blue-600 data-[state=active]:text-white hover:bg-gray-700">
              <BarChart3 className="h-4 w-4 mr-2" />
              Visão Geral
            </TabsTrigger>
            <TabsTrigger value="holdings" className="text-gray-300 data-[state=active]:bg-blue-600 data-[state=active]:text-white hover:bg-gray-700">
              <PieChart className="h-4 w-4 mr-2" />
              Assets & Trading
            </TabsTrigger>
            <TabsTrigger value="risk" className="text-gray-300 data-[state=active]:bg-blue-600 data-[state=active]:text-white hover:bg-gray-700">
              <Shield className="h-4 w-4 mr-2" />
              Análise de Risco
              {userComplete?.is_premium && (
                <Badge className="ml-2 bg-yellow-100 text-yellow-800 text-xs">Premium</Badge>
              )}
            </TabsTrigger>
            <TabsTrigger value="settings" className="text-gray-300 data-[state=active]:bg-blue-600 data-[state=active]:text-white hover:bg-gray-700">
              <Settings className="h-4 w-4 mr-2" />
              Configurações
            </TabsTrigger>
          </TabsList>

          <TabsContent value="overview" className="space-y-6">
            <PortfolioOverview
              portfolio={portfolio}
              balance={balance}
              summary={summary}
              holdings={holdings}
              userComplete={userComplete}
              formatCurrency={formatCurrency}
              formatDate={formatDate}
              formatPercentage={formatPercentage}
            />
          </TabsContent>

          <TabsContent value="holdings" className="space-y-6">
            {/* Quick Actions Section */}
            <QuickActionsSection
              portfolioId={portfolioId}
              portfolioName={portfolio.name}
              currentFunds={portfolio.current_funds}
              formatCurrency={formatCurrency}
              onRefresh={fetchAllData}
              userId={user?.user_id || ''}
            />

            {/* Holdings Management */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <PieChart className="h-5 w-5 text-purple-400" />
                  Gestão de Ativos
                </CardTitle>
                <CardDescription className="text-gray-400">
                  Gerir e negociar os seus ativos do portfólio {portfolio.name}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {holdings.length === 0 ? (
                  <div className="text-center py-12">
                    <PieChart className="h-16 w-16 mx-auto mb-4 text-gray-600" />
                    <h3 className="text-xl font-semibold text-white mb-2">Nenhum ativo</h3>
                    <p className="text-gray-400 mb-6">Este portfólio ainda não tem ativos.</p>
                    <div className="flex gap-3">
                      <Button 
                        onClick={() => router.push('/ativos')}
                        className="bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white"
                      >
                        <Search className="h-4 w-4 mr-2" />
                        Explorar Mais Ativos
                      </Button>
                      
                      <Button 
                        onClick={() => setShowDeallocateModal(true)}
                        variant="outline"
                        className="bg-orange-900/30 border-orange-600/50 text-orange-200 hover:bg-orange-800/40 hover:border-orange-500 hover:text-white backdrop-blur-sm"
                      >
                        <ArrowDownCircle className="h-4 w-4 mr-2" />
                        Retirar Fundos
                      </Button>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {holdings.map((holding) => (
                      <div key={holding.asset_id} className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-6 border border-gray-700/50">
                        <div className="flex items-center justify-between mb-4">
                          <div className="flex items-center gap-4">
                            <div className="bg-blue-600/20 rounded-lg p-3">
                              <span className="text-2xl">
                                {holding.asset_type === 'Stock' ? '📈' :
                                 holding.asset_type === 'Cryptocurrency' ? '₿' :
                                 holding.asset_type === 'Commodity' ? '🥇' :
                                 holding.asset_type === 'Index' ? '📊' : '📋'}
                              </span>
                            </div>
                          <div>
                              <h3 className="text-xl font-semibold text-white">{holding.asset_name}</h3>
                              <p className="text-gray-400">{holding.symbol} • {holding.asset_type}</p>
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="text-2xl font-bold text-white">{formatCurrency(holding.market_value)}</p>
                            <p className="text-gray-400">{holding.quantity_held} shares</p>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
                          <div className="bg-gray-800/30 rounded-lg p-3">
                            <p className="text-gray-400 text-sm">Preço Atual</p>
                            <p className="text-white font-medium text-lg">{formatCurrency(holding.current_price)}</p>
                          </div>
                          <div className="bg-gray-800/30 rounded-lg p-3">
                            <p className="text-gray-400 text-sm">Quantidade</p>
                            <p className="text-white font-medium text-lg">{holding.quantity_held}</p>
                          </div>
                          <div className="bg-gray-800/30 rounded-lg p-3">
                            <p className="text-gray-400 text-sm">Valor Total</p>
                            <p className="text-white font-medium text-lg">{formatCurrency(holding.market_value)}</p>
                          </div>
                          <div className="bg-gray-800/30 rounded-lg p-3">
                            <p className="text-gray-400 text-sm">% do Portfólio</p>
                            <p className="text-white font-medium text-lg">
                              {((holding.market_value / (balance?.total_portfolio_value || 1)) * 100).toFixed(1)}%
                            </p>
                          </div>
                        </div>

                        {/* Action Buttons */}
                        <div className="flex items-center gap-3 pt-4 border-t border-gray-700/50">
                          <Button 
                            size="sm" 
                            className="bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800"
                            onClick={() => handleBuyAsset(holding)}
                          >
                            <Plus className="h-4 w-4 mr-2" />
                            Comprar Mais
                          </Button>
                          <Button 
                            size="sm" 
                            className="bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white"
                            onClick={() => handleSellAsset(holding)}
                          >
                            <DollarSign className="h-4 w-4 mr-2" />
                            Vender
                          </Button>
                          <Button 
                            size="sm" 
                            className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white"
                            asChild
                          >
                            <Link href={`/assets/${holding.symbol}`}>
                              <Eye className="h-4 w-4 mr-2" />
                              Detalhes
                            </Link>
                          </Button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </CardContent>
            </Card>
          </TabsContent>

          <TabsContent value="risk" className="space-y-6">
            <RiskAnalysisSection
              portfolioId={portfolioId}
              userId={user?.user_id || ''}
              isPremium={userComplete?.is_premium || false}
              formatCurrency={formatCurrency}
            />
          </TabsContent>

          <TabsContent value="settings" className="space-y-6">
            {/* Portfolio Settings */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Settings className="h-5 w-5 text-gray-400" />
                  Configurações do Portfólio
                </CardTitle>
                <CardDescription className="text-gray-400">
                  Gerir definições e preferências do portfólio
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                {/* Edit Portfolio Name */}
                <div>
                  <Label htmlFor="portfolio-name" className="text-gray-300">Nome do Portfólio</Label>
                  <div className="flex gap-2 mt-2">
                    <Input
                      id="portfolio-name"
                      value={editName}
                      onChange={(e) => setEditName(e.target.value)}
                      className="bg-gray-700/50 border-gray-600 text-white"
                      disabled={!isEditing}
                    />
                    {isEditing ? (
                      <div className="flex gap-2">
                        <Button onClick={handleUpdatePortfolio} size="sm" className="bg-green-600 hover:bg-green-700">
                          <CheckCircle className="h-4 w-4" />
                        </Button>
                        <Button onClick={() => setIsEditing(false)} variant="outline" size="sm" className="border-gray-600">
                          <AlertCircle className="h-4 w-4" />
                        </Button>
                      </div>
                    ) : (
                      <Button onClick={() => setIsEditing(true)} variant="outline" size="sm" className="border-gray-600">
                        <Edit className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                  {editError && <p className="text-red-400 text-sm mt-1">{editError}</p>}
                </div>

                {/* Portfolio Information */}
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-6 border-t border-gray-700">
                  <div>
                    <p className="text-gray-400 text-sm">Data de Criação</p>
                    <p className="text-white font-medium">{formatDate(portfolio.creation_date)}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Última Atualização</p>
                    <p className="text-white font-medium">{formatDate(portfolio.last_updated)}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Total de Transações</p>
                    <p className="text-white font-medium">{summary?.total_trades || 0}</p>
                  </div>
                  <div>
                    <p className="text-gray-400 text-sm">Número de Ativos</p>
                    <p className="text-white font-medium">{holdings.length}</p>
                  </div>
                </div>

                {/* Danger Zone */}
                <div className="pt-6 border-t border-red-800/30">
                  <h3 className="text-red-400 font-semibold mb-4 flex items-center gap-2">
                    <AlertCircle className="h-5 w-5" />
                    Zona de Perigo
                  </h3>
                  <div className="bg-red-900/20 border border-red-800/40 rounded-lg p-4">
                    <p className="text-red-300 text-sm mb-4">
                      Eliminar este portfólio irá remover permanentemente todos os dados associados. Esta ação não pode ser desfeita.
                    </p>
                    <Button
                      onClick={() => setShowDeleteConfirm(true)}
                      variant="destructive"
                      size="sm"
                    >
                      <Trash2 className="h-4 w-4 mr-2" />
                      Eliminar Portfólio
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        </Tabs>

        {/* Buy Modal */}
        {showBuyModal && selectedAsset && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <Card className="bg-gray-800 border-green-600 max-w-md mx-4 w-full">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Plus className="h-5 w-5 text-green-400" />
                  Comprar {selectedAsset.asset_name}
                </CardTitle>
                <CardDescription className="text-gray-400">
                  {selectedAsset.symbol} • {formatCurrency(selectedAsset.current_price)} por share
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="bg-gradient-to-r from-green-900/30 to-gray-800/30 rounded-lg p-4 border border-green-800/30">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-300">Fundos Disponíveis</span>
                    <span className="text-white font-bold">{formatCurrency(portfolio?.current_funds || 0)}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Holdings Atuais</span>
                    <span className="text-white font-bold">{selectedAsset.quantity_held} shares</span>
                  </div>
                </div>

                <div>
                  <Label htmlFor="buy-quantity" className="text-gray-300">Quantidade a Comprar</Label>
                  <Input
                    id="buy-quantity"
                    type="number"
                    placeholder="0"
                    min="0"
                    step="0.01"
                    value={tradeQuantity}
                    onChange={(e) => setTradeQuantity(e.target.value)}
                    className="bg-gray-700/50 border-gray-600 text-white mt-2"
                  />
                  {tradeQuantity && (
                    <p className="text-sm text-gray-400 mt-2">
                      Total: {formatCurrency(parseFloat(tradeQuantity || '0') * selectedAsset.current_price)}
                    </p>
                  )}
                </div>

                <div className="flex gap-3 pt-4">
                  <Button
                    onClick={() => setShowBuyModal(false)}
                    variant="outline"
                    className="flex-1 border-gray-600 text-gray-300"
                    disabled={isTrading}
                  >
                    Cancelar
                  </Button>
                  <Button
                    onClick={executeBuyTrade}
                    disabled={!tradeQuantity || isTrading}
                    className="flex-1 bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800"
                  >
                    {isTrading ? (
                      <>
                        <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        A comprar...
                      </>
                    ) : (
                      <>
                        <Plus className="h-4 w-4 mr-2" />
                        Comprar
                      </>
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Sell Modal */}
        {showSellModal && selectedAsset && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <Card className="bg-gray-800 border-red-600 max-w-md mx-4 w-full">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <DollarSign className="h-5 w-5 text-red-400" />
                  Vender {selectedAsset.asset_name}
                </CardTitle>
                <CardDescription className="text-gray-400">
                  {selectedAsset.symbol} • {formatCurrency(selectedAsset.current_price)} por share
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="bg-gradient-to-r from-red-900/30 to-gray-800/30 rounded-lg p-4 border border-red-800/30">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-gray-300">Holdings Disponíveis</span>
                    <span className="text-white font-bold">{selectedAsset.quantity_held} shares</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-gray-300">Valor Total</span>
                    <span className="text-white font-bold">{formatCurrency(selectedAsset.market_value)}</span>
                  </div>
                </div>

                <div>
                  <Label htmlFor="sell-quantity" className="text-gray-300">Quantidade a Vender</Label>
                  <Input
                    id="sell-quantity"
                    type="number"
                    placeholder="0"
                    min="0"
                    max={selectedAsset.quantity_held}
                    step="0.01"
                    value={tradeQuantity}
                    onChange={(e) => setTradeQuantity(e.target.value)}
                    className="bg-gray-700/50 border-gray-600 text-white mt-2"
                  />
                  <div className="flex justify-between mt-2">
                    <Button
                      size="sm"
                      variant="outline"
                      className="text-xs border-gray-600 text-gray-400"
                      onClick={() => setTradeQuantity((selectedAsset.quantity_held * 0.25).toString())}
                    >
                      25%
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="text-xs border-gray-600 text-gray-400"
                      onClick={() => setTradeQuantity((selectedAsset.quantity_held * 0.5).toString())}
                    >
                      50%
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="text-xs border-gray-600 text-gray-400"
                      onClick={() => setTradeQuantity((selectedAsset.quantity_held * 0.75).toString())}
                    >
                      75%
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="text-xs border-gray-600 text-gray-400"
                      onClick={() => setTradeQuantity(selectedAsset.quantity_held.toString())}
                    >
                      Tudo
                    </Button>
                  </div>
                  {tradeQuantity && (
                    <p className="text-sm text-gray-400 mt-2">
                      Receberá: {formatCurrency(parseFloat(tradeQuantity || '0') * selectedAsset.current_price)}
                    </p>
                  )}
                </div>

                <div className="flex gap-3 pt-4">
                  <Button
                    onClick={() => setShowSellModal(false)}
                    variant="outline"
                    className="flex-1 border-gray-600 text-gray-300"
                    disabled={isTrading}
                  >
                    Cancelar
                  </Button>
                  <Button
                    onClick={executeSellTrade}
                    disabled={!tradeQuantity || isTrading}
                    variant="outline"
                    className="flex-1 border-red-600 text-red-400 hover:bg-red-600/20"
                  >
                    {isTrading ? (
                      <>
                        <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        A vender...
                      </>
                    ) : (
                      <>
                        <DollarSign className="h-4 w-4 mr-2" />
                        Vender
                      </>
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Delete Confirmation Modal */}
        {showDeleteConfirm && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <Card className="bg-gray-800 border-red-600 max-w-md mx-4">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <AlertCircle className="h-5 w-5 text-red-400" />
                  Confirmar Eliminação
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <p className="text-gray-300">
                  Tem a certeza que deseja eliminar o portfólio <strong>{portfolio.name}</strong>? 
                  Esta ação é irreversível.
                </p>
                {deleteError && (
                  <p className="text-red-400 text-sm">{deleteError}</p>
                )}
                <div className="flex gap-2 justify-end">
                  <Button
                    onClick={() => setShowDeleteConfirm(false)}
                    variant="outline"
                    className="border-gray-600 text-gray-300"
                    disabled={isDeleting}
                  >
                    Cancelar
                  </Button>
                  <Button 
                    onClick={handleDeletePortfolio}
                    variant="destructive"
                    disabled={isDeleting}
                  >
                    {isDeleting ? (
                      <>
                        <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                        A eliminar...
                      </>
                    ) : (
                      <>
                        <Trash2 className="h-4 w-4 mr-2" />
                        Eliminar
                      </>
                    )}
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        {/* Deallocate Funds Modal */}
        {showDeallocateModal && (
          <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gradient-to-br from-gray-800 to-gray-900 p-6 rounded-xl border border-gray-700 max-w-md w-full mx-4">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-xl font-bold text-white">Retirar Fundos do Portfólio</h3>
                <Button 
                  variant="ghost" 
                  size="sm" 
                  onClick={() => setShowDeallocateModal(false)}
                  className="text-gray-400 hover:text-white"
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
              
              <div className="space-y-4">
                <div className="bg-blue-900/30 border border-blue-600/50 rounded-lg p-3">
                  <p className="text-blue-200 text-sm">
                    <span className="font-medium">Fundos Disponíveis:</span> {formatCurrency(portfolio.current_funds)}
                  </p>
                </div>

                <div>
                  <Label className="text-white text-sm font-medium">Valor a Retirar</Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    max={portfolio.current_funds}
                    value={deallocateAmount}
                    onChange={(e) => setDeallocateAmount(e.target.value)}
                    placeholder="0.00"
                    className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>

                {/* Quick Deallocate Options */}
                <div>
                  <Label className="text-white text-sm font-medium">Retirada Rápida</Label>
                  <div className="grid grid-cols-3 gap-2 mt-2">
                    {[25, 50, 100].map((percentage) => {
                      const amount = portfolio.current_funds * (percentage / 100)
                      return (
                        <Button
                          key={percentage}
                          variant="outline"
                          size="sm"
                          onClick={() => setDeallocateAmount(amount.toString())}
                          className="border-gray-600 text-gray-200 hover:bg-orange-900/30 hover:border-orange-600/60 hover:text-orange-200"
                          disabled={amount <= 0}
                        >
                          {percentage}%
                        </Button>
                      )
                    })}
                  </div>
                </div>

                <div className="flex gap-3">
                  <Button 
                    variant="outline" 
                    onClick={() => setShowDeallocateModal(false)}
                    className="flex-1 bg-gray-800/40 border-gray-600/60 text-gray-100 hover:bg-gray-700/60 hover:border-gray-500 hover:text-white"
                  >
                    Cancelar
                  </Button>
                  <Button 
                    onClick={handleDeallocateFunds}
                    disabled={isDeallocating || !deallocateAmount || parseFloat(deallocateAmount) <= 0 || parseFloat(deallocateAmount) > portfolio.current_funds}
                    className="flex-1 bg-gradient-to-r from-orange-600 to-orange-700 hover:from-orange-700 hover:to-orange-800"
                  >
                    {isDeallocating ? (
                      <>
                        <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                        Retirando...
                      </>
                    ) : (
                      <>
                        <ArrowDownCircle className="mr-2 h-4 w-4" />
                        Retirar Fundos
                      </>
                    )}
                  </Button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
} 