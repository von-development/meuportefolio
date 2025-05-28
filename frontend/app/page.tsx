import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import Link from "next/link";
import { BarChart3Icon, LineChart, Wallet, ArrowRight } from "lucide-react";

export default function Home() {
  return (
    <div className="flex flex-col min-h-screen">
      {/* Hero Section */}
      <section className="relative py-20 md:py-32 lg:py-40">
        {/* Background Effects */}
        <div className="absolute inset-0">
          <div className="absolute inset-0 bg-gradient-to-r from-blue-500/20 via-purple-500/20 to-pink-500/20 blur-3xl opacity-50" />
          <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:20px_20px]" />
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/80 to-background/0" />
        </div>

        <div className="container relative mx-auto px-4">
          <div className="flex flex-col items-center text-center space-y-8 max-w-3xl mx-auto">
            <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold bg-gradient-to-br from-white to-white/60 bg-clip-text text-transparent">
              Bem-vindo ao meuPortefólio
            </h1>
            <p className="text-xl md:text-2xl text-muted-foreground max-w-2xl">
              Gerencie seus investimentos de forma simples e eficiente com nossa plataforma completa de gestão de portfólio.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 sm:gap-6 w-full sm:w-auto">
              <Button size="lg" className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-lg text-white" asChild>
                <Link href="/signup">Criar Conta</Link>
              </Button>
              <Button size="lg" variant="outline" className="border-blue-700/20 hover:bg-blue-700/10 text-lg text-white" asChild>
                <Link href="/login">Entrar</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-20 container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-3xl font-bold mb-4">Por que escolher o meuPortefólio?</h2>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            Nossa plataforma oferece todas as ferramentas necessárias para você gerenciar seus investimentos com confiança.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16">
          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60 hover:bg-card/80 transition-all border-blue-700/20">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Wallet className="h-5 w-5 text-blue-500" />
                Ativos Diversificados
              </CardTitle>
              <CardDescription>Acesso a diversos tipos de investimentos</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Invista em ações, índices, criptomoedas e commodities em uma única plataforma.</p>
            </CardContent>
          </Card>

          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60 hover:bg-card/80 transition-all border-blue-700/20">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <LineChart className="h-5 w-5 text-purple-500" />
                Gestão Simplificada
              </CardTitle>
              <CardDescription>Acompanhamento em tempo real</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Monitore seu portfólio com facilidade e tome decisões informadas sobre seus investimentos.</p>
            </CardContent>
          </Card>

          <Card className="bg-card/50 backdrop-blur supports-[backdrop-filter]:bg-background/60 hover:bg-card/80 transition-all border-blue-700/20">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <BarChart3Icon className="h-5 w-5 text-pink-500" />
                Análise Detalhada
              </CardTitle>
              <CardDescription>Métricas e insights importantes</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-muted-foreground">Acesse análises detalhadas de risco e desempenho para otimizar seus investimentos.</p>
            </CardContent>
          </Card>
        </div>

        <div className="text-center">
          <Button 
            size="lg" 
            className="group bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 hover:from-blue-600 hover:via-purple-600 hover:to-pink-600 transition-all duration-300 shadow-lg hover:shadow-xl text-lg px-8 text-white" 
            asChild
          >
            <Link href="/assets" className="flex items-center gap-2">
              Explorar Ativos Disponíveis
              <ArrowRight className="h-5 w-5 transition-transform group-hover:translate-x-1" />
            </Link>
          </Button>
        </div>
      </section>
    </div>
  );
}
