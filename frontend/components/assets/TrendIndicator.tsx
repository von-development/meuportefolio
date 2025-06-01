'use client'

import { TrendingUp, TrendingDown } from 'lucide-react'

interface TrendIndicatorProps {
  direction: 'up' | 'down'
  percentage: number
  size?: 'sm' | 'md' | 'lg'
}

export default function TrendIndicator({ direction, percentage, size = 'md' }: TrendIndicatorProps) {
  const TrendIcon = direction === 'up' ? TrendingUp : TrendingDown
  const trendColor = direction === 'up' ? 'text-green-400' : 'text-red-400'
  
  const sizeClasses = {
    sm: 'h-3 w-3',
    md: 'h-4 w-4', 
    lg: 'h-5 w-5'
  }
  
  const textSizeClasses = {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-lg'
  }

  return (
    <div className={`flex items-center gap-1 ${trendColor}`}>
      <TrendIcon className={sizeClasses[size]} />
      <span className={`${textSizeClasses[size]} font-medium`}>
        {percentage}%
      </span>
    </div>
  )
} 