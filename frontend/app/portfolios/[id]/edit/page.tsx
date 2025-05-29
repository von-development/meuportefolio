import { Suspense } from 'react';
import { PortfolioEditForm } from '@/components/portfolios/portfolio-edit-form';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

interface EditPortfolioPageProps {
  params: {
    id: string;
  };
}

export default async function EditPortfolioPage({ params }: EditPortfolioPageProps) {
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
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center space-x-4">
          <Button variant="ghost" size="sm" asChild className="text-slate-400 hover:text-white">
            <Link href={`/portfolios/${portfolioId}`}>
              <ArrowLeft className="h-4 w-4 mr-2" />
              Voltar para Detalhes
            </Link>
          </Button>
        </div>
        
        <div>
          <h1 className="text-3xl font-bold text-white">Editar Portfólio</h1>
          <p className="text-slate-400 mt-2">
            Modifique as informações do seu portfólio
          </p>
        </div>

        {/* Edit Form */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white">Informações do Portfólio</CardTitle>
            <CardDescription className="text-slate-400">
              Atualize as informações do seu portfólio
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Suspense fallback={
              <div className="flex items-center justify-center py-8">
                <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
                <span className="ml-3 text-slate-400">Carregando formulário...</span>
              </div>
            }>
              <PortfolioEditForm portfolioId={portfolioId} />
            </Suspense>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 