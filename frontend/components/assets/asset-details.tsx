'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { assetApi, type Asset, type AssetPriceHistory } from '@/lib/api/asset';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  ArrowLeft,
  Building2,
  TrendingUp,
  TrendingDown,
  DollarSign,
  BarChart3,
  Activity,
  RefreshCw,
  AlertTriangle,
  Calendar,
  Target,
  Volume2,
  Coins,
  LineChart
} from 'lucide-react';
import { formatDate, formatCurrency, formatNumber } from '@/lib/utils';
import { toast } from 'sonner';
import { 
  LineChart as RechartsLineChart, 
  Line, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer,
  Area,
  AreaChart
} from 'recharts';

interface AssetDetailsProps {
  assetId: string;
}

export function AssetDetails({ assetId }: AssetDetailsProps) {
  const router = useRouter();
  const [asset, setAsset] = useState<Asset | null>(null);
  const [priceHistory, setPriceHistory] = useState<AssetPriceHistory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchAssetData = async () => {
    try {
      setLoading(true);
      setError(null);

      // API CALL: getAsset - Get specific asset details
      const assetData = await assetApi.getAsset(parseInt(assetId));
      setAsset(assetData);

      // API CALL: getPriceHistory - Get asset price history for charts
      try {
        const historyData = await assetApi.getPriceHistory(parseInt(assetId));
        setPriceHistory(historyData);
      } catch (historyError) {
        console.log('Price history not available for this asset');
      }

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch asset data'));
      toast.error('Erro ao carregar dados do ativo');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAssetData();
  }, [assetId]);

  const getAssetTypeIcon = (assetType: string) => {
    switch (assetType.toLowerCase()) {
      case 'company':
        return <Building2 className="h-6 w-6" />;
      case 'index':
        return <BarChart3 className="h-6 w-6" />;
      case 'cryptocurrency':
        return <Coins className="h-6 w-6" />;
      case 'commodity':
        return <Activity className="h-6 w-6" />;
      default:
        return <DollarSign className="h-6 w-6" />;
    }
  };

  const getAssetTypeColor = (assetType: string) => {
    switch (assetType.toLowerCase()) {
      case 'company':
        return 'bg-blue-600 text-white hover:bg-blue-700';
      case 'index':
        return 'bg-green-600 text-white hover:bg-green-700';
      case 'cryptocurrency':
        return 'bg-yellow-600 text-white hover:bg-yellow-700';
      case 'commodity':
        return 'bg-orange-600 text-white hover:bg-orange-700';
      default:
        return 'bg-purple-600 text-white hover:bg-purple-700';
    }
  };

  // Calculate price change if we have history
  const getPriceChange = () => {
    if (priceHistory.length < 2) return null;
    const latest = priceHistory[priceHistory.length - 1];
    const previous = priceHistory[priceHistory.length - 2];
    const change = latest.price - previous.price;
    const changePercent = (change / previous.price) * 100;
    return { change, changePercent };
  };

  // Prepare chart data
  const chartData = priceHistory.map(entry => ({
    date: new Date(entry.timestamp).toLocaleDateString('pt-BR', { 
      month: 'short', 
      day: 'numeric' 
    }),
    fullDate: formatDate(entry.timestamp),
    price: entry.price,
    volume: entry.volume,
    formattedPrice: formatCurrency(entry.price),
    formattedVolume: formatNumber(entry.volume)
  })).reverse(); // Reverse to show chronological order

  // Calculate price statistics
  const priceStats = priceHistory.length > 0 ? {
    highest: Math.max(...priceHistory.map(p => p.price)),
    lowest: Math.min(...priceHistory.map(p => p.price)),
    average: priceHistory.reduce((sum, p) => sum + p.price, 0) / priceHistory.length,
    totalVolume: priceHistory.reduce((sum, p) => sum + p.volume, 0)
  } : null;

  const priceChange = getPriceChange();

  // Custom tooltip for the chart
  const CustomTooltip = ({ active, payload, label }: any) => {
    if (active && payload && payload.length) {
      const data = payload[0].payload;
      return (
        <div className="bg-slate-800 border border-slate-700 rounded-lg p-3 shadow-lg">
          <p className="text-slate-300 text-sm mb-2">{data.fullDate}</p>
          <div className="space-y-1">
            <p className="text-white font-semibold">
              Preço: <span className="text-green-400">{data.formattedPrice}</span>
            </p>
            <p className="text-white font-semibold">
              Volume: <span className="text-blue-400">{data.formattedVolume}</span>
            </p>
          </div>
        </div>
      );
    }
    return null;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-slate-400" />
          <span className="text-lg text-slate-300">Carregando detalhes do ativo...</span>
        </div>
      </div>
    );
  }

  if (error || !asset) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold mb-2 text-white">Erro ao carregar ativo</h2>
          <p className="text-slate-400 mb-4">
            {error?.message || 'Ativo não encontrado'}
          </p>
          <div className="space-x-2">
            <Button 
              onClick={() => router.back()} 
              variant="outline" 
              className="border-slate-600 text-slate-300 hover:bg-slate-800"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <Button onClick={fetchAssetData} className="bg-blue-600 hover:bg-blue-700">
              <RefreshCw className="h-4 w-4 mr-2" />
              Tentar novamente
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header with Navigation */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button 
            onClick={() => router.back()} 
            variant="outline" 
            size="sm"
            className="text-slate-300 border-slate-600 hover:bg-slate-800"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar
          </Button>
          <div>
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <div className={`w-10 h-10 rounded-full flex items-center justify-center ${getAssetTypeColor(asset.asset_type)}`}>
                {getAssetTypeIcon(asset.asset_type)}
              </div>
              {asset.name}
            </h1>
            <p className="text-slate-400 mt-1">
              {asset.symbol} • Última atualização: {formatDate(asset.last_updated)}
            </p>
          </div>
        </div>
        <Badge className={`text-sm ${getAssetTypeColor(asset.asset_type)}`}>
          {asset.asset_type}
        </Badge>
      </div>

      {/* Price Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-green-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <DollarSign className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Preço Atual</h3>
            <p className="text-3xl font-bold text-green-400">
              {formatCurrency(asset.price)}
            </p>
            {priceChange && (
              <div className={`flex items-center justify-center gap-1 mt-2 ${
                priceChange.change >= 0 ? 'text-green-400' : 'text-red-400'
              }`}>
                {priceChange.change >= 0 ? 
                  <TrendingUp className="h-4 w-4" /> : 
                  <TrendingDown className="h-4 w-4" />
                }
                <span className="text-sm font-medium">
                  {priceChange.changePercent >= 0 ? '+' : ''}{priceChange.changePercent.toFixed(2)}%
                </span>
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <Volume2 className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Volume</h3>
            <p className="text-3xl font-bold text-blue-400">
              {formatNumber(asset.volume)}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-purple-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <Target className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Ações Disponíveis</h3>
            <p className="text-3xl font-bold text-purple-400">
              {formatNumber(asset.available_shares)}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-orange-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <BarChart3 className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Cap. de Mercado</h3>
            <p className="text-3xl font-bold text-orange-400">
              {formatCurrency(asset.price * asset.available_shares)}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Asset Information and Price Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Asset Overview */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Activity className="h-5 w-5 text-slate-400" />
              Visão Geral do Ativo
            </CardTitle>
            <CardDescription className="text-slate-400">
              Informações básicas e métricas do ativo
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-slate-400 text-sm font-medium">ID do Ativo</p>
                <p className="text-white font-semibold">{asset.asset_id}</p>
              </div>
              <div>
                <p className="text-slate-400 text-sm font-medium">Símbolo</p>
                <p className="text-white font-semibold font-mono">{asset.symbol}</p>
              </div>
            </div>
            
            <div>
              <p className="text-slate-400 text-sm font-medium">Tipo de Ativo</p>
              <Badge className={`mt-1 ${getAssetTypeColor(asset.asset_type)}`}>
                {asset.asset_type}
              </Badge>
            </div>

            <div>
              <p className="text-slate-400 text-sm font-medium">Última Atualização</p>
              <p className="text-white font-semibold">{formatDate(asset.last_updated)}</p>
            </div>

            <div className="pt-4 space-y-2">
              <div className="flex justify-between">
                <span className="text-slate-400 text-sm">Volume de Negociação</span>
                <span className="text-white font-medium">{formatNumber(asset.volume)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-400 text-sm">Valor Total de Mercado</span>
                <span className="text-white font-medium">
                  {formatCurrency(asset.price * asset.available_shares)}
                </span>
              </div>
            </div>

            {/* Price Statistics */}
            {priceStats && (
              <>
                <div className="pt-4 border-t border-slate-700">
                  <h4 className="text-white font-semibold mb-3">Estatísticas de Preço</h4>
                  <div className="space-y-2">
                    <div className="flex justify-between">
                      <span className="text-slate-400 text-sm">Maior Preço</span>
                      <span className="text-green-400 font-medium">{formatCurrency(priceStats.highest)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400 text-sm">Menor Preço</span>
                      <span className="text-red-400 font-medium">{formatCurrency(priceStats.lowest)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400 text-sm">Preço Médio</span>
                      <span className="text-blue-400 font-medium">{formatCurrency(priceStats.average)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-400 text-sm">Volume Total</span>
                      <span className="text-purple-400 font-medium">{formatNumber(priceStats.totalVolume)}</span>
                    </div>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Interactive Price Chart */}
        <Card className="lg:col-span-2 bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <LineChart className="h-5 w-5 text-slate-400" />
              Evolução do Preço
            </CardTitle>
            <CardDescription className="text-slate-400">
              Gráfico interativo da evolução do preço ao longo do tempo
            </CardDescription>
          </CardHeader>
          <CardContent>
            {priceHistory.length === 0 ? (
              <div className="text-center py-12">
                <LineChart className="h-12 w-12 text-slate-600 mx-auto mb-4" />
                <p className="text-slate-400 text-lg">Histórico de preços não disponível</p>
                <p className="text-slate-500 text-sm mt-1">
                  Os dados históricos podem não estar disponíveis para este ativo
                </p>
              </div>
            ) : (
              <div className="space-y-6">
                {/* Price Chart */}
                <div className="h-80">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData}>
                      <defs>
                        <linearGradient id="priceGradient" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                      <XAxis 
                        dataKey="date" 
                        stroke="#9ca3af"
                        fontSize={12}
                        tickLine={{ stroke: '#6b7280' }}
                      />
                      <YAxis 
                        stroke="#9ca3af"
                        fontSize={12}
                        tickLine={{ stroke: '#6b7280' }}
                        tickFormatter={(value) => `$${value.toFixed(2)}`}
                      />
                      <Tooltip content={<CustomTooltip />} />
                      <Area
                        type="monotone"
                        dataKey="price"
                        stroke="#10b981"
                        strokeWidth={3}
                        fill="url(#priceGradient)"
                        dot={{ fill: '#10b981', strokeWidth: 2, r: 4 }}
                        activeDot={{ r: 6, stroke: '#10b981', strokeWidth: 2, fill: '#065f46' }}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>

                {/* Volume Chart */}
                <div className="h-32">
                  <h4 className="text-white font-semibold mb-3">Volume de Negociação</h4>
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart data={chartData}>
                      <defs>
                        <linearGradient id="volumeGradient" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                          <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#374151" />
                      <XAxis 
                        dataKey="date" 
                        stroke="#9ca3af"
                        fontSize={10}
                        tickLine={{ stroke: '#6b7280' }}
                      />
                      <YAxis 
                        stroke="#9ca3af"
                        fontSize={10}
                        tickLine={{ stroke: '#6b7280' }}
                        tickFormatter={(value) => formatNumber(value)}
                      />
                      <Tooltip 
                        formatter={(value: any) => [formatNumber(value), 'Volume']}
                        labelStyle={{ color: '#e5e7eb' }}
                        contentStyle={{ 
                          backgroundColor: '#1e293b', 
                          border: '1px solid #374151',
                          borderRadius: '8px'
                        }}
                      />
                      <Area
                        type="monotone"
                        dataKey="volume"
                        stroke="#3b82f6"
                        strokeWidth={2}
                        fill="url(#volumeGradient)"
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 