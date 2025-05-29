import { Suspense } from 'react';
import { PortfoliosList } from '@/components/portfolios/portfolios-list';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Plus } from 'lucide-react';
import Link from 'next/link';

export default function PortfoliosPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white">Portfólios</h1>
            <p className="text-slate-400 mt-2">
              Explore e gerencie todos os portfólios de investimento
            </p>
          </div>
          <Button asChild className="bg-blue-600 hover:bg-blue-700">
            <Link href="/portfolios/create">
              <Plus className="h-4 w-4 mr-2" />
              Criar Portfólio
            </Link>
          </Button>
        </div>

        {/* Portfolios List */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white">Todos os Portfólios</CardTitle>
            <CardDescription className="text-slate-400">
              Visualize todos os portfólios cadastrados no sistema
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Suspense fallback={
              <div className="flex items-center justify-center py-8">
                <div className="w-6 h-6 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
                <span className="ml-3 text-slate-400">Carregando portfólios...</span>
              </div>
            }>
              <PortfoliosList />
            </Suspense>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 