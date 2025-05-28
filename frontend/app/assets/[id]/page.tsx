import { api } from "@/lib/api";
import { AssetDetails } from "@/components/assets/asset-details";

interface AssetPageProps {
  params: {
    id: string;
  };
}

export default async function AssetPage({ params }: AssetPageProps) {
  const assetId = parseInt(params.id);
  const [asset, priceHistory] = await Promise.all([
    api.getAssetDetails(assetId),
    api.getAssetPriceHistory(assetId),
  ]);

  return (
    <div className="container py-6">
      <AssetDetails asset={asset} priceHistory={priceHistory} />
    </div>
  );
} 