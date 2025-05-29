'use client';

import { useEffect, useState } from 'react';
import { portfolioApi } from '@/lib/api/portfolio';
import { PortfolioCard } from '@/components/portfolios/portfolio-card';
import { toast } from 'sonner';
import type { Portfolio } from '@/lib/api/portfolio';

export function PortfoliosList() {
  const [portfolios, setPortfolios] = useState<Portfolio[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPortfolios();
  }, []);

  const loadPortfolios = async () => {
    try {
      // Get all portfolios (without user filter)
      const data = await portfolioApi.getPortfolios();
      setPortfolios(data);
    } catch (error) {
      console.error('Error loading portfolios:', error);
      toast.error('Erro ao carregar portfólios');
    } finally {
      setLoading(false);
    }
  };

  const handlePortfolioDeleted = (portfolioId: number) => {
    setPortfolios(prev => prev.filter(p => p.portfolio_id !== portfolioId));
    toast.success('Portfólio excluído com sucesso!');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        <span className="ml-3 text-slate-400">Carregando portfólios...</span>
      </div>
    );
  }

  if (portfolios.length === 0) {
    return (
      <div className="text-center py-12">
        <div className="w-24 h-24 mx-auto mb-4 rounded-full bg-slate-700 flex items-center justify-center">
          <svg className="w-12 h-12 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
          </svg>
        </div>
        <h3 className="text-lg font-medium text-white mb-2">Nenhum portfólio encontrado</h3>
        <p className="text-slate-400 mb-6">
          Não há portfólios cadastrados no sistema ainda.
        </p>
      </div>
    );
  }

  return (
    <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
      {portfolios.map((portfolio) => (
        <PortfolioCard
          key={portfolio.portfolio_id}
          portfolio={portfolio}
          onDeleted={handlePortfolioDeleted}
        />
      ))}
    </div>
  );
} 