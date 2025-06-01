'use client'

import { useRouter } from 'next/navigation'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import TrendIndicator from './TrendIndicator'
import { 
  AssetWithTrend, 
  getAssetTypeIcon, 
  getAssetTypeBadge, 
  formatCurrency, 
  formatVolume 
} from './AssetTypeUtils'

interface AssetCardProps {
  asset: AssetWithTrend
}

export default function AssetCard({ asset }: AssetCardProps) {
  const router = useRouter()
  const Icon = getAssetTypeIcon(asset.asset_type)

  const handleAssetClick = () => {
    router.push(`/assets/${asset.asset_id}`)
  }

  return (
    <Card 
      onClick={handleAssetClick}
      className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40 hover:border-blue-500/60 transition-all duration-300 hover:scale-105 cursor-pointer group"
    >
      <CardHeader className="pb-4">
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-gradient-to-br from-blue-500/20 to-blue-600/20 rounded-full w-12 h-12 flex items-center justify-center group-hover:scale-110 transition-transform duration-300">
              <Icon className="h-6 w-6 text-blue-400" />
            </div>
            <div>
              <CardTitle className="text-white text-lg group-hover:text-blue-400 transition-colors">
                {asset.symbol}
              </CardTitle>
              <p className="text-gray-400 text-sm truncate max-w-[150px]">
                {asset.name}
              </p>
            </div>
          </div>
          <div className="flex flex-col items-end gap-2">
            <Badge 
              variant="outline"
              className={`text-xs ${getAssetTypeBadge(asset.asset_type)}`}
            >
              {asset.asset_type}
            </Badge>
            <TrendIndicator 
              direction={asset.trend}
              percentage={asset.trendPercentage}
              size="sm"
            />
          </div>
        </div>
      </CardHeader>
      
      <CardContent className="pt-0">
        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-gray-400 text-sm">Preço</span>
            <span className="text-white font-semibold">
              {formatCurrency(asset.price)}
            </span>
          </div>
          
          <div className="flex justify-between items-center">
            <span className="text-gray-400 text-sm">Volume</span>
            <span className="text-gray-300">
              {formatVolume(asset.volume)}
            </span>
          </div>
          
          <div className="flex justify-between items-center">
            <span className="text-gray-400 text-sm">Ações Disponíveis</span>
            <span className="text-gray-300">
              {formatVolume(asset.available_shares)}
            </span>
          </div>
          
          <div className="pt-2 border-t border-gray-700">
            <p className="text-xs text-gray-500">
              Actualizado: {new Date(asset.last_updated).toLocaleDateString('pt-PT')}
            </p>
          </div>
        </div>
      </CardContent>
    </Card>
  )
} 