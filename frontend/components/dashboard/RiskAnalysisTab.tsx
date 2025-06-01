'use client'

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { AlertTriangle, BarChart3, TrendingUp, Crown, Lock } from 'lucide-react'

interface RiskAnalysisTabProps {
  userId: string | undefined
  formatCurrency: (amount: number) => string
}

export default function RiskAnalysisTab({ userId, formatCurrency }: RiskAnalysisTabProps) {
  return (
    <div className="space-y-6">
      {/* Premium Feature Notice */}
      <Card className="bg-gradient-to-br from-yellow-900/40 to-orange-900/40 border-yellow-600/40">
        <CardHeader>
          <CardTitle className="text-yellow-300 flex items-center">
            <Crown className="h-5 w-5 mr-2" />
            Funcionalidade Premium
          </CardTitle>
          <CardDescription className="text-yellow-400/80">
            Esta funcionalidade está disponível apenas para utilizadores Premium
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center p-3 rounded-lg bg-yellow-950/30 border border-yellow-800/40">
            <Lock className="h-5 w-5 text-yellow-400 mr-3" />
            <p className="text-yellow-200 text-sm">
              Acesso exclusivo para subscritores Premium. Analise o risco dos seus investimentos com algoritmos avançados.
            </p>
          </div>
        </CardContent>
      </Card>

      {/* Risk Analysis Preview */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <AlertTriangle className="h-5 w-5 mr-2" />
            Análise de Risco Avançada
          </CardTitle>
          <CardDescription className="text-gray-400">
            Ferramentas profissionais para análise de risco do portfólio
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="space-y-6">
            {/* Feature List */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="space-y-4">
                <h4 className="text-white font-medium flex items-center">
                  <BarChart3 className="h-4 w-4 mr-2 text-blue-400" />
                  Métricas de Risco
                </h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Value at Risk (VaR)</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Beta do Portfólio</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Sharpe Ratio</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Volatilidade</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                </div>
              </div>

              <div className="space-y-4">
                <h4 className="text-white font-medium flex items-center">
                  <TrendingUp className="h-4 w-4 mr-2 text-green-400" />
                  Análises Avançadas
                </h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Correlação de Ativos</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Stress Testing</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Simulação Monte Carlo</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                  <div className="flex items-center justify-between p-3 rounded-lg bg-gray-800/40 border border-gray-700">
                    <span className="text-gray-300">Recomendações AI</span>
                    <Badge variant="outline" className="border-gray-600 text-gray-400">Premium</Badge>
                  </div>
                </div>
              </div>
            </div>

            {/* Mock Risk Dashboard */}
            <div className="border-2 border-dashed border-gray-600 rounded-lg p-8 text-center bg-gray-800/20">
              <AlertTriangle className="h-16 w-16 mx-auto mb-4 text-gray-500" />
              <h3 className="text-lg font-medium text-white mb-2">Dashboard de Risco</h3>
              <p className="text-gray-400 mb-6">
                Visualização interativa dos riscos do seu portfólio aparecerá aqui
              </p>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Risco Baixo</p>
                  <p className="text-green-400 text-2xl font-bold">--</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Risco Médio</p>
                  <p className="text-yellow-400 text-2xl font-bold">--</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Risco Alto</p>
                  <p className="text-red-400 text-2xl font-bold">--</p>
                </div>
                <div className="bg-gray-800/40 p-4 rounded-lg border border-gray-700">
                  <p className="text-gray-400 text-sm">Score Geral</p>
                  <p className="text-blue-400 text-2xl font-bold">--</p>
                </div>
              </div>
              <Button disabled className="bg-gray-600 text-gray-300">
                <Lock className="h-4 w-4 mr-2" />
                Análise Bloqueada
              </Button>
            </div>

            {/* Coming Soon Notice */}
            <div className="text-center py-6">
              <p className="text-gray-400 mb-4">
                Funcionalidade de análise de risco em desenvolvimento
              </p>
              <p className="text-gray-500 text-sm">
                Esta funcionalidade estará disponível em breve para utilizadores Premium
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 