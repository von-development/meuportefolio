'use client';

import { useEffect, useState } from 'react';
import { PortfolioForm } from './portfolio-form';
import { portfolioApi } from '@/lib/api/portfolio';
import { toast } from 'sonner';
import type { Portfolio } from '@/lib/api/portfolio';

interface PortfolioEditFormProps {
  portfolioId: number;
}

export function PortfolioEditForm({ portfolioId }: PortfolioEditFormProps) {
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPortfolio();
  }, [portfolioId]);

  const loadPortfolio = async () => {
    try {
      const data = await portfolioApi.getPortfolio(portfolioId);
      setPortfolio(data);
    } catch (error) {
      console.error('Error loading portfolio:', error);
      toast.error('Erro ao carregar portfólio');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
        <span className="ml-3 text-slate-400">Carregando dados do portfólio...</span>
      </div>
    );
  }

  if (!portfolio) {
    return (
      <div className="text-center py-8">
        <p className="text-red-400">Portfólio não encontrado</p>
      </div>
    );
  }

  return <PortfolioForm portfolio={portfolio} isEditing />;
} 