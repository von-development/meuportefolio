'use client';

import * as React from "react";
import { Asset, AssetPriceHistory } from "@/lib/api";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { formatNumber, formatPercentage, formatUSD } from "@/lib/utils";
import Image from "next/image";
import { Badge } from "@/components/ui/badge";
import { TrendingDown, TrendingUp } from "lucide-react";
import { cn } from "@/lib/utils";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";

interface AssetDetailsProps {
  asset: Asset;
  priceHistory: AssetPriceHistory[];
}

export function AssetDetails({ asset, priceHistory }: AssetDetailsProps) {
  // Generate a consistent random variation based on asset_id
  const getPriceVariation = (id: number): number => {
    const seed = Math.sin(id) * 10000;
    return parseFloat((Math.sin(seed) * 5).toFixed(2));
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
        return [`/images/default-asset.svg`];
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

  // Format data for the chart
  const chartData = priceHistory.map(history => ({
    timestamp: new Date(history.timestamp).toLocaleDateString('pt-BR'),
    price: history.price,
    volume: history.volume,
  })).reverse(); // Reverse to show oldest to newest

  return (
    <div className="space-y-6">
      {/* Asset Header */}
      <Card>
        <CardHeader className="flex flex-row items-center gap-4 pb-2 space-y-0">
          <div className="relative h-16 w-16 overflow-hidden rounded-full bg-muted">
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
              <h1 className="text-2xl font-bold">{asset.name}</h1>
              <Badge variant="outline" className="font-medium text-lg">
                {asset.symbol}
              </Badge>
            </div>
            <p className="text-muted-foreground">
              {asset.asset_type}
            </p>
          </div>
        </CardHeader>
      </Card>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Price Information */}
        <Card>
          <CardContent className="pt-6">
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Preço Atual:</span>
                <div className="flex items-center gap-2">
                  <span className="text-xl font-bold tabular-nums">
                    {formatUSD(asset.price)}
                  </span>
                  <div className={cn(
                    "flex items-center gap-1 text-sm font-medium tabular-nums",
                    priceVariation >= 0 ? "text-green-500" : "text-red-500"
                  )}>
                    {priceVariation >= 0 ? <TrendingUp className="h-4 w-4" /> : <TrendingDown className="h-4 w-4" />}
                    {formatPercentage(priceVariation)}
                  </div>
                </div>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Volume 24h:</span>
                <span className="font-medium tabular-nums">
                  {formatUSD(asset.volume)}
                </span>
              </div>

              {asset.available_shares > 0 && (
                <>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Ações Disponíveis:</span>
                    <span className="font-medium tabular-nums">
                      {formatNumber(asset.available_shares)}
                    </span>
                  </div>

                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Market Cap:</span>
                    <span className="font-medium tabular-nums">
                      {formatUSD(marketCap)}
                    </span>
                  </div>
                </>
              )}

              <div className="flex items-center justify-between">
                <span className="text-muted-foreground">Última Atualização:</span>
                <span className="font-medium">
                  {new Date(asset.last_updated).toLocaleString('pt-BR')}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Price History Chart */}
        <Card>
          <CardContent className="pt-6">
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData}>
                  <defs>
                    <linearGradient id="priceGradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#2563eb" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#2563eb" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis 
                    dataKey="timestamp" 
                    tickFormatter={(value) => value}
                    angle={-45}
                    textAnchor="end"
                    height={60}
                  />
                  <YAxis 
                    tickFormatter={(value) => formatUSD(value)}
                    width={80}
                  />
                  <Tooltip 
                    formatter={(value: any) => [formatUSD(value), "Preço"]}
                    labelFormatter={(label) => `Data: ${label}`}
                  />
                  <Area
                    type="monotone"
                    dataKey="price"
                    stroke="#2563eb"
                    fillOpacity={1}
                    fill="url(#priceGradient)"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 