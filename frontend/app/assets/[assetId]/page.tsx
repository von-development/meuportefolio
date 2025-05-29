import { Suspense } from 'react';
import { AssetDetails } from '@/components/assets/asset-details';

interface AssetDetailPageProps {
  params: Promise<{
    assetId: string;
  }>;
}

export default async function AssetDetailPage({ params }: AssetDetailPageProps) {
  const { assetId } = await params;
  
  return (
    <div className="min-h-screen bg-slate-900">
      <div className="container mx-auto py-8 px-4">
        <Suspense fallback={<div className="text-slate-300">Carregando detalhes do ativo...</div>}>
          <AssetDetails assetId={assetId} />
        </Suspense>
      </div>
    </div>
  );
} 