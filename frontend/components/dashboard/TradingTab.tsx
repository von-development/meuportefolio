'use client'

import React, { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { Badge } from '@/components/ui/badge'
import { 
  TrendingUp, 
  TrendingDown, 
  ShoppingCart, 
  DollarSign, 
  PieChart,
  Search,
  AlertCircle,
  CheckCircle,
  RefreshCw,
  BarChart3,
  Activity,
  Target,
  Filter,
  Bitcoin,
  Landmark,
  TrendingUpIcon,
  Coins
} from 'lucide-react'
import { toast } from 'sonner'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, AreaChart, Area } from 'recharts'

interface Portfolio {
  portfolio_id: number
  user_id: string
  name: string
  creation_date: string
  current_funds: number
  current_profit_pct: number
  last_updated: string
}

interface Asset {
  asset_id: number
  name: string
  symbol: string
  asset_type: string
  price: number
  volume: number
  available_shares: number
  last_updated: string
}

interface PortfolioHolding {
  holding_id: number
  portfolio_id: number
  asset_id: number
  asset_name: string
  symbol: string
  asset_type: string
  quantity_held: number
  average_price: number
  total_cost: number
  current_price: number
  current_value: number
  unrealized_gain_loss: number
  last_updated: string
}

interface BuyAssetRequest {
  portfolio_id: number
  asset_id: number
  quantity: number
  unit_price?: number
}

interface SellAssetRequest {
  portfolio_id: number
  asset_id: number
  quantity: number
  unit_price?: number
}

interface PriceHistoryPoint {
  timestamp: string
  price: number
  volume: number
}

interface TradingTabProps {
  userId?: string
  formatCurrency: (amount: number) => string
  onRefresh: () => void
}

const ASSET_TYPES = [
  { value: '', label: 'Todos os Ativos', icon: Activity },
  { value: 'Stock', label: 'Ações', icon: TrendingUpIcon },
  { value: 'Cryptocurrency', label: 'Criptomoedas', icon: Bitcoin },
  { value: 'Commodity', label: 'Commodities', icon: Coins },
  { value: 'Index', label: 'Índices', icon: BarChart3 },
]

export default function TradingTab({ userId, formatCurrency, onRefresh }: TradingTabProps) {
  const [portfolios, setPortfolios] = useState<Portfolio[]>([])
  const [assets, setAssets] = useState<Asset[]>([])
  const [holdings, setHoldings] = useState<PortfolioHolding[]>([])
  const [selectedPortfolio, setSelectedPortfolio] = useState<string>('')
  const [selectedAsset, setSelectedAsset] = useState<string>('')
  const [selectedAssetPriceHistory, setSelectedAssetPriceHistory] = useState<PriceHistoryPoint[]>([])
  const [assetSearch, setAssetSearch] = useState('')
  const [assetTypeFilter, setAssetTypeFilter] = useState<string>('')
  const [loading, setLoading] = useState(true)
  const [tradeLoading, setTradeLoading] = useState(false)
  const [chartLoading, setChartLoading] = useState(false)
  
  // Buy form state
  const [buyQuantity, setBuyQuantity] = useState('')
  const [buyPrice, setBuyPrice] = useState('')
  const [useMarketPrice, setUseMarketPrice] = useState(true)
  
  // Sell form state
  const [sellQuantity, setSellQuantity] = useState('')
  const [sellPrice, setSellPrice] = useState('')
  const [useMarketPriceSell, setUseMarketPriceSell] = useState(true)

  useEffect(() => {
    if (userId) {
      fetchData()
    }
  }, [userId])

  useEffect(() => {
    if (selectedPortfolio) {
      fetchPortfolioHoldings(Number(selectedPortfolio))
    }
  }, [selectedPortfolio])

  useEffect(() => {
    if (selectedAsset) {
      fetchAssetPriceHistory(Number(selectedAsset))
    }
  }, [selectedAsset])

  const fetchData = async () => {
    try {
      setLoading(true)
      await Promise.all([
        fetchPortfolios(),
        fetchAssets()
      ])
    } catch (error) {
      console.error('Failed to fetch trading data:', error)
      toast.error('Falha ao carregar dados de trading')
    } finally {
      setLoading(false)
    }
  }

  const fetchPortfolios = async () => {
    try {
      const response = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${userId}`)
      if (response.ok) {
        const data = await response.json()
        setPortfolios(data)
        if (data.length > 0 && !selectedPortfolio) {
          setSelectedPortfolio(data[0].portfolio_id.toString())
        }
      } else {
        console.error('Failed to fetch portfolios:', response.status)
        toast.error('Erro ao carregar portfólios')
      }
    } catch (error) {
      console.error('Failed to fetch portfolios:', error)
      toast.error('Erro de conexão ao carregar portfólios')
    }
  }

  const fetchAssets = async () => {
    try {
      const response = await fetch('http://localhost:8080/api/v1/assets')
      if (response.ok) {
        const data = await response.json()
        console.log('Assets loaded:', data)
        setAssets(data)
      } else {
        console.error('Failed to fetch assets:', response.status)
        toast.error('Erro ao carregar ativos')
      }
    } catch (error) {
      console.error('Failed to fetch assets:', error)
      toast.error('Erro de conexão ao carregar ativos')
    }
  }

  const fetchPortfolioHoldings = async (portfolioId: number) => {
    try {
      const response = await fetch(`http://localhost:8080/api/v1/portfolios/${portfolioId}/holdings-summary`)
      if (response.ok) {
        const data = await response.json()
        console.log('Holdings loaded:', data)
        setHoldings(data.holdings || [])
      } else {
        console.error('Failed to fetch holdings:', response.status)
        if (response.status === 404) {
          setHoldings([])
        } else {
          toast.error('Erro ao carregar holdings do portfólio')
        }
      }
    } catch (error) {
      console.error('Failed to fetch portfolio holdings:', error)
      setHoldings([])
    }
  }

  const fetchAssetPriceHistory = async (assetId: number) => {
    try {
      setChartLoading(true)
      const response = await fetch(`http://localhost:8080/api/v1/assets/${assetId}/price-history`)
      if (response.ok) {
        const data = await response.json()
        const chartData = data.map((point: any) => ({
          timestamp: new Date(point.timestamp).toLocaleDateString(),
          price: point.price,
          volume: point.volume
        }))
        setSelectedAssetPriceHistory(chartData)
      } else {
        console.error('Failed to fetch price history:', response.status)
        generateMockPriceHistory(assetId)
      }
    } catch (error) {
      console.error('Failed to fetch price history:', error)
      generateMockPriceHistory(assetId)
    } finally {
      setChartLoading(false)
    }
  }

  const generateMockPriceHistory = (assetId: number) => {
    const asset = assets.find(a => a.asset_id === assetId)
    if (!asset) return

    const days = 30
    const data = []
    let price = asset.price
    
    for (let i = days; i >= 0; i--) {
      const date = new Date()
      date.setDate(date.getDate() - i)
      
      const change = (Math.random() - 0.5) * 0.1
      price = price * (1 + change)
      
      data.push({
        timestamp: date.toLocaleDateString(),
        price: Math.round(price * 100) / 100,
        volume: Math.floor(Math.random() * 1000000) + 100000
      })
    }
    
    setSelectedAssetPriceHistory(data)
  }

  const handleBuyAsset = async () => {
    if (!selectedPortfolio || !selectedAsset || !buyQuantity) {
      toast.error('Por favor preencha todos os campos obrigatórios')
      return
    }

    const quantity = parseFloat(buyQuantity)
    if (quantity <= 0) {
      toast.error('A quantidade deve ser positiva')
      return
    }

    let unitPrice: number | undefined
    if (!useMarketPrice && buyPrice) {
      unitPrice = parseFloat(buyPrice)
      if (unitPrice <= 0) {
        toast.error('O preço deve ser positivo')
        return
      }
    }

    const buyRequest: BuyAssetRequest = {
      portfolio_id: Number(selectedPortfolio),
      asset_id: Number(selectedAsset),
      quantity,
      unit_price: unitPrice
    }

    try {
      setTradeLoading(true)
      const response = await fetch('http://localhost:8080/api/v1/portfolios/buy', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(buyRequest),
      })

      if (response.ok) {
        const result = await response.json()
        toast.success(`✅ Compra realizada! ${result.quantity_purchased} ações por ${formatCurrency(result.total_cost)}`)
        
        setBuyQuantity('')
        setBuyPrice('')
        setUseMarketPrice(true)
        
        await fetchPortfolioHoldings(Number(selectedPortfolio))
        onRefresh()
      } else {
        const error = await response.text()
        toast.error(`❌ Falha na compra: ${error}`)
      }
    } catch (error) {
      console.error('Buy asset error:', error)
      toast.error('❌ Erro ao realizar compra')
    } finally {
      setTradeLoading(false)
    }
  }

  const handleSellAsset = async () => {
    if (!selectedPortfolio || !selectedAsset || !sellQuantity) {
      toast.error('Por favor preencha todos os campos obrigatórios')
      return
    }

    const quantity = parseFloat(sellQuantity)
    if (quantity <= 0) {
      toast.error('A quantidade deve ser positiva')
      return
    }

    let unitPrice: number | undefined
    if (!useMarketPriceSell && sellPrice) {
      unitPrice = parseFloat(sellPrice)
      if (unitPrice <= 0) {
        toast.error('O preço deve ser positivo')
        return
      }
    }

    const sellRequest: SellAssetRequest = {
      portfolio_id: Number(selectedPortfolio),
      asset_id: Number(selectedAsset),
      quantity,
      unit_price: unitPrice
    }

    try {
      setTradeLoading(true)
      const response = await fetch('http://localhost:8080/api/v1/portfolios/sell', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(sellRequest),
      })

      if (response.ok) {
        const result = await response.json()
        toast.success(`✅ Venda realizada! ${result.quantity_sold} ações por ${formatCurrency(result.total_proceeds)}`)
        
        setSellQuantity('')
        setSellPrice('')
        setUseMarketPriceSell(true)
        
        await fetchPortfolioHoldings(Number(selectedPortfolio))
        onRefresh()
      } else {
        const error = await response.text()
        toast.error(`❌ Falha na venda: ${error}`)
      }
    } catch (error) {
      console.error('Sell asset error:', error)
      toast.error('❌ Erro ao realizar venda')
    } finally {
      setTradeLoading(false)
    }
  }

  const handleQuickSell = (holding: PortfolioHolding, percentage: number) => {
    setSelectedAsset(holding.asset_id.toString())
    setSellQuantity((holding.quantity_held * percentage / 100).toString())
    setUseMarketPriceSell(true)
  }

  const getAssetTypeIcon = (type: string) => {
    const assetType = ASSET_TYPES.find(at => at.value === type)
    const Icon = assetType?.icon || Activity
    return <Icon className="h-4 w-4" />
  }

  const filteredAssets = assets.filter(asset => {
    const matchesSearch = asset.name.toLowerCase().includes(assetSearch.toLowerCase()) ||
                         asset.symbol.toLowerCase().includes(assetSearch.toLowerCase())
    const matchesType = !assetTypeFilter || asset.asset_type === assetTypeFilter
    return matchesSearch && matchesType
  })

  const filteredHoldings = holdings.filter(holding => {
    const matchesSearch = holding.asset_name.toLowerCase().includes(assetSearch.toLowerCase()) ||
                         holding.symbol.toLowerCase().includes(assetSearch.toLowerCase())
    const matchesType = !assetTypeFilter || holding.asset_type === assetTypeFilter
    return matchesSearch && matchesType
  })

  const selectedAssetData = assets.find(asset => asset.asset_id.toString() === selectedAsset)
  const selectedPortfolioData = portfolios.find(p => p.portfolio_id.toString() === selectedPortfolio)

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="text-center">
          <RefreshCw className="h-12 w-12 animate-spin text-blue-400 mx-auto" />
          <p className="text-gray-400 mt-4 text-lg">A carregar dados de trading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Portfolio Selection Header */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <Activity className="h-6 w-6 text-blue-400" />
            Trading Center
          </CardTitle>
          <CardDescription className="text-gray-400">
            Plataforma avançada para comprar e vender ativos com análise em tempo real
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <Label htmlFor="portfolio-select" className="text-gray-300 text-sm font-medium">Selecionar Portfólio</Label>
              <Select value={selectedPortfolio} onValueChange={setSelectedPortfolio}>
                <SelectTrigger className="bg-gray-700/50 border-gray-600 text-white mt-2">
                  <SelectValue placeholder="Escolher portfólio para trading" />
                </SelectTrigger>
                <SelectContent className="bg-gray-800 border-gray-600">
                  {portfolios.map((portfolio) => (
                    <SelectItem key={portfolio.portfolio_id} value={portfolio.portfolio_id.toString()}>
                      <div className="flex items-center justify-between w-full">
                        <span className="font-medium">{portfolio.name}</span>
                        <span className="text-green-400 ml-4">{formatCurrency(portfolio.current_funds)} disponível</span>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            <div>
              <Label htmlFor="asset-search" className="text-gray-300 text-sm font-medium">Pesquisar Ativo</Label>
              <div className="relative mt-2">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  id="asset-search"
                  placeholder="Digite nome ou símbolo (ex: AAPL, BTC)..."
                  value={assetSearch}
                  onChange={(e) => setAssetSearch(e.target.value)}
                  className="pl-10 bg-gray-700/50 border-gray-600 text-white placeholder:text-gray-400"
                />
              </div>
            </div>
          </div>

          {/* Asset Type Filters */}
          <div>
            <Label className="text-gray-300 text-sm font-medium flex items-center gap-2">
              <Filter className="h-4 w-4" />
              Filtrar por Tipo de Ativo
            </Label>
            <div className="grid grid-cols-2 md:grid-cols-5 gap-2 mt-2">
              {ASSET_TYPES.map((type) => {
                const Icon = type.icon
                return (
                  <Button
                    key={type.value}
                    variant={assetTypeFilter === type.value ? "default" : "outline"}
                    size="sm"
                    onClick={() => setAssetTypeFilter(type.value)}
                    className={`justify-start ${
                      assetTypeFilter === type.value 
                        ? 'bg-blue-600 hover:bg-blue-700 text-white' 
                        : 'border-gray-600 text-gray-300 hover:bg-gray-600'
                    }`}
                  >
                    <Icon className="h-4 w-4 mr-2" />
                    {type.label}
                  </Button>
                )
              })}
            </div>
          </div>

          {/* Portfolio Summary */}
          {selectedPortfolioData && (
            <div className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 rounded-xl p-6 border border-blue-800/30">
              <h3 className="text-white font-semibold mb-4 flex items-center gap-2">
                <Target className="h-5 w-5 text-blue-400" />
                Resumo do Portfólio: {selectedPortfolioData.name}
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                <div className="text-center">
                  <p className="text-gray-400 text-sm">Fundos Disponíveis</p>
                  <p className="text-white font-bold text-lg">{formatCurrency(selectedPortfolioData.current_funds)}</p>
                </div>
                <div className="text-center">
                  <p className="text-gray-400 text-sm">Rentabilidade</p>
                  <p className={`font-bold text-lg ${selectedPortfolioData.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                    {selectedPortfolioData.current_profit_pct >= 0 ? '+' : ''}{selectedPortfolioData.current_profit_pct.toFixed(2)}%
                  </p>
                </div>
                <div className="text-center">
                  <p className="text-gray-400 text-sm">Holdings</p>
                  <p className="text-white font-bold text-lg">{holdings.length} {holdings.length === 1 ? 'ativo' : 'ativos'}</p>
                </div>
                <div className="text-center">
                  <p className="text-gray-400 text-sm">Valor Total</p>
                  <p className="text-white font-bold text-lg">
                    {formatCurrency(holdings.reduce((sum, h) => sum + h.current_value, 0) + selectedPortfolioData.current_funds)}
                  </p>
                </div>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* New Layout: Two columns with Buy/Sell cards and Chart/Holdings */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        
        {/* Left Column: Trading Cards */}
        <div className="space-y-6">
          {/* Buy Card */}
          <Card className="bg-gradient-to-br from-green-900/20 to-gray-900/60 backdrop-blur-sm border border-green-800/40">
            <CardHeader>
              <CardTitle className="text-white flex items-center gap-2">
                <ShoppingCart className="h-5 w-5 text-green-400" />
                Comprar Ativo
              </CardTitle>
              <CardDescription className="text-gray-400">
                Selecione um ativo e defina a quantidade para compra
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-gray-300 font-medium">Selecionar Ativo</Label>
                <Select value={selectedAsset} onValueChange={setSelectedAsset}>
                  <SelectTrigger className="bg-gray-700/50 border-gray-600 text-white mt-2">
                    <SelectValue placeholder="Escolher ativo para comprar" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-800 border-gray-600 max-h-60">
                    {filteredAssets.map((asset) => (
                      <SelectItem key={asset.asset_id} value={asset.asset_id.toString()}>
                        <div className="flex items-center justify-between w-full">
                          <div className="flex items-center gap-2">
                            {getAssetTypeIcon(asset.asset_type)}
                            <div>
                              <span className="font-medium">{asset.name}</span>
                              <span className="text-gray-400 ml-2">({asset.symbol})</span>
                            </div>
                          </div>
                          <div className="text-right ml-4">
                            <span className="text-green-400 font-bold">{formatCurrency(asset.price)}</span>
                            <div className="text-xs text-gray-400">{asset.available_shares.toFixed(0)} disponível</div>
                          </div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-gray-300 font-medium">Quantidade</Label>
                  <Input
                    type="number"
                    placeholder="0"
                    min="0"
                    step="0.001"
                    value={buyQuantity}
                    onChange={(e) => setBuyQuantity(e.target.value)}
                    className="bg-gray-700/50 border-gray-600 text-white mt-2"
                  />
                  {selectedAssetData && (
                    <p className="text-xs text-gray-400 mt-1">
                      Máximo: {selectedAssetData.available_shares.toFixed(0)} shares
                    </p>
                  )}
                </div>
                
                <div>
                  <Label className="text-gray-300 font-medium">Preço por Unidade</Label>
                  <div className="space-y-2 mt-2">
                    <div className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        id="market-price-buy"
                        checked={useMarketPrice}
                        onChange={(e) => setUseMarketPrice(e.target.checked)}
                        className="rounded bg-gray-700 border-gray-600"
                      />
                      <label htmlFor="market-price-buy" className="text-sm text-gray-300">
                        Usar preço de mercado
                      </label>
                    </div>
                    {!useMarketPrice && (
                      <Input
                        type="number"
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                        value={buyPrice}
                        onChange={(e) => setBuyPrice(e.target.value)}
                        className="bg-gray-700/50 border-gray-600 text-white"
                      />
                    )}
                    {useMarketPrice && selectedAssetData && (
                      <div className="text-sm text-green-400 font-medium">
                        Preço atual: {formatCurrency(selectedAssetData.price)}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {selectedAssetData && buyQuantity && (
                <div className="bg-gradient-to-r from-green-900/30 to-gray-800/30 rounded-lg p-4 border border-green-800/30">
                  <h4 className="text-white font-medium mb-3 flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-400" />
                    Resumo da Ordem
                  </h4>
                  <div className="space-y-2 text-sm">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Total estimado:</span>
                      <span className="text-green-400 font-bold">
                        {formatCurrency(
                          parseFloat(buyQuantity) * (useMarketPrice ? selectedAssetData.price : parseFloat(buyPrice || '0'))
                        )}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              <Button 
                onClick={handleBuyAsset}
                disabled={!selectedPortfolio || !selectedAsset || !buyQuantity || tradeLoading}
                className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white font-medium py-3"
              >
                {tradeLoading ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    A processar...
                  </>
                ) : (
                  <>
                    <ShoppingCart className="h-4 w-4 mr-2" />
                    Executar Compra
                  </>
                )}
              </Button>
            </CardContent>
          </Card>

          {/* Sell Card */}
          <Card className="bg-gradient-to-br from-red-900/20 to-gray-900/60 backdrop-blur-sm border border-red-800/40">
            <CardHeader>
              <CardTitle className="text-white flex items-center gap-2">
                <DollarSign className="h-5 w-5 text-red-400" />
                Vender Ativo
              </CardTitle>
              <CardDescription className="text-gray-400">
                Venda ativos do seu portfólio selecionado
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label className="text-gray-300 font-medium">Selecionar Ativo (Holdings)</Label>
                <Select value={selectedAsset} onValueChange={setSelectedAsset}>
                  <SelectTrigger className="bg-gray-700/50 border-gray-600 text-white mt-2">
                    <SelectValue placeholder="Escolher ativo para vender" />
                  </SelectTrigger>
                  <SelectContent className="bg-gray-800 border-gray-600">
                    {filteredHoldings.map((holding) => (
                      <SelectItem key={holding.asset_id} value={holding.asset_id.toString()}>
                        <div className="flex items-center justify-between w-full">
                          <div className="flex items-center gap-2">
                            {getAssetTypeIcon(holding.asset_type)}
                            <div>
                              <span className="font-medium">{holding.asset_name}</span>
                              <span className="text-gray-400 ml-2">({holding.symbol})</span>
                            </div>
                          </div>
                          <div className="text-right ml-4">
                            <span className="text-blue-400 font-bold">{holding.quantity_held} shares</span>
                            <div className="text-xs text-gray-400">{formatCurrency(holding.current_price)}</div>
                          </div>
                        </div>
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {selectedAsset && holdings.find(h => h.asset_id.toString() === selectedAsset) && (
                <div>
                  <Label className="text-gray-300 font-medium">Venda Rápida</Label>
                  <div className="grid grid-cols-4 gap-2 mt-2">
                    {[25, 50, 75, 100].map((percentage) => (
                      <Button
                        key={percentage}
                        variant="outline"
                        size="sm"
                        onClick={() => handleQuickSell(holdings.find(h => h.asset_id.toString() === selectedAsset)!, percentage)}
                        className="border-gray-600 text-gray-300 hover:bg-gray-600"
                      >
                        {percentage}%
                      </Button>
                    ))}
                  </div>
                </div>
              )}

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label className="text-gray-300 font-medium">Quantidade</Label>
                  <Input
                    type="number"
                    placeholder="0"
                    min="0"
                    step="0.001"
                    value={sellQuantity}
                    onChange={(e) => setSellQuantity(e.target.value)}
                    className="bg-gray-700/50 border-gray-600 text-white mt-2"
                  />
                  {selectedAsset && holdings.find(h => h.asset_id.toString() === selectedAsset) && (
                    <p className="text-xs text-gray-400 mt-1">
                      Disponível: {holdings.find(h => h.asset_id.toString() === selectedAsset)?.quantity_held} shares
                    </p>
                  )}
                </div>
                
                <div>
                  <Label className="text-gray-300 font-medium">Preço por Unidade</Label>
                  <div className="space-y-2 mt-2">
                    <div className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        id="market-price-sell"
                        checked={useMarketPriceSell}
                        onChange={(e) => setUseMarketPriceSell(e.target.checked)}
                        className="rounded bg-gray-700 border-gray-600"
                      />
                      <label htmlFor="market-price-sell" className="text-sm text-gray-300">
                        Usar preço de mercado
                      </label>
                    </div>
                    {!useMarketPriceSell && (
                      <Input
                        type="number"
                        placeholder="0.00"
                        min="0"
                        step="0.01"
                        value={sellPrice}
                        onChange={(e) => setSellPrice(e.target.value)}
                        className="bg-gray-700/50 border-gray-600 text-white"
                      />
                    )}
                    {useMarketPriceSell && selectedAsset && holdings.find(h => h.asset_id.toString() === selectedAsset) && (
                      <div className="text-sm text-red-400 font-medium">
                        Preço atual: {formatCurrency(holdings.find(h => h.asset_id.toString() === selectedAsset)?.current_price || 0)}
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {selectedAsset && sellQuantity && holdings.find(h => h.asset_id.toString() === selectedAsset) && (
                <div className="bg-gradient-to-r from-red-900/30 to-gray-800/30 rounded-lg p-4 border border-red-800/30">
                  <h4 className="text-white font-medium mb-3 flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-red-400" />
                    Resumo da Ordem
                  </h4>
                  {(() => {
                    const holding = holdings.find(h => h.asset_id.toString() === selectedAsset)
                    const currentPrice = useMarketPriceSell ? holding?.current_price || 0 : parseFloat(sellPrice || '0')
                    return (
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-400">Total estimado:</span>
                          <span className="text-red-400 font-bold">
                            {formatCurrency(parseFloat(sellQuantity) * currentPrice)}
                          </span>
                        </div>
                      </div>
                    )
                  })()}
                </div>
              )}

              <Button 
                onClick={handleSellAsset}
                disabled={!selectedPortfolio || !selectedAsset || !sellQuantity || tradeLoading}
                className="w-full bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white font-medium py-3"
              >
                {tradeLoading ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    A processar...
                  </>
                ) : (
                  <>
                    <DollarSign className="h-4 w-4 mr-2" />
                    Executar Venda
                  </>
                )}
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Right Column: Chart and Holdings */}
        <div className="space-y-6">
          {/* Price Chart */}
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader>
              <CardTitle className="text-white flex items-center gap-2">
                <BarChart3 className="h-5 w-5 text-blue-400" />
                Gráfico de Preços
              </CardTitle>
              <CardDescription className="text-gray-400">
                {selectedAssetData ? `${selectedAssetData.name} (${selectedAssetData.symbol})` : 'Selecione um ativo'}
              </CardDescription>
            </CardHeader>
            <CardContent>
              {chartLoading ? (
                <div className="flex items-center justify-center h-64">
                  <RefreshCw className="h-8 w-8 animate-spin text-blue-400" />
                </div>
              ) : selectedAssetPriceHistory.length > 0 ? (
                <div className="h-64">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={selectedAssetPriceHistory}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                      <XAxis 
                        dataKey="timestamp" 
                        stroke="#9CA3AF"
                        fontSize={12}
                      />
                      <YAxis 
                        stroke="#9CA3AF"
                        fontSize={12}
                        tickFormatter={(value) => `€${value.toFixed(0)}`}
                      />
                      <Tooltip 
                        contentStyle={{ 
                          backgroundColor: '#1F2937', 
                          border: '1px solid #374151',
                          borderRadius: '8px',
                          color: '#F9FAFB'
                        }}
                        formatter={(value: any) => [formatCurrency(value), 'Preço']}
                      />
                      <Area 
                        type="monotone" 
                        dataKey="price" 
                        stroke="#3B82F6" 
                        fill="url(#colorPrice)"
                        strokeWidth={2}
                      />
                      <defs>
                        <linearGradient id="colorPrice" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              ) : (
                <div className="flex items-center justify-center h-64 text-gray-400">
                  <div className="text-center">
                    <BarChart3 className="h-12 w-12 mx-auto mb-2 text-gray-600" />
                    <p>Selecione um ativo para ver o gráfico</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          {/* Holdings */}
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader>
              <CardTitle className="text-white flex items-center gap-2">
                <PieChart className="h-5 w-5 text-purple-400" />
                Holdings Atuais
              </CardTitle>
              <CardDescription className="text-gray-400">
                {selectedPortfolioData?.name || 'Selecionar portfólio'}
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 max-h-96 overflow-y-auto">
                {filteredHoldings.length === 0 ? (
                  <div className="text-center py-8">
                    <PieChart className="h-12 w-12 mx-auto mb-2 text-gray-600" />
                    <p className="text-gray-400">Nenhum ativo encontrado</p>
                    <p className="text-gray-500 text-sm mt-1">
                      {holdings.length === 0 ? 'Comece comprando alguns ativos' : 'Tente ajustar os filtros'}
                    </p>
                  </div>
                ) : (
                  filteredHoldings.map((holding) => (
                    <div key={holding.holding_id} className="bg-gradient-to-r from-gray-700/30 to-gray-800/30 rounded-lg p-4 border border-gray-700/50 hover:border-blue-600/50 transition-all">
                      <div className="flex justify-between items-start mb-3">
                        <div className="flex items-center gap-2">
                          {getAssetTypeIcon(holding.asset_type)}
                          <div>
                            <h4 className="text-white font-medium">{holding.asset_name}</h4>
                            <p className="text-gray-400 text-sm">{holding.symbol}</p>
                          </div>
                        </div>
                        <Badge 
                          variant={holding.unrealized_gain_loss >= 0 ? "default" : "destructive"} 
                          className={`${holding.unrealized_gain_loss >= 0 ? 'bg-green-600' : 'bg-red-600'} text-white`}
                        >
                          {holding.unrealized_gain_loss >= 0 ? '+' : ''}{formatCurrency(holding.unrealized_gain_loss)}
                        </Badge>
                      </div>
                      <div className="grid grid-cols-2 gap-3 text-xs">
                        <div>
                          <p className="text-gray-400">Quantidade</p>
                          <p className="text-white font-medium">{holding.quantity_held}</p>
                        </div>
                        <div>
                          <p className="text-gray-400">Valor Atual</p>
                          <p className="text-white font-medium">{formatCurrency(holding.current_value)}</p>
                        </div>
                        <div>
                          <p className="text-gray-400">Preço Médio</p>
                          <p className="text-white font-medium">{formatCurrency(holding.average_price)}</p>
                        </div>
                        <div>
                          <p className="text-gray-400">Preço Atual</p>
                          <p className="text-white font-medium">{formatCurrency(holding.current_price)}</p>
                        </div>
                      </div>
                      
                      <div className="flex gap-2 mt-3">
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            setSelectedAsset(holding.asset_id.toString())
                            setSellQuantity((holding.quantity_held * 0.5).toString())
                          }}
                          className="flex-1 text-xs border-gray-600 text-gray-300 hover:bg-red-600/20"
                        >
                          Vender 50%
                        </Button>
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => {
                            setSelectedAsset(holding.asset_id.toString())
                            setSellQuantity(holding.quantity_held.toString())
                          }}
                          className="flex-1 text-xs border-gray-600 text-gray-300 hover:bg-red-600/20"
                        >
                          Vender Tudo
                        </Button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
} 