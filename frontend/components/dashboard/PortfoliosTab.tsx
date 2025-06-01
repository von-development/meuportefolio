'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  PieChart, 
  Plus, 
  Eye, 
  Edit,
  Trash2,
  TrendingUp,
  TrendingDown,
  Wallet,
  BarChart3,
  Calendar,
  AlertCircle,
  CheckCircle,
  DollarSign
} from 'lucide-react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'

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

interface PortfolioWithBalance extends Portfolio {
  balance?: PortfolioBalance
}

interface PortfoliosTabProps {
  userId: string | undefined
  totalPortfolios?: number
  formatCurrency: (amount: number) => string
  onRefresh?: () => void
}

export default function PortfoliosTab({ userId, totalPortfolios, formatCurrency, onRefresh }: PortfoliosTabProps) {
  const router = useRouter()
  const [portfolios, setPortfolios] = useState<PortfolioWithBalance[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isCreating, setIsCreating] = useState(false)
  const [createError, setCreateError] = useState('')
  const [createSuccess, setCreateSuccess] = useState('')
  
  // Create portfolio form state
  const [newPortfolio, setNewPortfolio] = useState({
    name: '',
    initial_funds: ''
  })

  // Delete state
  const [deletePortfolioId, setDeletePortfolioId] = useState<number | null>(null)
  const [isDeleting, setIsDeleting] = useState(false)
  const [deleteError, setDeleteError] = useState('')

  // Overview stats
  const [overviewStats, setOverviewStats] = useState({
    totalValue: 0,
    totalCash: 0,
    totalHoldings: 0,
    totalProfit: 0,
    portfolioCount: 0
  })

  useEffect(() => {
    if (userId) {
      fetchPortfolios()
    }
  }, [userId])

  const fetchPortfolios = async () => {
    try {
      setIsLoading(true)
      
      // Fetch all portfolios for the user
      const response = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${userId}`)
      if (response.ok) {
        const portfoliosData: Portfolio[] = await response.json()
        
        // Fetch balance for each portfolio
        const portfoliosWithBalance = await Promise.all(
          portfoliosData.map(async (portfolio) => {
            try {
              const balanceResponse = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolio.portfolio_id}/balance`)
              if (balanceResponse.ok) {
                const balance: PortfolioBalance = await balanceResponse.json()
                return { ...portfolio, balance }
              }
              return portfolio
            } catch (error) {
              console.error(`Failed to fetch balance for portfolio ${portfolio.portfolio_id}:`, error)
              return portfolio
            }
          })
        )
        
        setPortfolios(portfoliosWithBalance)
        calculateOverviewStats(portfoliosWithBalance)
      }
    } catch (error) {
      console.error('Failed to fetch portfolios:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const calculateOverviewStats = (portfolios: PortfolioWithBalance[]) => {
    const stats = portfolios.reduce((acc, portfolio) => {
      if (portfolio.balance) {
        acc.totalValue += portfolio.balance.total_portfolio_value
        acc.totalCash += portfolio.balance.cash_balance
        acc.totalHoldings += portfolio.balance.holdings_value
      }
      acc.totalProfit += portfolio.current_profit_pct
      return acc
    }, {
      totalValue: 0,
      totalCash: 0,
      totalHoldings: 0,
      totalProfit: 0,
      portfolioCount: portfolios.length
    })

    setOverviewStats(stats)
  }

  const handleCreatePortfolio = async () => {
    if (!newPortfolio.name.trim()) {
      setCreateError('Nome do portfólio é obrigatório')
      return
    }

    if (newPortfolio.initial_funds && parseFloat(newPortfolio.initial_funds) < 0) {
      setCreateError('Fundos iniciais não podem ser negativos')
      return
    }

    setIsCreating(true)
    setCreateError('')
    setCreateSuccess('')

    try {
      const requestBody = {
        user_id: userId,
        name: newPortfolio.name,
        initial_funds: newPortfolio.initial_funds ? parseFloat(newPortfolio.initial_funds) : undefined
      }

      const response = await fetch(`http://localhost:8080/api/v1/portfolios`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      })

      if (response.ok) {
        const result = await response.json()
        setCreateSuccess(`Portfólio "${result.name}" criado com sucesso!`)
        setNewPortfolio({ name: '', initial_funds: '' })
        fetchPortfolios() // Refresh the list
        onRefresh?.() // Notify parent dashboard to refresh
      } else {
        const errorData = await response.text()
        setCreateError(`Erro ao criar portfólio: ${errorData}`)
      }
    } catch (error) {
      console.error('Create portfolio failed:', error)
      setCreateError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsCreating(false)
    }
  }

  const handleDeletePortfolio = async (portfolioId: number, portfolioName: string) => {
    try {
      setIsDeleting(true)
      setDeleteError('')

      const response = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}`, {
        method: 'DELETE',
      })

      if (response.ok) {
        setCreateSuccess(`Portfólio "${portfolioName}" eliminado com sucesso!`)
        setDeletePortfolioId(null)
        fetchPortfolios() // Refresh the list
        onRefresh?.() // Notify parent dashboard to refresh
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

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-PT')
  }

  const formatPercentage = (percentage: number) => {
    return `${percentage >= 0 ? '+' : ''}${percentage.toFixed(2)}%`
  }

  if (isLoading) {
    return (
      <div className="text-center py-8">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
        <p className="text-gray-400 mt-4">A carregar portfólios...</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Portfolio Overview Stats */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <BarChart3 className="h-5 w-5 mr-2" />
            Resumo dos Portfólios
          </CardTitle>
          <CardDescription className="text-gray-400">
            Visão geral dos seus investimentos
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="text-center p-4 rounded-lg bg-blue-950/50 border border-blue-800/40">
              <PieChart className="h-8 w-8 mx-auto mb-2 text-blue-400" />
              <div className="text-2xl font-bold text-white">{overviewStats.portfolioCount}</div>
              <p className="text-blue-200 text-sm">Portfólios</p>
            </div>
            <div className="text-center p-4 rounded-lg bg-green-950/50 border border-green-800/40">
              <Wallet className="h-8 w-8 mx-auto mb-2 text-green-400" />
              <div className="text-2xl font-bold text-white">{formatCurrency(overviewStats.totalValue)}</div>
              <p className="text-green-200 text-sm">Valor Total</p>
            </div>
            <div className="text-center p-4 rounded-lg bg-purple-950/50 border border-purple-800/40">
              <DollarSign className="h-8 w-8 mx-auto mb-2 text-purple-400" />
              <div className="text-2xl font-bold text-white">{formatCurrency(overviewStats.totalCash)}</div>
              <p className="text-purple-200 text-sm">Dinheiro</p>
            </div>
            <div className="text-center p-4 rounded-lg bg-yellow-950/50 border border-yellow-800/40">
              <TrendingUp className="h-8 w-8 mx-auto mb-2 text-yellow-400" />
              <div className="text-2xl font-bold text-white">{formatCurrency(overviewStats.totalHoldings)}</div>
              <p className="text-yellow-200 text-sm">Holdings</p>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Create New Portfolio */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Plus className="h-5 w-5 mr-2" />
            Criar Novo Portfólio
          </CardTitle>
          <CardDescription className="text-gray-400">
            Adicione um novo portfólio aos seus investimentos
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label htmlFor="portfolio-name" className="text-white text-sm font-medium">
                Nome do Portfólio *
              </Label>
              <Input
                id="portfolio-name"
                value={newPortfolio.name}
                onChange={(e) => setNewPortfolio({...newPortfolio, name: e.target.value})}
                className="bg-gray-700 border-gray-600 text-white mt-1"
                placeholder="Ex: Portfólio Conservador"
              />
            </div>
            <div>
              <Label htmlFor="initial-funds" className="text-white text-sm font-medium">
                Fundos Iniciais (Opcional)
              </Label>
              <div className="relative mt-1">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <span className="text-gray-400">€</span>
                </div>
                <Input
                  id="initial-funds"
                  type="number"
                  value={newPortfolio.initial_funds}
                  onChange={(e) => setNewPortfolio({...newPortfolio, initial_funds: e.target.value})}
                  className="bg-gray-700 border-gray-600 text-white pl-8"
                  placeholder="0.00"
                  min="0"
                  step="0.01"
                />
              </div>
            </div>
          </div>

          {/* Messages */}
          {createError && (
            <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
              <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
              <p className="text-red-300 text-sm">{createError}</p>
            </div>
          )}

          {createSuccess && (
            <div className="flex items-center p-3 rounded-lg bg-green-950/50 border border-green-800/40">
              <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
              <p className="text-green-300 text-sm">{createSuccess}</p>
            </div>
          )}

          <Button 
            onClick={handleCreatePortfolio}
            disabled={isCreating || !newPortfolio.name.trim()}
            className="w-full bg-green-600 hover:bg-green-700"
          >
            {isCreating ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                A criar portfólio...
              </div>
            ) : (
              <>
                <Plus className="h-5 w-5 mr-2" />
                Criar Portfólio
              </>
            )}
          </Button>
        </CardContent>
      </Card>

      {/* Portfolio List */}
      {portfolios.length === 0 ? (
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardContent className="text-center py-12">
            <PieChart className="h-16 w-16 mx-auto mb-4 text-gray-500" />
            <h3 className="text-lg font-medium text-white mb-2">Nenhum portfólio encontrado</h3>
            <p className="text-gray-400 mb-6">
              Crie o seu primeiro portfólio para começar a investir
            </p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-semibold text-white">Os Seus Portfólios</h3>
            <Badge variant="outline" className="border-gray-600 text-gray-300">
              {portfolios.length} {portfolios.length === 1 ? 'portfólio' : 'portfólios'}
            </Badge>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {portfolios.map((portfolio) => (
              <Card key={portfolio.portfolio_id} className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40 hover:border-blue-600/60 transition-all">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-white text-lg">{portfolio.name}</CardTitle>
                      <CardDescription className="text-gray-400 text-sm">
                        Criado em {formatDate(portfolio.creation_date)}
                      </CardDescription>
                    </div>
                    <div className="flex items-center gap-1">
                      <Button size="sm" variant="outline" className="h-8 w-8 p-0 border-gray-600 text-gray-300 hover:bg-gray-600">
                        <Edit className="h-4 w-4" />
                      </Button>
                      <Button 
                        size="sm" 
                        variant="outline" 
                        onClick={() => setDeletePortfolioId(portfolio.portfolio_id)}
                        className="h-8 w-8 p-0 border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="space-y-4">
                  {/* Financial Info */}
                  <div className="space-y-2">
                    <div className="flex justify-between items-center">
                      <span className="text-gray-400 text-sm">Valor Total</span>
                      <span className="text-white font-semibold">
                        {portfolio.balance ? formatCurrency(portfolio.balance.total_portfolio_value) : formatCurrency(portfolio.current_funds)}
                      </span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="text-gray-400 text-sm">Dinheiro</span>
                      <span className="text-blue-300">
                        {portfolio.balance ? formatCurrency(portfolio.balance.cash_balance) : formatCurrency(portfolio.current_funds)}
                      </span>
                    </div>
                    {portfolio.balance && (
                      <div className="flex justify-between items-center">
                        <span className="text-gray-400 text-sm">Holdings</span>
                        <span className="text-green-300">
                          {formatCurrency(portfolio.balance.holdings_value)}
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Performance */}
                  <div className="flex justify-between items-center p-2 rounded bg-gray-800/40">
                    <span className="text-gray-400 text-sm">Performance</span>
                    <div className="flex items-center">
                      {portfolio.current_profit_pct >= 0 ? (
                        <TrendingUp className="h-4 w-4 text-green-400 mr-1" />
                      ) : (
                        <TrendingDown className="h-4 w-4 text-red-400 mr-1" />
                      )}
                      <span className={`font-medium ${portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                        {formatPercentage(portfolio.current_profit_pct)}
                      </span>
                    </div>
                  </div>

                  {/* Holdings count */}
                  {portfolio.balance?.holdings_count !== undefined && (
                    <div className="flex justify-between items-center">
                      <span className="text-gray-400 text-sm">Ativos</span>
                      <Badge variant="outline" className="border-gray-600 text-gray-300">
                        {portfolio.balance.holdings_count}
                      </Badge>
                    </div>
                  )}

                  {/* Action Buttons */}
                  <div className="space-y-2 pt-2">
                    <Button 
                      onClick={() => router.push(`/portfolios/${portfolio.portfolio_id}`)}
                      className="w-full bg-blue-600 hover:bg-blue-700" 
                      size="sm"
                    >
                      <Eye className="h-4 w-4 mr-2" />
                      Ver Detalhes
                    </Button>
                  </div>

                  {/* Last Updated */}
                  <div className="text-xs text-gray-500 flex items-center">
                    <Calendar className="h-3 w-3 mr-1" />
                    Atualizado: {formatDate(portfolio.last_updated)}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {deletePortfolioId && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <Card className="bg-gray-800 border-red-600 max-w-md mx-4">
            <CardHeader>
              <CardTitle className="text-red-400 flex items-center">
                <AlertCircle className="h-5 w-5 mr-2" />
                Confirmar Eliminação
              </CardTitle>
              <CardDescription className="text-gray-300">
                Esta ação não pode ser desfeita. Todos os dados do portfólio serão permanentemente removidos.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              {(() => {
                const portfolio = portfolios.find(p => p.portfolio_id === deletePortfolioId)
                return (
                  <>
                    <p className="text-white">
                      Tem a certeza que deseja eliminar o portfólio <strong>"{portfolio?.name}"</strong>?
                    </p>
                    
                    {deleteError && (
                      <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
                        <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
                        <p className="text-red-300 text-sm">{deleteError}</p>
                      </div>
                    )}
                    
                    <div className="flex gap-3 pt-4">
                      <Button 
                        onClick={() => handleDeletePortfolio(deletePortfolioId, portfolio?.name || '')}
                        disabled={isDeleting}
                        className="flex-1 bg-red-600 hover:bg-red-700"
                      >
                        {isDeleting ? (
                          <div className="flex items-center">
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                            A eliminar...
                          </div>
                        ) : (
                          <>
                            <Trash2 className="h-4 w-4 mr-2" />
                            Eliminar Portfólio
                          </>
                        )}
                      </Button>
                      <Button 
                        variant="outline" 
                        onClick={() => {setDeletePortfolioId(null); setDeleteError('')}}
                        className="flex-1 border-gray-600 text-gray-300 hover:bg-gray-600"
                      >
                        Cancelar
                      </Button>
                    </div>
                  </>
                )
              })()}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
} 