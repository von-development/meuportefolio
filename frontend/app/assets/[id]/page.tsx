import { api } from "@/lib/api";
import { AssetDetails } from "@/components/assets/asset-details";
import { notFound } from "next/navigation";

interface PageProps {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function AssetPage({ params }: PageProps) {
  try {
    const { id } = await params;
    const assetId = parseInt(id);
    const [asset, priceHistory] = await Promise.all([
      api.getAssetDetails(assetId),
      api.getAssetPriceHistory(assetId),
    ]);

    return (
      <div className="container py-6">
        <AssetDetails asset={asset} priceHistory={priceHistory} />
      </div>
    );
  } catch (error) {
    console.error('Error fetching asset data:', error);
    notFound();
  }
} 