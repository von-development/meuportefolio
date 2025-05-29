'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { portfolioApi } from '@/lib/api/portfolio';
import { toast } from 'sonner';
import { 
  MoreHorizontal, 
  TrendingUp, 
  TrendingDown, 
  DollarSign, 
  Calendar,
  Edit,
  Trash2,
  Eye
} from 'lucide-react';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import type { Portfolio } from '@/lib/api/portfolio';

interface PortfolioCardProps {
  portfolio: Portfolio;
  onDeleted: (portfolioId: number) => void;
}

export function PortfolioCard({ portfolio, onDeleted }: PortfolioCardProps) {
  const [loading, setLoading] = useState(false);

  const handleDelete = async () => {
    if (!confirm('Tem certeza que deseja excluir este portfólio?')) {
      return;
    }

    setLoading(true);
    try {
      await portfolioApi.deletePortfolio(portfolio.portfolio_id);
      onDeleted(portfolio.portfolio_id);
    } catch (error) {
      console.error('Error deleting portfolio:', error);
      toast.error('Erro ao excluir portfólio');
    } finally {
      setLoading(false);
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'USD',
    }).format(value);
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('pt-BR');
  };

  const isPositive = portfolio.current_profit_pct >= 0;

  return (
    <Card className="bg-slate-800 border-slate-700 hover:bg-slate-750 transition-colors">
      <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
        <CardTitle className="text-base font-medium text-white truncate pr-2">
          {portfolio.name}
        </CardTitle>
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="h-8 w-8 p-0 text-slate-400 hover:text-white">
              <MoreHorizontal className="h-4 w-4" />
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="bg-slate-800 border-slate-700">
            <DropdownMenuItem asChild className="text-slate-300 hover:bg-slate-700">
              <Link href={`/portfolios/${portfolio.portfolio_id}`}>
                <Eye className="mr-2 h-4 w-4" />
                Visualizar
              </Link>
            </DropdownMenuItem>
            <DropdownMenuItem asChild className="text-slate-300 hover:bg-slate-700">
              <Link href={`/portfolios/${portfolio.portfolio_id}/edit`}>
                <Edit className="mr-2 h-4 w-4" />
                Editar
              </Link>
            </DropdownMenuItem>
            <DropdownMenuItem 
              onClick={handleDelete}
              disabled={loading}
              className="text-red-400 hover:bg-red-600 hover:text-white"
            >
              <Trash2 className="mr-2 h-4 w-4" />
              {loading ? 'Excluindo...' : 'Excluir'}
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Current Funds */}
          <div className="flex items-center justify-between">
            <div className="flex items-center text-slate-400">
              <DollarSign className="h-4 w-4 mr-2" />
              <span className="text-sm">Fundos Atuais</span>
            </div>
            <span className="text-lg font-semibold text-white">
              {formatCurrency(portfolio.current_funds)}
            </span>
          </div>

          {/* Profit Percentage */}
          <div className="flex items-center justify-between">
            <div className="flex items-center text-slate-400">
              {isPositive ? (
                <TrendingUp className="h-4 w-4 mr-2 text-green-500" />
              ) : (
                <TrendingDown className="h-4 w-4 mr-2 text-red-500" />
              )}
              <span className="text-sm">Lucro</span>
            </div>
            <Badge 
              variant={isPositive ? "default" : "destructive"}
              className={isPositive ? "bg-green-600 hover:bg-green-700" : "bg-red-600 hover:bg-red-700"}
            >
              {isPositive ? '+' : ''}{portfolio.current_profit_pct.toFixed(2)}%
            </Badge>
          </div>

          {/* Creation Date */}
          <div className="flex items-center justify-between text-sm">
            <div className="flex items-center text-slate-400">
              <Calendar className="h-4 w-4 mr-2" />
              <span>Criado em</span>
            </div>
            <span className="text-slate-300">
              {formatDate(portfolio.creation_date)}
            </span>
          </div>

          {/* Last Updated */}
          <div className="flex items-center justify-between text-sm">
            <span className="text-slate-500">Última atualização</span>
            <span className="text-slate-400">
              {formatDate(portfolio.last_updated)}
            </span>
          </div>

          {/* View Details Button */}
          <Button 
            asChild 
            className="w-full mt-4 bg-blue-600 hover:bg-blue-700"
          >
            <Link href={`/portfolios/${portfolio.portfolio_id}`}>
              Ver Detalhes
            </Link>
          </Button>
        </div>
      </CardContent>
    </Card>
  );
} 