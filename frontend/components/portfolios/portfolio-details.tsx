'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { portfolioApi, type Portfolio, type PortfolioSummary } from '@/lib/api/portfolio';
import { riskApi, type PortfolioRiskAnalysis } from '@/lib/api/risk';
import { type AssetHolding } from '@/lib/api/asset';
import { userApi, type User } from '@/lib/api/user';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  ArrowLeft, 
  Briefcase, 
  TrendingUp, 
  TrendingDown,
  AlertTriangle, 
  RefreshCw, 
  DollarSign, 
  BarChart3, 
  Activity,
  PieChart,
  Target,
  Calendar,
  User as UserIcon,
  Edit,
  Trash2,
  Settings
} from 'lucide-react';
import { formatDate, formatCurrency, formatPercentage } from '@/lib/utils';
import { toast } from 'sonner';
import Link from 'next/link';

interface PortfolioDetailsProps {
  portfolioId: string;
  userId?: string;
}

export function PortfolioDetails({ portfolioId, userId }: PortfolioDetailsProps) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null);
  const [portfolioSummary, setPortfolioSummary] = useState<PortfolioSummary | null>(null);
  const [holdings, setHoldings] = useState<AssetHolding[]>([]);
  const [riskAnalysis, setRiskAnalysis] = useState<PortfolioRiskAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchPortfolioData = async () => {
    try {
      setLoading(true);
      setError(null);

      // API CALL: getPortfolio - Get basic portfolio details
      const portfolioData = await portfolioApi.getPortfolio(parseInt(portfolioId));
      setPortfolio(portfolioData);

      // Try to get user info if userId is provided or if we can extract it from portfolio
      if (userId) {
        try {
          const userData = await userApi.getUser(userId);
          setUser(userData);
        } catch (userError) {
          console.log('User data not available');
        }
      } else if (portfolioData.user_id) {
        try {
          const userData = await userApi.getUser(portfolioData.user_id);
          setUser(userData);
        } catch (userError) {
          console.log('User data not available');
        }
      }

      // API CALL: getPortfolioSummary - Get detailed portfolio summary
      try {
        const summaryData = await portfolioApi.getPortfolioSummary(parseInt(portfolioId));
        setPortfolioSummary(summaryData);
      } catch (summaryError) {
        console.log('Portfolio summary not available');
      }

      // API CALL: getPortfolioHoldings - Get portfolio holdings/assets
      try {
        const holdingsData = await portfolioApi.getPortfolioHoldings(parseInt(portfolioId));
        setHoldings(holdingsData);
      } catch (holdingsError) {
        console.log('Portfolio holdings not available');
      }

      // API CALL: getPortfolioRiskAnalysis - Get portfolio-specific risk metrics
      try {
        const riskData = await riskApi.getPortfolioRiskAnalysis(parseInt(portfolioId));
        setRiskAnalysis(riskData);
      } catch (riskError) {
        console.log('Portfolio risk analysis not available');
      }

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch portfolio data'));
      toast.error('Erro ao carregar dados do portfólio');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPortfolioData();
  }, [portfolioId, userId]);

  // Calculate asset allocation for visualization
  const getAssetAllocation = () => {
    const allocation: { [key: string]: number } = {};
    holdings.forEach(holding => {
      allocation[holding.asset_type] = (allocation[holding.asset_type] || 0) + holding.market_value;
    });
    return Object.entries(allocation).map(([type, value]) => ({
      type,
      value,
      percentage: (value / holdings.reduce((sum, h) => sum + h.market_value, 0)) * 100
    }));
  };

  const assetAllocation = holdings.length > 0 ? getAssetAllocation() : [];

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-slate-400" />
          <span className="text-lg text-slate-300">Carregando detalhes do portfólio...</span>
        </div>
      </div>
    );
  }

  if (error || !portfolio) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold mb-2 text-white">Erro ao carregar portfólio</h2>
          <p className="text-slate-400 mb-4">
            {error?.message || 'Portfólio não encontrado'}
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
            <Button onClick={fetchPortfolioData} className="bg-blue-600 hover:bg-blue-700">
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
      {/* Header with Navigation and Actions */}
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
              <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center">
                <Briefcase className="h-5 w-5 text-white" />
              </div>
              {portfolio.name}
            </h1>
            <p className="text-slate-400 mt-1">
              {user?.name ? `${user.name} • ` : ''}Criado em {formatDate(portfolio.creation_date)}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" className="border-slate-600 text-slate-300 hover:bg-slate-800" asChild>
            <Link href={`/portfolios/${portfolioId}/edit`}>
              <Edit className="h-4 w-4 mr-2" />
              Editar
            </Link>
          </Button>
          <Button variant="outline" size="sm" className="border-slate-600 text-slate-300 hover:bg-slate-800">
            <Settings className="h-4 w-4 mr-2" />
            Configurar
          </Button>
          <Button variant="destructive" size="sm">
            <Trash2 className="h-4 w-4 mr-2" />
            Excluir
          </Button>
        </div>
      </div>

      {/* Portfolio Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-green-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <DollarSign className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Fundos Atuais</h3>
            <p className="text-3xl font-bold text-green-400">
              {formatCurrency(portfolio.current_funds)}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-4 ${
              portfolio.current_profit_pct >= 0 ? 'bg-green-600' : 'bg-red-600'
            }`}>
              {portfolio.current_profit_pct >= 0 ? 
                <TrendingUp className="h-6 w-6 text-white" /> : 
                <TrendingDown className="h-6 w-6 text-white" />
              }
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Lucro Total</h3>
            <p className={`text-3xl font-bold ${
              portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'
            }`}>
              {formatPercentage(portfolio.current_profit_pct)}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <Target className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Total de Ativos</h3>
            <p className="text-3xl font-bold text-blue-400">
              {holdings.length}
            </p>
          </CardContent>
        </Card>

        <Card className="bg-slate-800 border-slate-700">
          <CardContent className="p-6 text-center">
            <div className="w-12 h-12 bg-purple-600 rounded-xl flex items-center justify-center mx-auto mb-4">
              <BarChart3 className="h-6 w-6 text-white" />
            </div>
            <h3 className="font-semibold text-lg mb-2 text-white">Total de Trades</h3>
            <p className="text-3xl font-bold text-purple-400">
              {portfolioSummary?.total_trades || 0}
            </p>
          </CardContent>
        </Card>
      </div>

      {/* Asset Allocation and Holdings */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Asset Allocation */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <PieChart className="h-5 w-5 text-slate-400" />
              Alocação por Tipo de Ativo
            </CardTitle>
            <CardDescription className="text-slate-400">
              Distribuição dos investimentos por categoria
            </CardDescription>
          </CardHeader>
          <CardContent>
            {assetAllocation.length === 0 ? (
              <div className="text-center py-8">
                <PieChart className="h-12 w-12 text-slate-600 mx-auto mb-4" />
                <p className="text-slate-400">Nenhum ativo encontrado</p>
              </div>
            ) : (
              <div className="space-y-4">
                {assetAllocation.map((allocation, index) => (
                  <div key={allocation.type} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className={`w-4 h-4 rounded-full ${
                        index === 0 ? 'bg-blue-500' :
                        index === 1 ? 'bg-green-500' :
                        index === 2 ? 'bg-purple-500' :
                        'bg-orange-500'
                      }`} />
                      <span className="text-white font-medium">{allocation.type}</span>
                    </div>
                    <div className="text-right">
                      <p className="text-white font-semibold">{formatCurrency(allocation.value)}</p>
                      <p className="text-slate-400 text-sm">{allocation.percentage.toFixed(1)}%</p>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Holdings Table */}
        <Card className="lg:col-span-2 bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Target className="h-5 w-5 text-slate-400" />
              Holdings do Portfólio
            </CardTitle>
            <CardDescription className="text-slate-400">
              Detalhes de todos os ativos no portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            {holdings.length === 0 ? (
              <div className="text-center py-8">
                <Target className="h-12 w-12 text-slate-600 mx-auto mb-4" />
                <p className="text-slate-400">Nenhum ativo encontrado neste portfólio</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-slate-700">
                      <th className="text-left py-3 px-2 text-slate-400 font-medium">Ativo</th>
                      <th className="text-left py-3 px-2 text-slate-400 font-medium">Tipo</th>
                      <th className="text-right py-3 px-2 text-slate-400 font-medium">Quantidade</th>
                      <th className="text-right py-3 px-2 text-slate-400 font-medium">Preço Atual</th>
                      <th className="text-right py-3 px-2 text-slate-400 font-medium">Valor de Mercado</th>
                    </tr>
                  </thead>
                  <tbody>
                    {holdings.map((holding) => (
                      <tr key={`${holding.portfolio_id}-${holding.asset_id}`} className="border-b border-slate-700/50 hover:bg-slate-700/30">
                        <td className="py-4 px-2">
                          <div>
                            <p className="text-white font-medium">{holding.asset_name}</p>
                            <p className="text-slate-400 text-sm">{holding.symbol}</p>
                          </div>
                        </td>
                        <td className="py-4 px-2">
                          <Badge variant="outline" className="border-slate-600 text-slate-300">
                            {holding.asset_type}
                          </Badge>
                        </td>
                        <td className="py-4 px-2 text-right text-white font-medium">
                          {holding.quantity_held.toLocaleString()}
                        </td>
                        <td className="py-4 px-2 text-right text-white font-medium">
                          {formatCurrency(holding.current_price)}
                        </td>
                        <td className="py-4 px-2 text-right text-white font-bold">
                          {formatCurrency(holding.market_value)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Portfolio Risk Analysis */}
      {riskAnalysis && (
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Activity className="h-5 w-5 text-slate-400" />
              Análise de Risco do Portfólio
            </CardTitle>
            <CardDescription className="text-slate-400">
              Métricas específicas de risco para este portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="text-center p-4 bg-slate-700/50 rounded-lg">
                <div className="w-12 h-12 bg-orange-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                  <AlertTriangle className="h-6 w-6 text-white" />
                </div>
                <h3 className="font-semibold text-lg mb-2 text-white">Nível de Risco</h3>
                <Badge 
                  className={`text-sm px-3 py-1 font-semibold ${
                    riskAnalysis.risk_level === 'Low' ? 'bg-green-600 text-white hover:bg-green-700' :
                    riskAnalysis.risk_level === 'Moderate' ? 'bg-yellow-600 text-white hover:bg-yellow-700' : 
                    'bg-red-600 text-white hover:bg-red-700'
                  }`}
                >
                  {riskAnalysis.risk_level}
                </Badge>
              </div>

              {riskAnalysis.beta && (
                <div className="text-center p-4 bg-slate-700/50 rounded-lg">
                  <div className="w-12 h-12 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <BarChart3 className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Beta</h3>
                  <p className="text-3xl font-bold text-blue-400">
                    {riskAnalysis.beta.toFixed(2)}
                  </p>
                </div>
              )}

              {riskAnalysis.sharpe_ratio && (
                <div className="text-center p-4 bg-slate-700/50 rounded-lg">
                  <div className="w-12 h-12 bg-purple-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <Activity className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Sharpe Ratio</h3>
                  <p className="text-3xl font-bold text-purple-400">
                    {riskAnalysis.sharpe_ratio.toFixed(2)}
                  </p>
                </div>
              )}

              {riskAnalysis.maximum_drawdown && (
                <div className="text-center p-4 bg-slate-700/50 rounded-lg">
                  <div className="w-12 h-12 bg-red-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <TrendingDown className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Drawdown Máximo</h3>
                  <p className="text-3xl font-bold text-red-400">
                    {formatPercentage(riskAnalysis.maximum_drawdown)}
                  </p>
                </div>
              )}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
} 