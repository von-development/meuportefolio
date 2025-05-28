'use client';

import * as React from "react";
import { Asset } from "@/lib/api";
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card";
import { formatNumber, formatPercentage, formatUSD } from "@/lib/utils";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { TrendingDown, TrendingUp } from "lucide-react";
import { cn } from "@/lib/utils";

interface AssetCardProps {
  asset: Asset;
}

export function AssetCard({ asset }: AssetCardProps) {
  // Generate a consistent random variation based on asset_id
  const getPriceVariation = (id: number): number => {
    // Use the asset ID as a seed for consistent randomness
    const seed = Math.sin(id) * 10000;
    return parseFloat((Math.sin(seed) * 5).toFixed(2)); // Returns -5 to +5
  };

  const priceVariation = getPriceVariation(asset.asset_id);
  const marketCap = asset.price * (asset.available_shares || 0);

  // Function to get the asset logo based on type and symbol
  const getAssetLogo = (type: string, symbol: string, name: string) => {
    const cleanSymbol = symbol.toLowerCase();
    const cleanName = name.toLowerCase().replace(/[^a-z0-9]/g, '');
    
    switch (type) {
      case 'Company':
        return [
          `https://companieslogo.com/img/orig/${symbol}-040ea85d.png`,
          `https://logo.clearbit.com/${cleanName}.com`,
          `/images/default-asset.svg`
        ];
      case 'Cryptocurrency':
        return [
          `https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/128/color/${cleanSymbol}.png`,
          `https://assets.coincap.io/assets/icons/${cleanSymbol}@2x.png`,
          `https://cryptologos.cc/logos/${cleanName}-${cleanSymbol}-logo.png`,
          `/images/default-asset.svg`
        ];
      case 'Index':
        const indexLogos: Record<string, string> = {
          'SPX': 'https://s3.symbol-logo.com/sp500-logo.png',
          'NDX': 'https://s3.symbol-logo.com/nasdaq-logo.png',
          'IBOV': 'https://s3.symbol-logo.com/ibovespa-logo.png',
          'PSI': 'https://s3.symbol-logo.com/psi-logo.png',
          'DAX': 'https://s3.symbol-logo.com/dax-logo.png',
        };
        return [indexLogos[symbol] || `/images/default-asset.svg`];
      case 'Commodity':
        const commodityLogos: Record<string, string> = {
          'GC': '/images/default-asset.svg',
          'SI': '/images/default-asset.svg',
          'CL': '/images/default-asset.svg',
          'NG': '/images/default-asset.svg',
          'HG': '/images/default-asset.svg',
        };
        return [commodityLogos[symbol] || `/images/default-asset.svg`];
      default:
        return ['/images/default-asset.svg'];
    }
  };

  const [currentLogoIndex, setCurrentLogoIndex] = React.useState(0);
  const logoUrls = getAssetLogo(asset.asset_type, asset.symbol, asset.name);

  const handleImageError = () => {
    if (currentLogoIndex < logoUrls.length - 1) {
      setCurrentLogoIndex(currentLogoIndex + 1);
    }
  };

  return (
    <Card className="hover:shadow-lg transition-shadow bg-card">
      <CardHeader className="flex flex-row items-center gap-4 pb-2 space-y-0">
        <div className="relative h-12 w-12 overflow-hidden rounded-full bg-muted">
          <Image
            src={logoUrls[currentLogoIndex]}
            alt={asset.name}
            fill
            className="object-cover"
            onError={handleImageError}
          />
        </div>
        <div className="flex flex-col flex-1">
          <div className="flex items-center gap-2">
            <p className="font-semibold text-lg">{asset.name}</p>
            <Badge variant="outline" className="font-medium">
              {asset.symbol}
            </Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            {asset.asset_type}
          </p>
        </div>
      </CardHeader>
      <CardContent className="pb-2">
        <div className="space-y-2.5">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Preço:</span>
            <div className="flex items-center gap-2 justify-end">
              <span className="font-medium tabular-nums">
                {formatUSD(asset.price)}
              </span>
              <div className={cn(
                "flex items-center gap-1 text-xs font-medium tabular-nums",
                priceVariation >= 0 ? "text-green-500" : "text-red-500"
              )}>
                {priceVariation >= 0 ? <TrendingUp className="h-3 w-3" /> : <TrendingDown className="h-3 w-3" />}
                {formatPercentage(priceVariation)}
              </div>
            </div>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Volume 24h:</span>
            <span className="text-sm tabular-nums">
              {formatUSD(asset.volume)}
            </span>
          </div>
          {asset.available_shares && (
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Market Cap:</span>
              <span className="text-sm tabular-nums">
                {formatUSD(marketCap)}
              </span>
            </div>
          )}
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Última Atualização:</span>
            <span className="text-sm tabular-nums">
              {new Date(asset.last_updated).toLocaleString('pt-BR', {
                day: '2-digit',
                month: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
              })}
            </span>
          </div>
        </div>
      </CardContent>
      <CardFooter className="pt-4">
        <Button className="w-full" variant="secondary" asChild>
          <Link href={`/assets/${asset.asset_id}`}>
            Ver Detalhes
          </Link>
        </Button>
      </CardFooter>
    </Card>
  );
} 