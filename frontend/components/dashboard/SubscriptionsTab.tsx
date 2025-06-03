'use client'

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { api } from '@/lib/api'
import { 
  Crown, 
  CreditCard, 
  Calendar, 
  CheckCircle, 
  AlertCircle, 
  Shield,
  Star,
  Zap,
  BarChart3,
  TrendingUp,
  Settings,
  DollarSign
} from 'lucide-react'

interface ExtendedUser {
  user_id: string
  name: string
  email: string
  country_of_residence: string
  iban: string
  user_type: string
  account_balance: number
  payment_method_type?: string
  payment_method_details?: string
  payment_method_expiry?: string
  payment_method_active: boolean
  is_premium: boolean
  premium_start_date?: string
  premium_end_date?: string
  monthly_subscription_rate?: number
  auto_renew_subscription: boolean
  last_subscription_payment?: string
  next_subscription_payment?: string
  days_remaining_in_subscription: number
  subscription_expired: boolean
  created_at: string
  updated_at: string
}

interface SubscriptionsTabProps {
  userComplete: ExtendedUser | null
  onRefresh: () => void
  formatCurrency: (amount: number) => string
}

export default function SubscriptionsTab({ userComplete, onRefresh, formatCurrency }: SubscriptionsTabProps) {
  const [isUpgrading, setIsUpgrading] = useState(false)
  const [upgradeError, setUpgradeError] = useState('')
  const [upgradeSuccess, setUpgradeSuccess] = useState('')
  const [isCancelling, setIsCancelling] = useState(false)
  const [cancelError, setCancelError] = useState('')
  const [cancelSuccess, setCancelSuccess] = useState('')

  const handleUpgradeToPremium = async () => {
    if (!userComplete?.payment_method_active) {
      setUpgradeError('É necessário configurar um método de pagamento antes de fazer upgrade para Premium.')
      return
    }

    // Check if user is already premium
    if (userComplete.is_premium) {
      setUpgradeError('Já é um utilizador Premium.')
      return
    }

    try {
      setIsUpgrading(true)
      setUpgradeError('')
      setUpgradeSuccess('')

      const response = await api.post(`/users/${userComplete.user_id}/upgrade-premium`, {
        subscription_type: 'monthly',
        auto_renew: true
      })

      if (response.ok) {
        setUpgradeSuccess('Upgrade para Premium realizado com sucesso! Bem-vindo ao meuPortfólio Premium!')
        // Wait a moment before refreshing to ensure backend has processed the change
        setTimeout(() => {
          onRefresh()
        }, 1000)
      } else {
        const errorData = await response.text()
        setUpgradeError(`Erro no upgrade: ${errorData}`)
      }
    } catch (error) {
      console.error('Upgrade failed:', error)
      setUpgradeError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsUpgrading(false)
    }
  }

  const handleCancelSubscription = async () => {
    if (!confirm('Tem a certeza que deseja cancelar a sua subscrição Premium? Perderá acesso às funcionalidades premium no final do período atual.')) {
      return
    }

    try {
      setIsCancelling(true)
      setCancelError('')
      setCancelSuccess('')

      const response = await api.post(`/users/${userComplete?.user_id}/subscription`, {
        action: 'CANCEL'
      })

      if (response.ok) {
        setCancelSuccess('Subscrição cancelada com sucesso. Continuará a ter acesso premium até ao final do período atual.')
        // Wait a moment before refreshing to ensure backend has processed the change
        setTimeout(() => {
          onRefresh()
        }, 1000)
      } else {
        const errorData = await response.text()
        setCancelError(`Erro ao cancelar subscrição: ${errorData}`)
      }
    } catch (error) {
      console.error('Cancellation failed:', error)
      setCancelError('Erro de conexão. Tente novamente.')
    } finally {
      setIsCancelling(false)
    }
  }

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleDateString('pt-PT')
  }

  if (!userComplete) {
    return (
      <div className="text-center py-8">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-400"></div>
        <p className="text-gray-400 mt-4">A carregar dados...</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Current Subscription Status */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Crown className="h-5 w-5 mr-2" />
            Estado da Subscrição
          </CardTitle>
          <CardDescription className="text-gray-400">
            Informações sobre o seu plano atual
          </CardDescription>
        </CardHeader>
        <CardContent>
          {userComplete.is_premium ? (
            <div className="space-y-6">
              {/* Premium Status */}
              <div className="flex items-center justify-between p-6 rounded-lg bg-gradient-to-r from-yellow-900/40 to-yellow-800/40 border border-yellow-600/40">
                <div className="flex items-center">
                  <div className="bg-yellow-500/20 rounded-full p-3 mr-4">
                    <Crown className="h-8 w-8 text-yellow-400" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-white">meuPortfólio Premium</h3>
                    <p className="text-yellow-200">Plano premium ativo</p>
                  </div>
                </div>
                <Badge className="bg-yellow-100 text-yellow-800 text-lg px-4 py-2">
                  <Crown className="h-4 w-4 mr-2" />
                  Premium
                </Badge>
              </div>

              {/* Subscription Details */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Valor mensal</span>
                    <span className="text-white font-bold text-lg">
                      {formatCurrency(userComplete.monthly_subscription_rate || 50)}
                    </span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Data de início</span>
                    <span className="text-white">{formatDate(userComplete.premium_start_date)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Próxima renovação</span>
                    <span className="text-white">{formatDate(userComplete.premium_end_date)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Dias restantes</span>
                    <span className={`font-bold ${userComplete.days_remaining_in_subscription <= 7 ? 'text-red-400' : 'text-green-400'}`}>
                      {userComplete.days_remaining_in_subscription} dias
                    </span>
                  </div>
                </div>

                <div className="space-y-4">
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Último pagamento</span>
                    <span className="text-white">{formatDate(userComplete.last_subscription_payment)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Próximo pagamento</span>
                    <span className="text-white">{formatDate(userComplete.next_subscription_payment)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Renovação automática</span>
                    <Badge variant={userComplete.auto_renew_subscription ? "secondary" : "outline"}>
                      {userComplete.auto_renew_subscription ? 'Ativa' : 'Inativa'}
                    </Badge>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-gray-300">Estado</span>
                    <Badge className={userComplete.subscription_expired ? "bg-red-100 text-red-800" : "bg-green-100 text-green-800"}>
                      {userComplete.subscription_expired ? 'Expirada' : 'Ativa'}
                    </Badge>
                  </div>
                </div>
              </div>

              {/* Subscription Actions */}
              <div className="pt-4 border-t border-gray-700">
                <h4 className="text-white font-medium mb-4 flex items-center">
                  <Settings className="h-4 w-4 mr-2" />
                  Gerir Subscrição
                </h4>
                
                <div className="space-y-4">
                  <div className="p-4 rounded-lg border border-gray-700 bg-gray-800/40">
                    <div className="mb-3">
                      <p className="text-white font-medium">Renovação Automática</p>
                      <p className="text-gray-400 text-sm">
                        {userComplete.auto_renew_subscription ? 
                          'A sua subscrição será renovada automaticamente' : 
                          'A sua subscrição não será renovada automaticamente'
                        }
                      </p>
                    </div>
                    <Badge variant={userComplete.auto_renew_subscription ? "secondary" : "outline"}>
                      {userComplete.auto_renew_subscription ? 'Ativa' : 'Inativa'}
                    </Badge>
                  </div>

                  <div className="flex gap-3">
                    <Button 
                      onClick={handleCancelSubscription}
                      disabled={isCancelling}
                      variant="outline"
                      className="border-red-600 text-red-400 hover:bg-red-600 hover:text-white"
                    >
                      {isCancelling ? (
                        <div className="flex items-center">
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          A cancelar...
                        </div>
                      ) : (
                        'Cancelar Subscrição'
                      )}
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          ) : (
            <div className="text-center py-8">
              <div className="bg-gray-700/50 rounded-full w-20 h-20 flex items-center justify-center mx-auto mb-6">
                <Crown className="h-10 w-10 text-gray-400" />
              </div>
              <h3 className="text-xl font-bold text-white mb-2">Plano Básico</h3>
              <p className="text-gray-400 mb-6">Está atualmente no plano básico gratuito</p>
              <Badge variant="outline" className="border-gray-600 text-gray-300 text-base px-4 py-2">
                Básico - Gratuito
              </Badge>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Premium Features & Upgrade */}
      {!userComplete.is_premium && (
        <Card className="bg-gradient-to-br from-yellow-900/20 to-yellow-800/20 backdrop-blur-sm border border-yellow-600/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center">
              <Star className="h-5 w-5 mr-2 text-yellow-400" />
              Upgrade para Premium
            </CardTitle>
            <CardDescription className="text-gray-300">
              Desbloqueie funcionalidades avançadas e análises detalhadas
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Premium Features */}
            <div className="space-y-4">
              <h4 className="text-white font-medium">Funcionalidades Premium:</h4>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">Análise de risco avançada</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">Relatórios detalhados</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">Alertas personalizados</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">Suporte prioritário</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">API de dados avançada</span>
                </div>
                <div className="flex items-center">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <span className="text-gray-300">Portfólios ilimitados</span>
                </div>
              </div>
            </div>

            {/* Pricing */}
            <div className="bg-gradient-to-r from-yellow-600/20 to-yellow-500/20 rounded-lg p-6 border border-yellow-500/30">
              <div className="text-center">
                <div className="text-3xl font-bold text-white mb-2">
                  {formatCurrency(50)}
                  <span className="text-lg font-normal text-gray-300">/mês</span>
                </div>
                <p className="text-yellow-200 mb-4">Cancele a qualquer momento</p>
                
                {!userComplete.payment_method_active ? (
                  <div className="mb-4">
                    <div className="flex items-center justify-center p-3 rounded-lg bg-orange-950/50 border border-orange-600/40 mb-3">
                      <AlertCircle className="h-5 w-5 text-orange-400 mr-3" />
                      <p className="text-orange-200 text-sm">
                        Configure um método de pagamento primeiro
                      </p>
                    </div>
                    <Button asChild variant="outline" className="border-yellow-600 text-yellow-400">
                      <a href="#pagamentos">Configurar Pagamento</a>
                    </Button>
                  </div>
                ) : (
                  <Button 
                    onClick={handleUpgradeToPremium}
                    disabled={isUpgrading}
                    className="bg-gradient-to-r from-yellow-600 to-yellow-500 hover:from-yellow-700 hover:to-yellow-600 text-white font-medium px-8 py-3"
                  >
                    {isUpgrading ? (
                      <div className="flex items-center">
                        <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                        A processar upgrade...
                      </div>
                    ) : (
                      <>
                        <Crown className="h-5 w-5 mr-2" />
                        Upgrade para Premium
                      </>
                    )}
                  </Button>
                )}
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Messages */}
      {(upgradeError || cancelError) && (
        <div className="flex items-center p-4 rounded-lg bg-red-950/50 border border-red-800/40">
          <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
          <p className="text-red-300 text-sm">{upgradeError || cancelError}</p>
        </div>
      )}

      {(upgradeSuccess || cancelSuccess) && (
        <div className="flex items-center p-4 rounded-lg bg-green-950/50 border border-green-800/40">
          <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
          <p className="text-green-300 text-sm">{upgradeSuccess || cancelSuccess}</p>
        </div>
      )}

      {/* Payment Method Notice for Premium Users */}
      {userComplete.is_premium && !userComplete.payment_method_active && (
        <Card className="bg-gradient-to-br from-red-900/20 to-red-800/20 backdrop-blur-sm border border-red-600/40">
          <CardHeader>
            <CardTitle className="text-red-400 flex items-center">
              <AlertCircle className="h-5 w-5 mr-2" />
              Ação Necessária
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-gray-300 mb-4">
              O seu método de pagamento não está ativo. Configure um método de pagamento para garantir que a sua subscrição premium não seja interrompida.
            </p>
            <Button asChild className="bg-red-600 hover:bg-red-700">
              <a href="#pagamentos">
                <CreditCard className="h-4 w-4 mr-2" />
                Configurar Método de Pagamento
              </a>
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  )
} 