import { Suspense } from "react";
import { api } from "@/lib/api";
import { AssetsClient } from "@/components/assets/assets-client";
import { Skeleton } from "@/components/ui/skeleton";

// Loading skeleton for assets
function AssetsLoading() {
  return (
    <div className="container mx-auto py-10">
      <div className="flex flex-col space-y-4">
        <div className="flex justify-between items-center">
          <div className="h-9 w-32">
            <Skeleton className="h-9 w-32" />
          </div>
          <div className="h-9 w-32">
            <Skeleton className="h-9 w-32" />
          </div>
        </div>

        <div className="flex gap-4 items-center">
          <div className="flex-1">
            <Skeleton className="h-10 w-[384px]" />
          </div>
          <Skeleton className="h-10 w-[180px]" />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {[...Array(6)].map((_, i) => (
            <div key={i} className="space-y-4">
              <Skeleton className="h-[200px] w-full rounded-xl" />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default async function AssetsPage() {
  return (
    <Suspense fallback={<AssetsLoading />}>
      <AssetsContent />
    </Suspense>
  );
}

async function AssetsContent() {
  const assets = await api.getAssets();

  // Group assets by type for better organization
  const groupedAssets = assets.reduce((acc, asset) => {
    const type = asset.asset_type;
    if (!acc[type]) {
      acc[type] = [];
    }
    acc[type].push(asset);
    return acc;
  }, {} as Record<string, typeof assets>);

  return <AssetsClient assets={assets} groupedAssets={groupedAssets} />;
} 