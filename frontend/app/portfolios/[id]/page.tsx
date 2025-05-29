import { Suspense } from 'react';
import { PortfolioDetails } from '@/components/portfolios/portfolio-details';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

interface PortfolioDetailPageProps {
  params: {
    id: string;
  };
}

export default async function PortfolioDetailPage({ params }: PortfolioDetailPageProps) {
  const { id } = await params;
  const portfolioId = parseInt(id);

  if (isNaN(portfolioId)) {
    return (
      <div className="container mx-auto py-8 px-4">
        <div className="text-center">
          <h1 className="text-2xl font-bold text-white mb-4">Portfólio não encontrado</h1>
          <p className="text-slate-400 mb-6">O ID do portfólio fornecido é inválido.</p>
          <Button asChild>
            <Link href="/portfolios">Voltar para Portfólios</Link>
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="container mx-auto py-8 px-4">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center space-x-4">
          <Button variant="ghost" size="sm" asChild className="text-slate-400 hover:text-white">
            <Link href="/portfolios">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar para Portfólios
            </Link>
          </Button>
        </div>

        {/* Portfolio Details */}
        <Suspense fallback={
          <div className="flex items-center justify-center py-16">
            <div className="w-8 h-8 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
            <span className="ml-3 text-slate-400">Carregando detalhes do portfólio...</span>
          </div>
        }>
          <PortfolioDetails portfolioId={id} />
        </Suspense>
      </div>
    </div>
  );
} 