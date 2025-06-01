import { Building2, Coins, BarChart3, Package, TrendingUp } from 'lucide-react'

export interface Asset {
  asset_id: number
  name: string
  symbol: string
  asset_type: string
  price: number
  volume: number
  available_shares: number
  last_updated: string
}

export interface AssetWithTrend extends Asset {
  trend: 'up' | 'down'
  trendPercentage: number
}

// Enhanced asset interface for the detailed view
export interface EnhancedAsset extends Asset {
  category_info?: string
  additional_info?: string
  market_metric?: number
  price_30_days_ago?: number
  total_quantity_held?: number
  total_portfolios_holding?: number
}

// Price history interface matching backend
export interface AssetPriceHistory {
  asset_id: number
  symbol: string
  price: number
  volume: number
  timestamp: string
  // Optional fields from enhanced view
  open_price?: number
  high_price?: number
  low_price?: number
  daily_change_percent?: number
  daily_change_amount?: number
}

// Asset type filter configuration
export const assetTypeFilters = [
  { value: '', label: 'Todos os Ativos', icon: Package },
  { value: 'Stock', label: 'Ações', icon: Building2 },
  { value: 'Cryptocurrency', label: 'Criptomoedas', icon: Coins },
  { value: 'Index', label: 'Índices', icon: BarChart3 },
  { value: 'Commodity', label: 'Commodities', icon: TrendingUp },
]

// Get asset type icon
export const getAssetTypeIcon = (assetType: string) => {
  const iconMap = {
    'Stock': Building2,
    'Cryptocurrency': Coins,
    'Index': BarChart3,
    'Commodity': Package,
  }
  return iconMap[assetType as keyof typeof iconMap] || Package
}

// Get asset type badge color classes
export const getAssetTypeBadge = (assetType: string) => {
  const colors = {
    'Stock': 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    'Cryptocurrency': 'bg-orange-500/20 text-orange-400 border-orange-500/30',
    'Index': 'bg-green-500/20 text-green-400 border-green-500/30',
    'Commodity': 'bg-purple-500/20 text-purple-400 border-purple-500/30',
  }
  return colors[assetType as keyof typeof colors] || 'bg-gray-500/20 text-gray-400 border-gray-500/30'
}

// Format currency for Portuguese locale
export const formatCurrency = (value: number) => {
  return new Intl.NumberFormat('pt-PT', {
    style: 'currency',
    currency: 'EUR',
    minimumFractionDigits: 2,
    maximumFractionDigits: 4,
  }).format(value)
}

// Format large numbers with K/M/B suffixes
export const formatLargeNumber = (value: number) => {
  if (value >= 1000000000) {
    return `${(value / 1000000000).toFixed(1)}B`
  } else if (value >= 1000000) {
    return `${(value / 1000000).toFixed(1)}M`
  } else if (value >= 1000) {
    return `${(value / 1000).toFixed(1)}K`
  }
  return value.toString()
}

// Format volume with appropriate suffixes
export const formatVolume = (volume: number) => {
  if (volume >= 1000000) {
    return `${(volume / 1000000).toFixed(1)}M`
  } else if (volume >= 1000) {
    return `${(volume / 1000).toFixed(1)}K`
  }
  return volume.toString()
}

// Calculate trend from price history (instead of random data)
export const calculateTrendFromHistory = (priceHistory: AssetPriceHistory[]): { direction: 'up' | 'down', percentage: number } => {
  if (priceHistory.length < 2) {
    return { direction: 'up', percentage: 0 }
  }
  
  // Get first and last prices (chronological order)
  const firstPrice = priceHistory[0].price
  const lastPrice = priceHistory[priceHistory.length - 1].price
  
  const change = lastPrice - firstPrice
  const percentage = firstPrice !== 0 ? Math.abs((change / firstPrice) * 100) : 0
  
  return {
    direction: change >= 0 ? 'up' : 'down',
    percentage: Number(percentage.toFixed(2))
  }
}

// Generate trend data - improved version that can use real data when available
export const generateTrendData = (assets: Asset[], priceHistoryMap?: Map<number, AssetPriceHistory[]>): AssetWithTrend[] => {
  return assets.map(asset => {
    // If we have real price history, use it to calculate trend
    if (priceHistoryMap && priceHistoryMap.has(asset.asset_id)) {
      const history = priceHistoryMap.get(asset.asset_id)!
      const trend = calculateTrendFromHistory(history)
      return {
        ...asset,
        trend: trend.direction,
        trendPercentage: trend.percentage
      }
    }
    
    // Fallback to random data for demo purposes
    return {
      ...asset,
      trend: Math.random() > 0.5 ? 'up' : 'down' as 'up' | 'down',
      trendPercentage: Number((Math.random() * 10).toFixed(2))
    }
  })
} 