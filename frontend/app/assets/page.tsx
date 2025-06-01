'use client'

import { useState, useEffect } from 'react'
import { Package } from 'lucide-react'
import { Button } from '@/components/ui/button'
import Navbar from '@/components/layout/Navbar'
import AssetFilters from '@/components/assets/AssetFilters'
import AssetCard from '@/components/assets/AssetCard'
import { Asset, AssetWithTrend, generateTrendData } from '@/components/assets/AssetTypeUtils'

export default function AssetsPage() {
  const [assets, setAssets] = useState<AssetWithTrend[]>([])
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')
  const [selectedAssetType, setSelectedAssetType] = useState('')
  const [error, setError] = useState<string | null>(null)

  // Fetch assets based on filters
  const fetchAssets = async (query: string = '', assetType: string = '') => {
    try {
      setLoading(true)
      setError(null)
      
      const params = new URLSearchParams()
      if (query.trim()) params.append('query', query.trim())
      if (assetType) params.append('asset_type', assetType)
      
      const url = `http://localhost:8080/api/v1/assets${params.toString() ? `?${params.toString()}` : ''}`
      const response = await fetch(url)
      
      if (!response.ok) {
        throw new Error('Erro ao carregar ativos')
      }
      
      const data = await response.json()
      const assetsWithTrend = generateTrendData(data)
      setAssets(assetsWithTrend)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erro desconhecido')
      setAssets([])
    } finally {
      setLoading(false)
    }
  }

  // Initial load
  useEffect(() => {
    fetchAssets()
  }, [])

  // Handle search
  const handleSearch = () => {
    fetchAssets(searchQuery, selectedAssetType)
  }

  // Handle filter change
  const handleFilterChange = (assetType: string) => {
    setSelectedAssetType(assetType)
    fetchAssets(searchQuery, assetType)
  }

  // Handle search query change
  const handleSearchChange = (query: string) => {
    setSearchQuery(query)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      {/* Navbar */}
      <Navbar />

      {/* Header */}
      <div className="bg-gray-900/95 backdrop-blur-sm border-b border-blue-800/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="text-center">
            <h1 className="text-4xl md:text-5xl font-bold text-white mb-4">
              Explorar <span className="text-blue-400">Ativos</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-3xl mx-auto">
              Descubra e analise uma vasta gama de ativos de investimento
            </p>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Search and Filters */}
        <AssetFilters
          searchQuery={searchQuery}
          selectedAssetType={selectedAssetType}
          onSearchChange={handleSearchChange}
          onSearch={handleSearch}
          onFilterChange={handleFilterChange}
        />

        {/* Loading State */}
        {loading && (
          <div className="text-center py-12">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
            <p className="text-gray-400 mt-4">A carregar ativos...</p>
          </div>
        )}

        {/* Error State */}
        {error && (
          <div className="text-center py-12">
            <p className="text-red-400 mb-4">{error}</p>
            <Button 
              onClick={() => fetchAssets(searchQuery, selectedAssetType)}
              variant="outline"
              className="border-gray-600 text-gray-300 hover:bg-gray-800/50"
            >
              Tentar Novamente
            </Button>
          </div>
        )}

        {/* Assets Grid */}
        {!loading && !error && (
          <>
            {assets.length === 0 ? (
              <div className="text-center py-12">
                <Package className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                <p className="text-gray-400 text-lg">Nenhum ativo encontrado</p>
                <p className="text-gray-500 text-sm mt-2">
                  Tente ajustar os filtros ou termos de pesquisa
                </p>
              </div>
            ) : (
              <>
                <div className="flex justify-between items-center mb-6">
                  <p className="text-gray-400">
                    {assets.length} ativo{assets.length !== 1 ? 's' : ''} encontrado{assets.length !== 1 ? 's' : ''}
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  {assets.map((asset) => (
                    <AssetCard key={asset.asset_id} asset={asset} />
                  ))}
                </div>
              </>
            )}
          </>
        )}
      </div>
    </div>
  )
} 