'use client'

import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Area, AreaChart } from 'recharts'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { TrendingUp } from 'lucide-react'
import { formatCurrency, AssetPriceHistory } from './AssetTypeUtils'

interface PriceChartProps {
  priceHistory: AssetPriceHistory[]
  symbol: string
}

export default function PriceChart({ priceHistory, symbol }: PriceChartProps) {
  // Transform data for the chart
  const chartData = priceHistory.map((item, index) => {
    const date = new Date(item.timestamp)
    
    // Skip invalid dates
    if (isNaN(date.getTime())) {
      console.warn(`⚠️ Invalid date found: ${item.timestamp}`)
      return null
    }
    
    return {
      date: date.toLocaleDateString('pt-PT', { 
        month: 'short', 
        day: 'numeric',
        year: date.getFullYear() !== new Date().getFullYear() ? 'numeric' : undefined
      }),
      price: item.price,
      volume: item.volume,
      fullDate: date.toLocaleDateString('pt-PT'),
      timestamp: item.timestamp,
      index
    }
  }).filter(item => item !== null) // Remove any null entries from invalid dates

  // Custom tooltip component
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload
      return (
        <div className="bg-gray-800/95 backdrop-blur-sm border border-blue-500/30 rounded-lg p-3 shadow-lg">
          <p className="text-white font-medium mb-1">{data.fullDate}</p>
          <div className="space-y-1">
            <p className="text-blue-400">
              Preço: <span className="text-white font-semibold">{formatCurrency(data.price)}</span>
            </p>
            <p className="text-gray-400 text-sm">
              Volume: <span className="text-white">{data.volume.toLocaleString('pt-PT')}</span>
            </p>
          </div>
        </div>
      )
    }
    return null
  }

  // Calculate price trend
  const firstPrice = chartData[0]?.price || 0
  const lastPrice = chartData[chartData.length - 1]?.price || 0
  const priceChange = lastPrice - firstPrice
  const priceChangePercent = firstPrice !== 0 ? ((priceChange / firstPrice) * 100) : 0
  const isPositive = priceChange >= 0

  if (chartData.length === 0) {
    return (
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-blue-400" />
            Gráfico de Preços - {symbol}
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-12">
            <TrendingUp className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-400">Dados de preços insuficientes para exibir o gráfico.</p>
          </div>
        </CardContent>
      </Card>
    )
  }

  return (
    <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="text-white flex items-center gap-2">
            <TrendingUp className="h-5 w-5 text-blue-400" />
            Gráfico de Preços - {symbol}
          </CardTitle>
          <div className="text-right">
            <div className={`text-sm font-medium ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
              {isPositive ? '+' : ''}{formatCurrency(priceChange)} ({priceChangePercent.toFixed(2)}%)
            </div>
            <div className="text-xs text-gray-400">
              Variação do período ({chartData.length} pontos)
            </div>
          </div>
        </div>
      </CardHeader>
      <CardContent>
        <div className="h-80 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={chartData} margin={{ top: 10, right: 30, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="priceGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3}/>
                  <stop offset="95%" stopColor="#3B82F6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid 
                strokeDasharray="3 3" 
                stroke="#374151" 
                strokeOpacity={0.3}
              />
              <XAxis 
                dataKey="date" 
                stroke="#9CA3AF"
                fontSize={12}
                tickLine={false}
                axisLine={false}
                interval={Math.max(0, Math.floor(chartData.length / 8))} // Show max 8 labels
              />
              <YAxis 
                stroke="#9CA3AF"
                fontSize={12}
                tickLine={false}
                axisLine={false}
                tickFormatter={(value) => `€${value.toFixed(2)}`}
              />
              <Tooltip content={<CustomTooltip />} />
              <Area
                type="monotone"
                dataKey="price"
                stroke="#3B82F6"
                strokeWidth={2}
                fill="url(#priceGradient)"
                dot={{ fill: '#3B82F6', strokeWidth: 2, r: 4 }}
                activeDot={{ r: 6, fill: '#60A5FA', stroke: '#1E40AF', strokeWidth: 2 }}
              />
            </AreaChart>
          </ResponsiveContainer>
        </div>
        
        {/* Chart Footer Info */}
        <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t border-gray-700">
          <div className="text-center">
            <div className="text-lg font-bold text-white">
              {formatCurrency(Math.min(...chartData.map(d => d.price)))}
            </div>
            <div className="text-xs text-gray-400">Mínimo</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-bold text-white">
              {formatCurrency(Math.max(...chartData.map(d => d.price)))}
            </div>
            <div className="text-xs text-gray-400">Máximo</div>
          </div>
          <div className="text-center">
            <div className="text-lg font-bold text-white">
              {formatCurrency(chartData.reduce((sum, d) => sum + d.price, 0) / chartData.length)}
            </div>
            <div className="text-xs text-gray-400">Média</div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
} 