'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { userApi, type User } from '@/lib/api/user';
import { portfolioApi, type Portfolio } from '@/lib/api/portfolio';
import { riskApi, type RiskAnalysis } from '@/lib/api/risk';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { ArrowLeft, User as UserIcon, Briefcase, TrendingUp, AlertTriangle, RefreshCw, DollarSign, BarChart3, Activity, TrendingDown, Mail, MapPin, CreditCard, Calendar } from 'lucide-react';
import { formatDate, formatCurrency, formatPercentage } from '@/lib/utils';
import { toast } from 'sonner';

interface UserProfileProps {
  userId: string;
}

export function UserProfile({ userId }: UserProfileProps) {
  const router = useRouter();
  const [user, setUser] = useState<User | null>(null);
  const [portfolios, setPortfolios] = useState<Portfolio[]>([]);
  const [riskAnalysis, setRiskAnalysis] = useState<RiskAnalysis | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchUserData = async () => {
    try {
      setLoading(true);
      setError(null);

      // API CALL: getUserDetails - Fetch user details
      const userData = await userApi.getUser(userId);
      setUser(userData);

      // API CALL: getPortfolios - Fetch user portfolios filtered by user_id
      const portfoliosData = await portfolioApi.getPortfolios(userId);
      setPortfolios(portfoliosData);

      // API CALL: getUserRiskMetrics - Fetch user risk analysis and metrics
      try {
        const riskData = await riskApi.getUserRiskMetrics(userId);
        setRiskAnalysis(riskData);
      } catch (riskError) {
        // Risk analysis might not be available for all users
        console.log('Risk analysis not available for this user');
      }

    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch user data'));
      toast.error('Erro ao carregar dados do usuário');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUserData();
  }, [userId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin mx-auto mb-4 text-slate-400" />
          <span className="text-lg text-slate-300">Carregando perfil do usuário...</span>
        </div>
      </div>
    );
  }

  if (error || !user) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-center">
          <AlertTriangle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold mb-2 text-white">Erro ao carregar usuário</h2>
          <p className="text-slate-400 mb-4">
            {error?.message || 'Usuário não encontrado'}
          </p>
          <div className="space-x-2">
            <Button onClick={() => router.back()} variant="outline" className="border-slate-600 text-slate-300 hover:bg-slate-800">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar
            </Button>
            <Button onClick={fetchUserData} className="bg-blue-600 hover:bg-blue-700">
              <RefreshCw className="h-4 w-4 mr-2" />
              Tentar novamente
            </Button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900">
      <div className="container mx-auto py-8 px-4 space-y-8">
        {/* Header */}
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
          <div className="flex-1">
            <h1 className="text-3xl font-bold text-white flex items-center gap-3">
              <div className="w-10 h-10 bg-slate-700 rounded-full flex items-center justify-center">
                <UserIcon className="h-5 w-5 text-slate-300" />
              </div>
              {user.name}
            </h1>
            <p className="text-slate-400 mt-1">Perfil detalhado do usuário</p>
          </div>
          <Badge 
            variant={user.user_type === 'Premium' ? 'default' : 'secondary'} 
            className={`${user.user_type === 'Premium' ? 'bg-blue-600 text-white hover:bg-blue-700' : 'bg-slate-700 text-slate-300'}`}
          >
            {user.user_type}
          </Badge>
        </div>

        {/* User Information Card - Using getUserDetails API */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader className="border-b border-slate-700">
            <CardTitle className="text-white flex items-center gap-2">
              <UserIcon className="h-5 w-5 text-slate-400" />
              Informações Pessoais
            </CardTitle>
            <CardDescription className="text-slate-400">
              Dados básicos do usuário
            </CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-slate-700 rounded-lg flex items-center justify-center">
                  <Mail className="h-4 w-4 text-slate-400" />
                </div>
                <div>
                  <label className="text-sm font-medium text-slate-500">Email</label>
                  <p className="text-white font-medium">{user.email}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-slate-700 rounded-lg flex items-center justify-center">
                  <MapPin className="h-4 w-4 text-slate-400" />
                </div>
                <div>
                  <label className="text-sm font-medium text-slate-500">País</label>
                  <p className="text-white font-medium">{user.country_of_residence}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-slate-700 rounded-lg flex items-center justify-center">
                  <CreditCard className="h-4 w-4 text-slate-400" />
                </div>
                <div>
                  <label className="text-sm font-medium text-slate-500">IBAN</label>
                  <p className="text-white font-medium font-mono text-sm">{user.iban}</p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-slate-700 rounded-lg flex items-center justify-center">
                  <Calendar className="h-4 w-4 text-slate-400" />
                </div>
                <div>
                  <label className="text-sm font-medium text-slate-500">Criado em</label>
                  <p className="text-white font-medium">{formatDate(user.created_at)}</p>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Portfolios Section - Using getPortfolios API */}
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-2xl font-bold text-white flex items-center gap-3">
                <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                  <Briefcase className="h-4 w-4 text-white" />
                </div>
                Portfólios ({portfolios.length})
              </h2>
              <p className="text-slate-400 mt-1">Lista de todos os portfólios gerenciados por este usuário</p>
            </div>
          </div>

          {portfolios.length === 0 ? (
            <Card className="bg-slate-800 border-slate-700">
              <CardContent className="text-center py-12">
                <div className="w-16 h-16 bg-slate-700 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <Briefcase className="h-8 w-8 text-slate-400" />
                </div>
                <p className="text-slate-300 text-lg">Nenhum portfólio encontrado</p>
                <p className="text-slate-500 text-sm mt-1">Este usuário ainda não possui portfólios</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {portfolios.map((portfolio) => (
                <Card key={portfolio.portfolio_id} className="bg-slate-800 border-slate-700 hover:bg-slate-750 transition-all duration-200">
                  <CardHeader className="pb-4">
                    <div className="flex items-start justify-between">
                      <div>
                        <CardTitle className="text-white text-lg">{portfolio.name}</CardTitle>
                        <CardDescription className="text-slate-400 text-sm mt-1">
                          ID: {portfolio.portfolio_id} • {formatDate(portfolio.creation_date)}
                        </CardDescription>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <span className="text-slate-400 text-sm">Fundos Atuais</span>
                        <span className="font-bold text-lg text-white">
                          {formatCurrency(portfolio.current_funds)}
                        </span>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-slate-400 text-sm">Lucro</span>
                        <span className={`font-bold text-lg ${
                          portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'
                        }`}>
                          {formatPercentage(portfolio.current_profit_pct)}
                        </span>
                      </div>
                    </div>
                    <Button 
                      size="sm" 
                      className="w-full bg-slate-700 hover:bg-slate-600 text-white"
                      onClick={() => router.push(`/users/${userId}/portfolios/${portfolio.portfolio_id}`)}
                    >
                      Ver Detalhes
                    </Button>                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </div>

        {/* Risk Analysis Section - Using getUserRiskMetrics API */}
        <div className="space-y-6">
          <div>
            <h2 className="text-2xl font-bold text-white flex items-center gap-3">
              <div className="w-8 h-8 bg-orange-600 rounded-lg flex items-center justify-center">
                <TrendingUp className="h-4 w-4 text-white" />
              </div>
              Análise de Risco
            </h2>
            <p className="text-slate-400 mt-1">Métricas de risco e performance do usuário</p>
          </div>

          {!riskAnalysis ? (
            <Card className="bg-slate-800 border-slate-700">
              <CardContent className="text-center py-12">
                <div className="w-16 h-16 bg-slate-700 rounded-2xl flex items-center justify-center mx-auto mb-4">
                  <AlertTriangle className="h-8 w-8 text-slate-400" />
                </div>
                <p className="text-slate-300 text-lg">Análise de risco não disponível</p>
                <p className="text-slate-500 text-sm mt-1">Dados insuficientes para calcular métricas de risco</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              <Card className="bg-slate-800 border-slate-700">
                <CardContent className="p-6 text-center">
                  <div className="w-12 h-12 bg-blue-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <BarChart3 className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Total de Portfólios</h3>
                  <p className="text-3xl font-bold text-blue-400">
                    {riskAnalysis.total_portfolios}
                  </p>
                </CardContent>
              </Card>
              
              <Card className="bg-slate-800 border-slate-700">
                <CardContent className="p-6 text-center">
                  <div className="w-12 h-12 bg-green-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <DollarSign className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Investimento Total</h3>
                  <p className="text-3xl font-bold text-green-400">
                    {formatCurrency(riskAnalysis.total_investment)}
                  </p>
                </CardContent>
              </Card>
              
              <Card className="bg-slate-800 border-slate-700">
                <CardContent className="p-6 text-center">
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
                </CardContent>
              </Card>

              {riskAnalysis.maximum_drawdown && (
                <Card className="bg-slate-800 border-slate-700">
                  <CardContent className="p-6 text-center">
                    <div className="w-12 h-12 bg-red-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                      <TrendingDown className="h-6 w-6 text-white" />
                    </div>
                    <h3 className="font-semibold text-lg mb-2 text-white">Drawdown Máximo</h3>
                    <p className="text-3xl font-bold text-red-400">
                      {formatPercentage(riskAnalysis.maximum_drawdown)}
                    </p>
                  </CardContent>
                </Card>
              )}

              {riskAnalysis.sharpe_ratio && (
                <Card className="bg-slate-800 border-slate-700">
                  <CardContent className="p-6 text-center">
                    <div className="w-12 h-12 bg-purple-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                      <Activity className="h-6 w-6 text-white" />
                    </div>
                    <h3 className="font-semibold text-lg mb-2 text-white">Sharpe Ratio</h3>
                    <p className="text-3xl font-bold text-purple-400">
                      {riskAnalysis.sharpe_ratio.toFixed(2)}
                    </p>
                  </CardContent>
                </Card>
              )}

              <Card className="bg-slate-800 border-slate-700">
                <CardContent className="p-6 text-center">
                  <div className="w-12 h-12 bg-slate-600 rounded-xl flex items-center justify-center mx-auto mb-4">
                    <RefreshCw className="h-6 w-6 text-slate-300" />
                  </div>
                  <h3 className="font-semibold text-lg mb-2 text-white">Última Atualização</h3>
                  <p className="text-lg text-slate-300">
                    {formatDate(riskAnalysis.last_updated)}
                  </p>
                </CardContent>
              </Card>
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 
