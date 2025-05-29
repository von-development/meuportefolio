import { Suspense } from 'react';
import { PortfolioDetails } from '@/components/portfolios/portfolio-details';

interface PortfolioDetailPageProps {
  params: {
    id: string;
    portfolioId: string;
  };
}

export default async function PortfolioDetailPage({ params }: PortfolioDetailPageProps) {
  const { id, portfolioId } = await params;
  
  return (
    <div className="min-h-screen bg-slate-900">
      <div className="container mx-auto py-8 px-4">
        <Suspense fallback={<div className="text-slate-300">Carregando detalhes do portfólio...</div>}>
          <PortfolioDetails 
            userId={id} 
            portfolioId={portfolioId} 
          />
        </Suspense>
      </div>
    </div>
  );
} 