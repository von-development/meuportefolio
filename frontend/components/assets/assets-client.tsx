'use client';

import * as React from "react";
import { Asset } from "@/lib/api";
import { AssetCard } from "./asset-card";
import { Input } from "@/components/ui/input";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { cn } from "@/lib/utils";
import { useEffect, useState } from "react";
import { Skeleton } from "@/components/ui/skeleton";

interface AssetsClientProps {
  assets: Asset[];
  groupedAssets: Record<string, Asset[]>;
}

export function AssetsClient({ assets, groupedAssets }: AssetsClientProps) {
  const [search, setSearch] = React.useState("");
  const [selectedTab, setSelectedTab] = React.useState("all");
  const [isClient, setIsClient] = useState(false);

  useEffect(() => {
    setIsClient(true);
  }, []);

  // Get unique asset types and sort them
  const assetTypes = ["all", ...Object.keys(groupedAssets)].map(type => ({
    value: type,
    label: type === "all" ? "Todos" : 
           type === "Company" ? "Ações" :
           type === "Cryptocurrency" ? "Criptomoedas" :
           type === "Index" ? "Índices" :
           type === "Commodity" ? "Commodities" : type
  }));

  // Filter assets based on search and type
  const filteredAssets = React.useMemo(() => {
    let filtered = assets;

    // Filter by type if not "all"
    if (selectedTab !== "all") {
      filtered = filtered.filter((asset) => asset.asset_type === selectedTab);
    }

    // Filter by search term
    if (search) {
      const searchLower = search.toLowerCase();
      filtered = filtered.filter(
        (asset) =>
          asset.name.toLowerCase().includes(searchLower) ||
          asset.symbol.toLowerCase().includes(searchLower)
      );
    }

    return filtered;
  }, [assets, search, selectedTab]);

  if (!isClient) {
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

  return (
    <div className="container mx-auto py-10 space-y-8">
      <div className="flex flex-col space-y-4">
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold tracking-tight">Ativos</h1>
          <div className="w-full max-w-sm">
            <Input
              placeholder="Pesquisar por nome ou símbolo..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full"
            />
          </div>
        </div>
      </div>

      <Tabs defaultValue="all" value={selectedTab} onValueChange={setSelectedTab}>
        <TabsList className="w-full justify-start h-12 bg-muted/50 p-1">
          {assetTypes.map(({ value, label }) => (
            <TabsTrigger
              key={value}
              value={value}
              className={cn(
                "flex-1 max-w-[200px] h-10",
                "data-[state=active]:bg-background data-[state=active]:text-foreground",
                "data-[state=active]:shadow-sm"
              )}
            >
              {label}
            </TabsTrigger>
          ))}
        </TabsList>

        {assetTypes.map(({ value }) => (
          <TabsContent key={value} value={value} className="mt-6">
            {filteredAssets.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredAssets.map((asset) => (
                  <AssetCard key={asset.asset_id} asset={asset} />
                ))}
              </div>
            ) : (
              <div className="text-center py-10">
                <p className="text-muted-foreground">
                  {assets.length === 0 
                    ? "Carregando ativos..." 
                    : "Nenhum ativo encontrado com os filtros selecionados."}
                </p>
              </div>
            )}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
} 