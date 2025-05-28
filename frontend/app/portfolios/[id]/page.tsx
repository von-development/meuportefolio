'use client';

import { api, APIError } from "@/lib/api";
import { notFound } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { BarChart3Icon, TrendingUpIcon, TrendingDownIcon, CalendarIcon, WalletIcon, ArrowLeftIcon } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import type { Portfolio } from "@/lib/api";
import { use } from "react";
import { ErrorBoundary } from "@/components/error-boundary";
import { formatDate } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import Link from "next/link";

interface PageProps {
  params: Promise<{ id: string }>;
}

type AppError = Error | APIError;

function isAppError(error: unknown): error is AppError {
  return error instanceof Error || error instanceof APIError;
}

export default function PortfolioPage({ params }: PageProps) {
  const { id } = use(params);
  const [portfolio, setPortfolio] = useState<Portfolio | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<AppError | null>(null);

  const fetchData = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);

      const portfolioData = await api.getPortfolioDetails(id);
      setPortfolio(portfolioData);
    } catch (err) {
      console.error('Error fetching data:', err);
      if (err instanceof APIError && err.status === 404) {
        notFound();
      } else {
        setError(isAppError(err) ? err : new Error('An unexpected error occurred'));
      }
    } finally {
      setIsLoading(false);
    }
  }, [id]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  if (error) {
    return <ErrorBoundary error={error} reset={fetchData} />;
  }

  if (isLoading || !portfolio) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-background">
        <div className="animate-spin rounded-full h-32 w-32 border-t-2 border-b-2 border-blue-500"></div>
      </div>
    );
  }

  const formatCurrency = (value: number) => {
    return new Intl.NumberFormat('pt-BR', {
      style: 'currency',
      currency: 'EUR'
    }).format(value);
  };

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="relative w-full bg-gradient-to-r from-blue-600 via-blue-700 to-blue-800">
        {/* Background Pattern */}
        <div className="absolute inset-0 bg-grid-white/[0.05] bg-[size:20px_20px]" />
        
        {/* Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-background/80 to-background/20" />
        
        <div className="relative container mx-auto px-4 py-16">
          <div className="flex flex-col space-y-4">
            <Button variant="ghost" className="w-fit text-white hover:text-white/80 -ml-4" asChild>
              <Link href={`/users/${portfolio.user_id}`}>
                <ArrowLeftIcon className="h-4 w-4 mr-2" />
                Voltar
              </Link>
            </Button>
            <div className="flex items-center gap-4">
              <h1 className="text-3xl font-bold text-white">{portfolio.name}</h1>
              {portfolio.current_profit_pct > 0 ? (
                <TrendingUpIcon className="h-6 w-6 text-green-400" />
              ) : (
                <TrendingDownIcon className="h-6 w-6 text-red-400" />
              )}
            </div>
          </div>
        </div>
      </div>
      
      <div className="container mx-auto px-4 py-8 space-y-8">
        {/* Quick Stats */}
        <div className="grid gap-6 md:grid-cols-3">
          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <WalletIcon className="h-5 w-5 text-blue-500" />
                Saldo Atual
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-3xl font-bold">{formatCurrency(portfolio.current_funds)}</div>
            </CardContent>
          </Card>

          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <BarChart3Icon className="h-5 w-5 text-green-500" />
                Lucro
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className={`text-3xl font-bold ${
                portfolio.current_profit_pct > 0 ? 'text-green-500' : 'text-red-500'
              }`}>
                {portfolio.current_profit_pct.toFixed(2)}%
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-lg">
                <CalendarIcon className="h-5 w-5 text-purple-500" />
                Data de Criação
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-medium">
                {formatDate(portfolio.creation_date)}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Transactions will be added here */}
        <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <BarChart3Icon className="h-5 w-5 text-blue-500" />
              Transações
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground text-center py-8">
              Funcionalidade de transações em desenvolvimento...
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 