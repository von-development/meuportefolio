'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { assetApi, type Asset } from '@/lib/api/asset';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { 
  Search,
  Building2,
  TrendingUp,
  TrendingDown,
  DollarSign,
  BarChart3,
  Filter,
  RefreshCw,
  AlertTriangle,
  Eye,
  Activity,
  Coins
} from 'lucide-react';
import { formatCurrency, formatNumber } from '@/lib/utils';
import { toast } from 'sonner';

export function AssetsList() {
  const router = useRouter();
  const [allAssets, setAllAssets] = useState<Asset[]>([]);
  const [filteredAssets, setFilteredAssets] = useState<Asset[]>([]);
  const [companies, setCompanies] = useState<Asset[]>([]);
  const [indices, setIndices] = useState<Asset[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'company' | 'index' | 'cryptocurrency' | 'commodity'>('all');

  // Generate random price variation for each asset (-10% to +10%)
  const generatePriceVariation = (assetId: number) => {
    // Use asset ID as seed for consistent random values
    const seed = assetId * 12345;
    const random = (Math.sin(seed) * 10000) % 1;
    const variation = (Math.abs(random) * 20) - 10; // -10 to +10
    return parseFloat(variation.toFixed(2));
  };

  const getPriceVariationDisplay = (variation: number) => {
    const isPositive = variation >= 0;
    return {
      isPositive,
      color: isPositive ? 'text-green-400' : 'text-red-400',
      icon: isPositive ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />,
      text: `${isPositive ? '+' : ''}${variation.toFixed(2)}%`
    };
  };

  const fetchAssetsData = async () => {
    try {
      setLoading(true);
      setError(null);

      // API CALL: getAssets - Get all assets
      const assetsData = await assetApi.getAssets();
      setAllAssets(assetsData);
      setFilteredAssets(assetsData);

      // API CALL: getCompanies - Get company assets specifically
      const companiesData = await assetApi.getCompanies();
      setCompanies(companiesData);

      // API CALL: getIndices - Get index assets specifically
      const indicesData = await assetApi.getIndices();
      setIndices(indicesData);

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch assets'));
      toast.error('Erro ao carregar ativos');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAssetsData();
  }, []);

  // Filter and search logic
  useEffect(() => {
    let filtered = allAssets;

    // Apply type filter
    if (selectedFilter === 'company') {
      filtered = allAssets.filter(asset => asset.asset_type.toLowerCase() === 'company');
    } else if (selectedFilter === 'index') {
      filtered = allAssets.filter(asset => asset.asset_type.toLowerCase() === 'index');
    } else if (selectedFilter === 'cryptocurrency') {
      filtered = allAssets.filter(asset => asset.asset_type.toLowerCase() === 'cryptocurrency');
    } else if (selectedFilter === 'commodity') {
      filtered = allAssets.filter(asset => asset.asset_type.toLowerCase() === 'commodity');
    }

    // Apply search filter
    if (searchQuery.trim()) {
      filtered = filtered.filter(asset => 
        asset.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        asset.symbol.toLowerCase().includes(searchQuery.toLowerCase()) ||
        asset.asset_type.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }

    setFilteredAssets(filtered);
  }, [allAssets, searchQuery, selectedFilter]);

  const getAssetTypeIcon = (assetType: string) => {
    switch (assetType.toLowerCase()) {
      case 'company':
        return <Building2 className="h-4 w-4" />;
      case 'index':
        return <BarChart3 className="h-4 w-4" />;
      case 'cryptocurrency':
        return <Coins className="h-4 w-4" />;
      case 'commodity':
        return <Activity className="h-4 w-4" />;
      default:
        return <DollarSign className="h-4 w-4" />;
    }
  };

  const getAssetTypeColor = (assetType: string) => {
    switch (assetType.toLowerCase()) {
      case 'company':
        return 'bg-blue-600 text-white';
      case 'index':
        return 'bg-green-600 text-white';
      case 'cryptocurrency':
        return 'bg-yellow-600 text-white';
      case 'commodity':
        return 'bg-orange-600 text-white';
      default:
        return 'bg-purple-600 text-white';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-16">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-slate-400" />
          <span className="text-lg text-slate-300">Carregando ativos...</span>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-16">
        <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
        <h2 className="text-xl font-semibold mb-2 text-white">Erro ao carregar ativos</h2>
        <p className="text-slate-400 mb-4">{error.message}</p>
        <Button onClick={fetchAssetsData} className="bg-blue-600 hover:bg-blue-700">
          <RefreshCw className="h-4 w-4 mr-2" />
          Tentar novamente
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        <Card className="bg-slate-700/50 border-slate-600">
          <CardContent className="p-4 text-center">
            <div className="w-10 h-10 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-3">
              <BarChart3 className="h-5 w-5 text-white" />
            </div>
            <h3 className="font-semibold text-sm mb-1 text-white">Total</h3>
            <p className="text-2xl font-bold text-blue-400">{allAssets.length}</p>
            <div className="flex items-center justify-center gap-1 mt-1 text-green-400">
              <TrendingUp className="h-3 w-3" />
              <span className="text-xs">+2.4%</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-700/50 border-slate-600">
          <CardContent className="p-4 text-center">
            <div className="w-10 h-10 bg-green-600 rounded-xl flex items-center justify-center mx-auto mb-3">
              <Building2 className="h-5 w-5 text-white" />
            </div>
            <h3 className="font-semibold text-sm mb-1 text-white">Empresas</h3>
            <p className="text-2xl font-bold text-green-400">{companies.length}</p>
            <div className="flex items-center justify-center gap-1 mt-1 text-green-400">
              <TrendingUp className="h-3 w-3" />
              <span className="text-xs">+1.8%</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-700/50 border-slate-600">
          <CardContent className="p-4 text-center">
            <div className="w-10 h-10 bg-purple-600 rounded-xl flex items-center justify-center mx-auto mb-3">
              <TrendingUp className="h-5 w-5 text-white" />
            </div>
            <h3 className="font-semibold text-sm mb-1 text-white">Índices</h3>
            <p className="text-2xl font-bold text-purple-400">{indices.length}</p>
            <div className="flex items-center justify-center gap-1 mt-1 text-red-400">
              <TrendingDown className="h-3 w-3" />
              <span className="text-xs">-0.7%</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-700/50 border-slate-600">
          <CardContent className="p-4 text-center">
            <div className="w-10 h-10 bg-yellow-600 rounded-xl flex items-center justify-center mx-auto mb-3">
              <Coins className="h-5 w-5 text-white" />
            </div>
            <h3 className="font-semibold text-sm mb-1 text-white">Cripto</h3>
            <p className="text-2xl font-bold text-yellow-400">
              {allAssets.filter(a => a.asset_type.toLowerCase() === 'cryptocurrency').length}
            </p>
            <div className="flex items-center justify-center gap-1 mt-1 text-green-400">
              <TrendingUp className="h-3 w-3" />
              <span className="text-xs">+8.2%</span>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-700/50 border-slate-600">
          <CardContent className="p-4 text-center">
            <div className="w-10 h-10 bg-orange-600 rounded-xl flex items-center justify-center mx-auto mb-3">
              <Activity className="h-5 w-5 text-white" />
            </div>
            <h3 className="font-semibold text-sm mb-1 text-white">Commodities</h3>
            <p className="text-2xl font-bold text-orange-400">
              {allAssets.filter(a => a.asset_type.toLowerCase() === 'commodity').length}
            </p>
            <div className="flex items-center justify-center gap-1 mt-1 text-green-400">
              <TrendingUp className="h-3 w-3" />
              <span className="text-xs">+3.1%</span>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Search and Filter Controls */}
      <div className="flex flex-col sm:flex-row gap-4">
        {/* Search Input */}
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
          <Input
            placeholder="Buscar por nome, símbolo ou tipo..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="pl-10 bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500"
          />
        </div>

        {/* Filter Buttons */}
        <div className="flex gap-2">
          <Button
            variant={selectedFilter === 'all' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedFilter('all')}
            className={selectedFilter === 'all' ? 'bg-blue-600 hover:bg-blue-700' : 'border-slate-600 text-slate-300 hover:bg-slate-700'}
          >
            <Filter className="h-4 w-4 mr-2" />
            Todos
          </Button>
          <Button
            variant={selectedFilter === 'company' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedFilter('company')}
            className={selectedFilter === 'company' ? 'bg-blue-600 hover:bg-blue-700' : 'border-slate-600 text-slate-300 hover:bg-slate-700'}
          >
            <Building2 className="h-4 w-4 mr-2" />
            Empresas
          </Button>
          <Button
            variant={selectedFilter === 'index' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedFilter('index')}
            className={selectedFilter === 'index' ? 'bg-blue-600 hover:bg-blue-700' : 'border-slate-600 text-slate-300 hover:bg-slate-700'}
          >
            <BarChart3 className="h-4 w-4 mr-2" />
            Índices
          </Button>
          <Button
            variant={selectedFilter === 'cryptocurrency' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedFilter('cryptocurrency')}
            className={selectedFilter === 'cryptocurrency' ? 'bg-yellow-600 hover:bg-yellow-700' : 'border-slate-600 text-slate-300 hover:bg-slate-700'}
          >
            <Coins className="h-4 w-4 mr-2" />
            Criptomoedas
          </Button>
          <Button
            variant={selectedFilter === 'commodity' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedFilter('commodity')}
            className={selectedFilter === 'commodity' ? 'bg-orange-600 hover:bg-orange-700' : 'border-slate-600 text-slate-300 hover:bg-slate-700'}
          >
            <Activity className="h-4 w-4 mr-2" />
            Commodities
          </Button>
        </div>
      </div>

      {/* Results Info */}
      <div className="flex items-center justify-between">
        <p className="text-slate-400">
          Mostrando {filteredAssets.length} de {allAssets.length} ativos
          {searchQuery && (
            <span className="ml-2 text-blue-400">
              para "{searchQuery}"
            </span>
          )}
        </p>
      </div>

      {/* Assets Grid */}
      {filteredAssets.length === 0 ? (
        <div className="text-center py-12">
          <Search className="h-12 w-12 text-slate-600 mx-auto mb-4" />
          <p className="text-slate-400 text-lg">Nenhum ativo encontrado</p>
          <p className="text-slate-500 text-sm mt-1">
            Tente ajustar os filtros ou termos de busca
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredAssets.map((asset) => (
            <Card 
              key={asset.asset_id} 
              className="bg-slate-800 border-slate-700 hover:bg-slate-750 transition-all duration-200 cursor-pointer"
              onClick={() => router.push(`/assets/${asset.asset_id}`)}
            >
              <CardHeader className="pb-4">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <CardTitle className="text-white text-lg flex items-center gap-2">
                      {getAssetTypeIcon(asset.asset_type)}
                      {asset.name}
                    </CardTitle>
                    <CardDescription className="text-slate-400 text-sm mt-1">
                      {asset.symbol}
                    </CardDescription>
                  </div>
                  <Badge className={`text-xs ${getAssetTypeColor(asset.asset_type)}`}>
                    {asset.asset_type}
                  </Badge>
                  {/* Market status indicator */}
                  <div className={`w-2 h-2 rounded-full ml-2 ${
                    generatePriceVariation(asset.asset_id) >= 0 ? 'bg-green-400' : 'bg-red-400'
                  } animate-pulse`}></div>
                </div>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-slate-400 text-sm">Preço Atual</p>
                    <div className="space-y-1">
                      <p className="text-white font-bold text-lg">
                        {formatCurrency(asset.price)}
                      </p>
                      <div className={`flex items-center gap-1 ${getPriceVariationDisplay(generatePriceVariation(asset.asset_id)).color}`}>
                        {getPriceVariationDisplay(generatePriceVariation(asset.asset_id)).icon}
                        <span className="text-xs font-medium">
                          {getPriceVariationDisplay(generatePriceVariation(asset.asset_id)).text}
                        </span>
                      </div>
                    </div>
                  </div>
                  <div>
                    <p className="text-slate-400 text-sm">Volume</p>
                    <p className="text-white font-semibold">
                      {formatNumber(asset.volume)}
                    </p>
                  </div>
                </div>
                
                <div>
                  <p className="text-slate-400 text-sm">Ações Disponíveis</p>
                  <p className="text-slate-300 font-medium">
                    {formatNumber(asset.available_shares)}
                  </p>
                </div>

                <Button 
                  size="sm" 
                  className="w-full bg-slate-700 hover:bg-slate-600 text-white"
                  onClick={(e) => {
                    e.stopPropagation();
                    router.push(`/assets/${asset.asset_id}`);
                  }}
                >
                  <Eye className="h-4 w-4 mr-2" />
                  Ver Detalhes
                </Button>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
} 