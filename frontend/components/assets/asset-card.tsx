'use client';

import * as React from "react";
import { Asset } from "@/lib/api";
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card";
import { formatCurrency, formatNumber } from "@/lib/utils";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import Image from "next/image";

interface AssetCardProps {
  asset: Asset;
}

export function AssetCard({ asset }: AssetCardProps) {
  // Function to get the asset logo based on type and symbol
  const getAssetLogo = (type: string, symbol: string, name: string) => {
    const cleanSymbol = symbol.toLowerCase();
    const cleanName = name.toLowerCase().replace(/[^a-z0-9]/g, '');
    
    switch (type) {
      case 'Company':
        // Try multiple sources for company logos
        return [
          `https://companieslogo.com/img/orig/${symbol}-040ea85d.png`,
          `https://logo.clearbit.com/${cleanName}.com`,
          `/images/default-asset.svg` // Default fallback
        ];
      case 'Cryptocurrency':
        // Try multiple sources for crypto logos
        return [
          `https://cdn.jsdelivr.net/gh/atomiclabs/cryptocurrency-icons@1a63530be6e374711a8554f31b17e4cb92c25fa5/128/color/${cleanSymbol}.png`,
          `https://assets.coincap.io/assets/icons/${cleanSymbol}@2x.png`,
          `https://cryptologos.cc/logos/${cleanName}-${cleanSymbol}-logo.png`,
          `/images/default-asset.svg` // Default fallback
        ];
      case 'Index':
        // Use a mapping for index logos
        const indexLogos: Record<string, string> = {
          'SPX': 'https://s3.symbol-logo.com/sp500-logo.png',
          'NDX': 'https://s3.symbol-logo.com/nasdaq-logo.png',
          'IBOV': 'https://s3.symbol-logo.com/ibovespa-logo.png',
          'PSI': 'https://s3.symbol-logo.com/psi-logo.png',
          'DAX': 'https://s3.symbol-logo.com/dax-logo.png',
        };
        return [indexLogos[symbol] || `/images/default-asset.svg`];
      case 'Commodity':
        // Use a mapping for commodity logos
        const commodityLogos: Record<string, string> = {
          'GC': '/images/default-asset.svg', // Gold
          'SI': '/images/default-asset.svg', // Silver
          'CL': '/images/default-asset.svg', // Crude Oil
          'NG': '/images/default-asset.svg', // Natural Gas
          'HG': '/images/default-asset.svg', // Copper
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
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center gap-4 pb-2">
        <div className="relative h-12 w-12 overflow-hidden rounded-full bg-muted">
          <Image
            src={logoUrls[currentLogoIndex]}
            alt={asset.name}
            fill
            className="object-cover"
            onError={handleImageError}
          />
        </div>
        <div className="flex flex-col">
          <p className="text-lg font-semibold">{asset.name}</p>
          <p className="text-sm text-muted-foreground">{asset.symbol}</p>
        </div>
      </CardHeader>
      <CardContent className="pb-2">
        <div className="grid gap-1">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Preço:</span>
            <span className="text-sm font-medium">{formatCurrency(asset.price)}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Volume:</span>
            <span className="text-sm">{formatNumber(asset.volume)}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Tipo:</span>
            <span className="text-sm capitalize">{asset.asset_type.toLowerCase()}</span>
          </div>
        </div>
      </CardContent>
      <CardFooter className="pt-4">
        <Button variant="outline" className="w-full" asChild>
          <Link href={`/assets/${asset.asset_id}`}>Ver Detalhes</Link>
        </Button>
      </CardFooter>
    </Card>
  );
} 