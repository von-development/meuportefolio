import { api } from "@/lib/api";
import { notFound } from "next/navigation";
import { UserProfileHeader } from "@/components/users/user-profile-header";
import { UserPortfolios } from "@/components/users/user-portfolios";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { CreditCardIcon, UserIcon, BarChart3Icon } from "lucide-react";
import type { User, Portfolio } from "@/lib/api";
import { formatDate } from "@/lib/utils";

interface PageProps {
  params: Promise<{ id: string }>;
}

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function UserPage({ params }: PageProps) {
  try {
    const { id } = await params;
    
    const [user, portfolios] = await Promise.all([
      api.getUserDetails(id),
      api.getPortfolios(id)
    ]);

    if (!user) {
      notFound();
    }

    // Calculate portfolio statistics
    const totalFunds = portfolios.reduce((acc, p) => acc + p.current_funds, 0);
    const averageProfit = portfolios.length > 0
      ? portfolios.reduce((acc, p) => acc + p.current_profit_pct, 0) / portfolios.length
      : 0;

    return (
      <div className="min-h-screen bg-background">
        <UserProfileHeader user={user} />
        
        <div className="container mx-auto px-4 py-8 space-y-8">
          {/* Quick Stats */}
          <div className="grid gap-6 md:grid-cols-3">
            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <BarChart3Icon className="h-5 w-5 text-blue-500" />
                  Total de Portfólios
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold">{portfolios.length}</div>
              </CardContent>
            </Card>

            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <CreditCardIcon className="h-5 w-5 text-green-500" />
                  Saldo Total
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold">
                  {new Intl.NumberFormat('pt-BR', {
                    style: 'currency',
                    currency: 'EUR'
                  }).format(totalFunds)}
                </div>
              </CardContent>
            </Card>

            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-lg">
                  <BarChart3Icon className="h-5 w-5 text-amber-500" />
                  Lucro Médio
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="text-3xl font-bold">
                  {averageProfit.toFixed(2)}%
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Account Details */}
          <div className="grid gap-6 md:grid-cols-2">
            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <UserIcon className="h-5 w-5 text-purple-500" />
                  Informações Pessoais
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="text-sm text-muted-foreground">País</p>
                    <p className="text-lg font-medium">{user.country_of_residence}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Tipo de Conta</p>
                    <p className={`text-lg font-medium ${user.user_type === 'Premium' ? 'text-amber-500' : 'text-zinc-400'}`}>
                      {user.user_type}
                    </p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Email</p>
                    <p className="text-lg font-medium">{user.email}</p>
                  </div>
                  <div>
                    <p className="text-sm text-muted-foreground">Criado em</p>
                    <p className="text-lg font-medium">{formatDate(user.created_at)}</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <CreditCardIcon className="h-5 w-5 text-indigo-500" />
                  Detalhes Bancários
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div>
                  <p className="text-sm text-muted-foreground">IBAN</p>
                  <p className="text-lg font-medium font-mono">{user.iban}</p>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Portfolios */}
          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3Icon className="h-5 w-5 text-blue-500" />
                Portfólios
              </CardTitle>
            </CardHeader>
            <CardContent>
              <UserPortfolios 
                portfolios={portfolios}
                userId={id}
              />
            </CardContent>
          </Card>
        </div>
      </div>
    );
  } catch (error) {
    console.error('Error fetching user data:', error);
    notFound();
  }
} 