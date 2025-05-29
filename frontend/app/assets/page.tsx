import { Suspense } from 'react';
import { AssetsList } from '@/components/assets/assets-list';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

export default function AssetsPage() {
  return (
    <div className="min-h-screen bg-slate-900">
      <div className="container mx-auto py-8 px-4 space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white">Ativos Disponíveis</h1>
            <p className="text-slate-400 mt-2">
              Explore e analise todos os ativos disponíveis para investimento
            </p>
          </div>
        </div>

        {/* Assets List */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white">Mercado de Ativos</CardTitle>
            <CardDescription className="text-slate-400">
              Visualize e pesquise todos os ativos disponíveis na plataforma
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Suspense fallback={<div className="text-slate-300">Carregando ativos...</div>}>
              <AssetsList />
            </Suspense>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 