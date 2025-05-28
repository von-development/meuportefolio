'use client';

import { Portfolio, api } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { PlusIcon, TrendingUpIcon, TrendingDownIcon, BarChart3Icon } from "lucide-react";
import { formatDate } from "@/lib/utils";
import Link from "next/link";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";

interface UserPortfoliosProps {
  portfolios: Portfolio[];
  userId: string;
}

export function UserPortfolios({ portfolios: initialPortfolios, userId }: UserPortfoliosProps) {
  const [portfolios, setPortfolios] = useState(initialPortfolios);
  const router = useRouter();

  const handleCreatePortfolio = async () => {
    try {
      const newPortfolio = await api.createPortfolio(userId, {
        name: `Portfolio ${portfolios.length + 1}`,
        user_id: userId,
      });
      setPortfolios(prev => [...prev, newPortfolio]);
      toast.success("Portfólio criado com sucesso!");
      router.refresh();
    } catch (error) {
      console.error('Error creating portfolio:', error);
      toast.error("Não foi possível criar o portfólio. Tente novamente.");
    }
  };

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'EUR'
    }).format(value);
  };

  if (portfolios.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-center">
        <BarChart3Icon className="h-12 w-12 text-muted-foreground mb-4" />
        <p className="text-lg font-medium mb-2">Nenhum Portfólio</p>
        <p className="text-sm text-muted-foreground mb-4">
          Este usuário ainda não possui nenhum portfólio.
        </p>
        <Button onClick={handleCreatePortfolio} className="bg-blue-600 hover:bg-blue-700">
          <PlusIcon className="h-4 w-4 mr-2" />
          Criar Primeiro Portfólio
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-end">
        <Button onClick={handleCreatePortfolio} className="bg-blue-600 hover:bg-blue-700">
          <PlusIcon className="h-4 w-4 mr-2" />
          Novo Portfólio
        </Button>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {portfolios.map((portfolio) => (
          <Link key={portfolio.portfolio_id} href={`/portfolios/${portfolio.portfolio_id}`}>
            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60 hover:bg-card/80 transition-all cursor-pointer hover:shadow-lg hover:scale-[1.02] hover:border-blue-500/50">
              <CardContent className="p-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold">{portfolio.name}</h3>
                  {portfolio.current_profit_pct > 0 ? (
                    <TrendingUpIcon className="h-5 w-5 text-green-500" />
                  ) : (
                    <TrendingDownIcon className="h-5 w-5 text-red-500" />
                  )}
                </div>
                
                <div>
                  <div className="flex justify-between items-center pb-2 border-b border-border/50">
                    <span className="text-sm text-muted-foreground">Saldo Atual</span>
                    <span className="font-medium">{formatCurrency(portfolio.current_funds)}</span>
                  </div>
                  
                  <div className="flex justify-between items-center pb-2 border-b border-border/50">
                    <span className="text-sm text-muted-foreground">Lucro</span>
                    <span className={`font-medium ${
                      portfolio.current_profit_pct > 0 ? 'text-green-500' : 'text-red-500'
                    }`}>
                      {portfolio.current_profit_pct.toFixed(2)}%
                    </span>
                  </div>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-sm text-muted-foreground">Criado em</span>
                    <span className="text-sm">{formatDate(portfolio.creation_date)}</span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
} 