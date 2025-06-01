'use client'

import { Search } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { assetTypeFilters } from './AssetTypeUtils'

interface AssetFiltersProps {
  searchQuery: string
  selectedAssetType: string
  onSearchChange: (query: string) => void
  onSearch: () => void
  onFilterChange: (assetType: string) => void
}

export default function AssetFilters({
  searchQuery,
  selectedAssetType,
  onSearchChange,
  onSearch,
  onFilterChange
}: AssetFiltersProps) {
  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      onSearch()
    }
  }

  return (
    <div className="mb-8">
      {/* Search Bar */}
      <div className="flex gap-4 mb-6">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
          <Input
            placeholder="Pesquisar por símbolo ou nome..."
            value={searchQuery}
            onChange={(e) => onSearchChange(e.target.value)}
            onKeyPress={handleKeyPress}
            className="pl-10 bg-gray-800/50 border-gray-600 text-white placeholder-gray-400 focus:border-blue-500"
          />
        </div>
        <Button 
          onClick={onSearch}
          className="bg-blue-600 hover:bg-blue-700 text-white px-8"
        >
          <Search className="h-4 w-4 mr-2" />
          Pesquisar
        </Button>
      </div>

      {/* Asset Type Filters */}
      <div className="flex flex-wrap gap-3">
        {assetTypeFilters.map((filter) => {
          const Icon = filter.icon
          return (
            <Button
              key={filter.value}
              variant={selectedAssetType === filter.value ? "default" : "outline"}
              onClick={() => onFilterChange(filter.value)}
              className={`flex items-center gap-2 ${
                selectedAssetType === filter.value
                  ? 'bg-blue-600 hover:bg-blue-700 text-white'
                  : 'bg-transparent border-gray-600 text-gray-300 hover:bg-gray-800/50 hover:text-white'
              }`}
            >
              <Icon className="h-4 w-4" />
              {filter.label}
            </Button>
          )
        })}
      </div>
    </div>
  )
} 