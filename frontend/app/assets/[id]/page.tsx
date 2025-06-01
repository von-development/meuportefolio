'use client'

import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import { ArrowLeft, Building2, Coins, BarChart3, Package, Globe, Calendar, Activity, Info, TrendingUp, TrendingDown, Target, Users, Zap, Shield } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import Navbar from '@/components/layout/Navbar'
import TrendIndicator from '@/components/assets/TrendIndicator'
import PriceChart from '@/components/assets/PriceChart'
import { 
  getAssetTypeIcon, 
  getAssetTypeBadge, 
  formatCurrency, 
  formatLargeNumber 
} from '@/components/assets/AssetTypeUtils'

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

interface StockDetails {
  asset_id: number
  sector: string
  country: string
  market_cap: number
  last_updated: string
}

interface CryptoDetails {
  asset_id: number
  blockchain: string
  max_supply?: number
  circulating_supply: number
  last_updated: string
}

interface IndexDetails {
  asset_id: number
  region: string
  index_type: string
  component_count: number
  last_updated: string
}

interface CommodityDetails {
  asset_id: number
  category: string
  unit: string
  last_updated: string
}

interface AssetPriceHistory {
  asset_id: number
  symbol: string
  price: number
  volume: number
  timestamp: string
}

interface CompleteAsset {
  asset: Asset
  stock_details?: StockDetails
  crypto_details?: CryptoDetails
  index_details?: IndexDetails
  commodity_details?: CommodityDetails
  recent_prices: AssetPriceHistory[]
}

export default function AssetDetailPage() {
  const params = useParams()
  const router = useRouter()
  const assetId = params.id as string

  const [assetData, setAssetData] = useState<CompleteAsset | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [trend] = useState<{ direction: 'up' | 'down', percentage: number }>({
    direction: Math.random() > 0.5 ? 'up' : 'down',
    percentage: Number((Math.random() * 10).toFixed(2))
  })

  // Generate rich mock data for demonstration
  const generateRichData = (asset: Asset) => {
    const basePrice = asset.price
    return {
      // Common metrics
      dayHigh: basePrice * (1 + Math.random() * 0.1),
      dayLow: basePrice * (1 - Math.random() * 0.1),
      avgVolume: asset.volume * (0.8 + Math.random() * 0.4),
      
      // Stock specific
      peRatio: 15 + Math.random() * 20,
      dividendYield: Math.random() * 8,
      eps: basePrice / (15 + Math.random() * 20),
      beta: 0.5 + Math.random() * 1.5,
      roe: 10 + Math.random() * 25,
      
      // Crypto specific
      athPrice: basePrice * (2 + Math.random() * 8),
      atlPrice: basePrice * (0.1 + Math.random() * 0.4),
      dominance: Math.random() * 10,
      
      // Index specific
      ytdReturn: (Math.random() - 0.5) * 40,
      volatility: 10 + Math.random() * 20,
      sharpeRatio: Math.random() * 2,
      
      // Commodity specific
      futures: basePrice * (1 + (Math.random() - 0.5) * 0.1),
      inventoryLevel: 70 + Math.random() * 30,
      seasonalTrend: Math.random() > 0.5 ? 'Alta' : 'Baixa'
    }
  }

  // Fetch complete asset data
  const fetchAssetData = async () => {
    try {
      setLoading(true)
      setError(null)

      const response = await fetch(`http://localhost:8080/api/v1/assets/${assetId}/complete`)
      
      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Ativo não encontrado')
        }
        throw new Error('Erro ao carregar dados do ativo')
      }
      
      const data = await response.json()
      setAssetData(data)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido')
      setAssetData(null)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (assetId) {
      fetchAssetData()
    }
  }, [assetId])

  if (loading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900 flex items-center justify-center">
        <div className="text-center">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
          <p className="text-gray-400 mt-4">A carregar dados do ativo...</p>
        </div>
      </div>
    )
  }

  if (error || !assetData) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900 flex items-center justify-center">
        <div className="text-center px-6">
          <Package className="h-16 w-16 text-gray-400 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-white mb-4">Ativo não encontrado</h2>
          <p className="text-gray-400 mb-8">{error}</p>
          <div className="flex gap-4 justify-center">
            <Button onClick={() => router.back()} variant="outline" className="border-gray-600 text-gray-300">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <Button onClick={fetchAssetData} className="bg-blue-600 hover:bg-blue-700">
              Tentar Novamente
            </Button>
          </div>
        </div>
      </div>
    )
  }

  const { asset } = assetData
  const Icon = getAssetTypeIcon(asset.asset_type)
  const richData = generateRichData(asset)

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      {/* Navbar */}
      <Navbar />

      {/* Header */}
      <div className="bg-gray-900/95 backdrop-blur-sm border-b border-blue-800/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex items-center justify-between">
            <Button 
              onClick={() => router.back()}
              variant="ghost" 
              className="text-gray-300 hover:text-white"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar aos Ativos
            </Button>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Asset Header */}
        <div className="mb-8">
          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader className="pb-6">
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-4">
                  <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-full w-16 h-16 flex items-center justify-center">
                    <Icon className="h-8 w-8 text-blue-400" />
                  </div>
                  <div>
                    <div className="flex items-center gap-3 mb-2">
                      <h1 className="text-3xl font-bold text-white">{asset.symbol}</h1>
                      <Badge 
                        variant="outline"
                        className={getAssetTypeBadge(asset.asset_type)}
                      >
                        {asset.asset_type}
                      </Badge>
                    </div>
                    <p className="text-gray-400 text-lg">{asset.name}</p>
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="flex items-center gap-2 mb-2">
                    <span className="text-3xl font-bold text-white">
                      {formatCurrency(asset.price)}
                    </span>
                    <TrendIndicator 
                      direction={trend.direction}
                      percentage={trend.percentage}
                      size="lg"
                    />
                  </div>
                  <p className="text-gray-400 text-sm">
                    Atualizado: {new Date(asset.last_updated).toLocaleString('pt-PT')}
                  </p>
                </div>
              </div>
            </CardHeader>
          </Card>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Details and Chart */}
          <div className="lg:col-span-2 space-y-6">
            {/* Asset-Specific Details - MOVED TO TOP */}
            <Tabs defaultValue="details" className="w-full">
              <TabsList className="grid w-full grid-cols-3 bg-gray-800/50">
                <TabsTrigger value="details" className="data-[state=active]:bg-blue-600">
                  Detalhes Específicos
                </TabsTrigger>
                <TabsTrigger value="metrics" className="data-[state=active]:bg-blue-600">
                  Métricas Avançadas
                </TabsTrigger>
                <TabsTrigger value="history" className="data-[state=active]:bg-blue-600">
                  Histórico de Preços
                </TabsTrigger>
              </TabsList>
              
              <TabsContent value="details" className="mt-6">
                <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                  <CardHeader>
                    <CardTitle className="text-white flex items-center gap-2">
                      <Info className="h-5 w-5 text-blue-400" />
                      Informações Específicas - {asset.asset_type}
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    {/* Stock Details */}
                    {asset.asset_type === 'Stock' && assetData.stock_details && (
                      <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Setor</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Building2 className="h-4 w-4 text-blue-400" />
                              {assetData.stock_details.sector}
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">País</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Globe className="h-4 w-4 text-blue-400" />
                              {assetData.stock_details.country}
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Cap. de Mercado</div>
                            <div className="text-white font-medium">
                              {formatCurrency(assetData.stock_details.market_cap)}
                            </div>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                          <div className="text-center p-3 bg-green-500/10 rounded-lg border border-green-500/20">
                            <div className="text-green-400 text-lg font-bold">
                              {richData.peRatio.toFixed(1)}
                            </div>
                            <div className="text-gray-400 text-xs">P/E Ratio</div>
                          </div>
                          <div className="text-center p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
                            <div className="text-blue-400 text-lg font-bold">
                              {richData.dividendYield.toFixed(2)}%
                            </div>
                            <div className="text-gray-400 text-xs">Dividend Yield</div>
                          </div>
                          <div className="text-center p-3 bg-purple-500/10 rounded-lg border border-purple-500/20">
                            <div className="text-purple-400 text-lg font-bold">
                              {formatCurrency(richData.eps)}
                            </div>
                            <div className="text-gray-400 text-xs">EPS</div>
                          </div>
                          <div className="text-center p-3 bg-orange-500/10 rounded-lg border border-orange-500/20">
                            <div className="text-orange-400 text-lg font-bold">
                              {richData.beta.toFixed(2)}
                            </div>
                            <div className="text-gray-400 text-xs">Beta</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Crypto Details */}
                    {asset.asset_type === 'Cryptocurrency' && assetData.crypto_details && (
                      <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Blockchain</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Zap className="h-4 w-4 text-orange-400" />
                              {assetData.crypto_details.blockchain}
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Dominância</div>
                            <div className="text-white font-medium">
                              {richData.dominance.toFixed(2)}%
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Fornecimento Total</div>
                            <div className="text-white font-medium">
                              {assetData.crypto_details.max_supply 
                                ? formatLargeNumber(assetData.crypto_details.max_supply)
                                : 'Ilimitado'
                              }
                            </div>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                          <div>
                            <div className="text-gray-400 text-sm mb-2">Fornecimento</div>
                            <div className="space-y-3">
                              <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                                <span className="text-gray-300">Máximo</span>
                                <span className="text-white font-medium">
                                  {assetData.crypto_details.max_supply 
                                    ? formatLargeNumber(assetData.crypto_details.max_supply)
                                    : 'Ilimitado'
                                  }
                                </span>
                              </div>
                              <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                                <span className="text-gray-300">Circulante</span>
                                <span className="text-white font-medium">
                                  {formatLargeNumber(assetData.crypto_details.circulating_supply)}
                                </span>
                              </div>
                            </div>
                          </div>
                          <div>
                            <div className="text-gray-400 text-sm mb-2">Preços Históricos</div>
                            <div className="space-y-3">
                              <div className="flex justify-between items-center p-3 bg-green-500/10 rounded border border-green-500/20">
                                <span className="text-gray-300">ATH</span>
                                <span className="text-green-400 font-medium">
                                  {formatCurrency(richData.athPrice)}
                                </span>
                              </div>
                              <div className="flex justify-between items-center p-3 bg-red-500/10 rounded border border-red-500/20">
                                <span className="text-gray-300">ATL</span>
                                <span className="text-red-400 font-medium">
                                  {formatCurrency(richData.atlPrice)}
                                </span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Index Details */}
                    {asset.asset_type === 'Index' && assetData.index_details && (
                      <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Região</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Globe className="h-4 w-4 text-blue-400" />
                              {assetData.index_details.region}
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Tipo de Índice</div>
                            <div className="text-white font-medium">{assetData.index_details.index_type}</div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Componentes</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Users className="h-4 w-4 text-blue-400" />
                              {assetData.index_details.component_count}
                            </div>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                          <div className="text-center p-3 bg-green-500/10 rounded-lg border border-green-500/20">
                            <div className={`text-lg font-bold ${richData.ytdReturn >= 0 ? 'text-green-400' : 'text-red-400'}`}>
                              {richData.ytdReturn >= 0 ? '+' : ''}{richData.ytdReturn.toFixed(1)}%
                            </div>
                            <div className="text-gray-400 text-xs">Retorno YTD</div>
                          </div>
                          <div className="text-center p-3 bg-blue-500/10 rounded-lg border border-blue-500/20">
                            <div className="text-blue-400 text-lg font-bold">
                              {richData.volatility.toFixed(1)}%
                            </div>
                            <div className="text-gray-400 text-xs">Volatilidade</div>
                          </div>
                          <div className="text-center p-3 bg-purple-500/10 rounded-lg border border-purple-500/20">
                            <div className="text-purple-400 text-lg font-bold">
                              {richData.sharpeRatio.toFixed(2)}
                            </div>
                            <div className="text-gray-400 text-xs">Sharpe Ratio</div>
                          </div>
                          <div className="text-center p-3 bg-orange-500/10 rounded-lg border border-orange-500/20">
                            <div className="text-orange-400 text-lg font-bold">
                              {assetData.index_details.component_count}
                            </div>
                            <div className="text-gray-400 text-xs">Holdings</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Commodity Details */}
                    {asset.asset_type === 'Commodity' && assetData.commodity_details && (
                      <div className="space-y-6">
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Categoria</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              <Package className="h-4 w-4 text-blue-400" />
                              {assetData.commodity_details.category}
                            </div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Unidade</div>
                            <div className="text-white font-medium">{assetData.commodity_details.unit}</div>
                          </div>
                          <div className="bg-gray-700/30 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-1">Tendência Sazonal</div>
                            <div className="text-white font-medium flex items-center gap-2">
                              {richData.seasonalTrend === 'Alta' ? 
                                <TrendingUp className="h-4 w-4 text-green-400" /> : 
                                <TrendingDown className="h-4 w-4 text-red-400" />
                              }
                              {richData.seasonalTrend}
                            </div>
                          </div>
                        </div>
                        
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                          <div className="bg-gray-700/20 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-2">Preço Futuro</div>
                            <div className="text-white text-xl font-bold">
                              {formatCurrency(richData.futures)}
                            </div>
                            <div className="text-gray-500 text-xs mt-1">Contrato próximo mês</div>
                          </div>
                          <div className="bg-gray-700/20 p-4 rounded-lg">
                            <div className="text-gray-400 text-sm mb-2">Nível de Inventário</div>
                            <div className="text-white text-xl font-bold">
                              {richData.inventoryLevel.toFixed(0)}%
                            </div>
                            <div className="text-gray-500 text-xs mt-1">Da capacidade total</div>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* No specific details available */}
                    {!assetData.stock_details && !assetData.crypto_details && !assetData.index_details && !assetData.commodity_details && (
                      <div className="text-center py-8">
                        <Info className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                        <p className="text-gray-400">Detalhes específicos não disponíveis para este ativo.</p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </TabsContent>

              <TabsContent value="metrics" className="mt-6">
                <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                  <CardHeader>
                    <CardTitle className="text-white flex items-center gap-2">
                      <Activity className="h-5 w-5 text-blue-400" />
                      Métricas de Performance
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div>
                        <h4 className="text-white font-semibold mb-4">Preços (Hoje)</h4>
                        <div className="space-y-3">
                          <div className="flex justify-between items-center p-3 bg-blue-500/10 rounded border border-blue-500/20">
                            <span className="text-gray-300">Hoje - Máximo</span>
                            <span className="text-blue-400 font-bold">{formatCurrency(richData.dayHigh)}</span>
                          </div>
                          <div className="flex justify-between items-center p-3 bg-blue-500/10 rounded border border-blue-500/20">
                            <span className="text-gray-300">Hoje - Mínimo</span>
                            <span className="text-blue-400 font-bold">{formatCurrency(richData.dayLow)}</span>
                          </div>
                          <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                            <span className="text-gray-300">Preço Atual</span>
                            <span className="text-white font-bold">{formatCurrency(asset.price)}</span>
                          </div>
                        </div>
                      </div>
                      
                      <div>
                        <h4 className="text-white font-semibold mb-4">Volume & Atividade</h4>
                        <div className="space-y-3">
                          <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                            <span className="text-gray-300">Volume Atual</span>
                            <span className="text-white font-bold">{formatLargeNumber(asset.volume)}</span>
                          </div>
                          <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                            <span className="text-gray-300">Volume Médio</span>
                            <span className="text-white font-bold">{formatLargeNumber(richData.avgVolume)}</span>
                          </div>
                          <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                            <span className="text-gray-300">Relação Vol/Avg</span>
                            <span className={`font-bold ${asset.volume > richData.avgVolume ? 'text-green-400' : 'text-red-400'}`}>
                              {((asset.volume / richData.avgVolume) * 100).toFixed(0)}%
                            </span>
                          </div>
                          <div className="flex justify-between items-center p-3 bg-gray-700/20 rounded">
                            <span className="text-gray-300">Liquidez</span>
                            <Badge className={asset.volume > richData.avgVolume ? 'bg-green-500/20 text-green-400' : 'bg-orange-500/20 text-orange-400'}>
                              {asset.volume > richData.avgVolume ? 'Alta' : 'Moderada'}
                            </Badge>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </TabsContent>

              <TabsContent value="history" className="mt-6">
                <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
                  <CardHeader>
                    <CardTitle className="text-white flex items-center gap-2">
                      <Calendar className="h-5 w-5 text-blue-400" />
                      Histórico de Preços Recente
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    {assetData.recent_prices.length > 0 ? (
                      <div className="space-y-3">
                        {assetData.recent_prices.slice(0, 10).map((pricePoint, index) => (
                          <div key={index} className="flex justify-between items-center p-3 bg-gray-700/30 rounded-lg hover:bg-gray-700/50 transition-colors">
                            <div>
                              <div className="text-white font-medium">
                                {formatCurrency(pricePoint.price)}
                              </div>
                              <div className="text-gray-400 text-sm">
                                Volume: {formatLargeNumber(pricePoint.volume)}
                              </div>
                            </div>
                            <div className="text-right">
                              <div className="text-gray-400 text-sm">
                                {new Date(pricePoint.timestamp).toLocaleDateString('pt-PT')}
                              </div>
                              <div className="text-gray-500 text-xs">
                                {new Date(pricePoint.timestamp).toLocaleTimeString('pt-PT')}
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <div className="text-center py-8">
                        <Calendar className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                        <p className="text-gray-400">Nenhum histórico de preços disponível.</p>
                      </div>
                    )}
                  </CardContent>
                </Card>
              </TabsContent>
            </Tabs>

            {/* Interactive Price Chart */}
            <PriceChart 
              priceHistory={assetData.recent_prices} 
              symbol={asset.symbol}
            />

            {/* Basic Stats */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white flex items-center gap-2">
                  <Activity className="h-5 w-5 text-blue-400" />
                  Estatísticas Básicas
                </CardTitle>
              </CardHeader>
              <CardContent className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="text-center">
                  <div className="text-2xl font-bold text-white mb-1">
                    {formatLargeNumber(asset.volume)}
                  </div>
                  <div className="text-gray-400 text-sm">Volume</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-white mb-1">
                    {formatLargeNumber(asset.available_shares)}
                  </div>
                  <div className="text-gray-400 text-sm">Ações Disponíveis</div>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-blue-400 mb-1">
                    {assetData.recent_prices.length}
                  </div>
                  <div className="text-gray-400 text-sm">Registos de Preço</div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Right Column - Summary */}
          <div className="space-y-6">
            {/* Performance Summary */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white text-lg">Resumo de Performance</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Preço Atual</span>
                  <span className="text-white font-semibold">{formatCurrency(asset.price)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Tendência</span>
                  <TrendIndicator 
                    direction={trend.direction}
                    percentage={trend.percentage}
                    size="sm"
                  />
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Volume Total</span>
                  <span className="text-white">{formatLargeNumber(asset.volume)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Último Update</span>
                  <span className="text-white text-sm">
                    {new Date(asset.last_updated).toLocaleDateString('pt-PT')}
                  </span>
                </div>
              </CardContent>
            </Card>

            {/* Market Information */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white text-lg">Informações de Mercado</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Tipo de Ativo</span>
                  <Badge 
                    variant="outline"
                    className={getAssetTypeBadge(asset.asset_type)}
                  >
                    {asset.asset_type}
                  </Badge>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Ações Disponíveis</span>
                  <span className="text-white">{formatLargeNumber(asset.available_shares)}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Registos Históricos</span>
                  <span className="text-white">{assetData.recent_prices.length}</span>
                </div>
              </CardContent>
            </Card>

            {/* Risk Assessment */}
            <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
              <CardHeader>
                <CardTitle className="text-white text-lg flex items-center gap-2">
                  <Shield className="h-5 w-5 text-blue-400" />
                  Avaliação de Risco
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Volatilidade</span>
                  <Badge className="bg-orange-500/20 text-orange-400">
                    {richData.volatility.toFixed(1)}%
                  </Badge>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Liquidez</span>
                  <Badge className={asset.volume > richData.avgVolume ? 'bg-green-500/20 text-green-400' : 'bg-yellow-500/20 text-yellow-400'}>
                    {asset.volume > richData.avgVolume ? 'Alta' : 'Moderada'}
                  </Badge>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-gray-400">Risco Geral</span>
                  <Badge className="bg-blue-500/20 text-blue-400">
                    {richData.volatility > 20 ? 'Alto' : richData.volatility > 10 ? 'Moderado' : 'Baixo'}
                  </Badge>
                </div>
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
} 