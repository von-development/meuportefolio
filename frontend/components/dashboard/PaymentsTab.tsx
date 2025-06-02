'use client'

import { useState, useEffect } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  CreditCard, 
  Edit, 
  Check, 
  X, 
  Plus, 
  AlertCircle,
  CheckCircle,
  Shield,
  Calendar,
  Info,
  ArrowUpCircle,
  ArrowDownCircle,
  RefreshCw,
  TrendingUp,
  TrendingDown,
  Clock,
  History
} from 'lucide-react'

interface ExtendedUser {
  payment_method_type?: string
  payment_method_details?: string
  payment_method_expiry?: string
  payment_method_active: boolean
}

interface FundTransaction {
  fund_transaction_id: number
  user_id: string
  portfolio_id?: number
  transaction_type: string
  amount: number
  balance_after: number
  description?: string
  created_at: string
}

interface PaymentsTabProps {
  userId: string | undefined
  userComplete: ExtendedUser | null
  onRefresh: () => void
}

export default function PaymentsTab({ userId, userComplete, onRefresh }: PaymentsTabProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  
  const [paymentData, setPaymentData] = useState({
    payment_method_type: userComplete?.payment_method_type || 'IBAN',
    payment_method_details: userComplete?.payment_method_details || '',
    payment_method_expiry: userComplete?.payment_method_expiry || ''
  })

  const [fundTransactions, setFundTransactions] = useState<FundTransaction[]>([])
  const [isLoadingTransactions, setIsLoadingTransactions] = useState(true)

  const handleSave = async () => {
    if (!paymentData.payment_method_details.trim()) {
      setError('Por favor, insira os detalhes do método de pagamento')
      return
    }

    // Basic IBAN validation for Portuguese IBANs
    if (paymentData.payment_method_type === 'IBAN') {
      const iban = paymentData.payment_method_details.replace(/\s/g, '')
      if (!iban.match(/^PT50[0-9]{21}$/)) {
        setError('Por favor, insira um IBAN português válido (formato: PT50 XXXX XXXX XXXX XXXX XXXX X)')
        return
      }
    }

    setIsLoading(true)
    setError('')
    setSuccess('')

    try {
      const requestBody = {
        payment_method_type: paymentData.payment_method_type,
        payment_method_details: paymentData.payment_method_details,
        payment_method_expiry: paymentData.payment_method_expiry || null
      }

      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/payment-method`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(requestBody),
      })

      if (response.ok) {
        const result = await response.json()
        setSuccess(result.message || 'Método de pagamento atualizado com sucesso!')
        setIsEditing(false)
        onRefresh() // Refresh the dashboard data
      } else {
        const errorData = await response.text()
        setError(`Erro ao atualizar método de pagamento: ${errorData}`)
      }
    } catch (error) {
      console.error('Payment method update failed:', error)
      setError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsLoading(false)
    }
  }

  const handleCancel = () => {
    setPaymentData({
      payment_method_type: userComplete?.payment_method_type || 'IBAN',
      payment_method_details: userComplete?.payment_method_details || '',
      payment_method_expiry: userComplete?.payment_method_expiry || ''
    })
    setIsEditing(false)
    setError('')
    setSuccess('')
  }

  const formatIBAN = (iban: string) => {
    // Format IBAN for display (hide middle digits)
    if (iban.length >= 8) {
      return `${iban.slice(0, 4)} **** **** ${iban.slice(-4)}`
    }
    return iban
  }

  const formatDate = (dateString?: string) => {
    if (!dateString) return 'N/A'
    return new Date(dateString).toLocaleDateString('pt-PT')
  }

  const fetchFundTransactions = async () => {
    if (!userId) return
    
    setIsLoadingTransactions(true)
    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/fund-transactions`)
      if (response.ok) {
        const data = await response.json()
        setFundTransactions(data)
      }
    } catch (error) {
      console.error('Failed to fetch fund transactions:', error)
    } finally {
      setIsLoadingTransactions(false)
    }
  }

  useEffect(() => {
    fetchFundTransactions()
  }, [userId])

  const getTransactionIcon = (type: string) => {
    switch (type) {
      case 'Deposit': return <ArrowUpCircle className="h-4 w-4 text-green-400" />
      case 'Withdrawal': return <ArrowDownCircle className="h-4 w-4 text-red-400" />
      case 'Allocation': return <TrendingUp className="h-4 w-4 text-blue-400" />
      case 'Deallocation': return <TrendingDown className="h-4 w-4 text-orange-400" />
      default: return <Clock className="h-4 w-4 text-gray-400" />
    }
  }

  const getTransactionLabel = (type: string) => {
    switch (type) {
      case 'Deposit': return 'Depósito'
      case 'Withdrawal': return 'Levantamento'
      case 'Allocation': return 'Alocação ao Portfólio'
      case 'Deallocation': return 'Retirada do Portfólio'
      case 'AssetPurchase': return 'Compra de Ativo'
      case 'AssetSale': return 'Venda de Ativo'
      case 'PremiumUpgrade': return 'Upgrade Premium'
      default: return type
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('pt-PT', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  return (
    <div className="space-y-6">
      {/* Current Payment Method */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <CreditCard className="h-5 w-5 mr-2" />
            Método de Pagamento Atual
          </CardTitle>
          <CardDescription className="text-gray-400">
            Apenas um método de pagamento é permitido por conta
          </CardDescription>
        </CardHeader>
        <CardContent>
          {userComplete?.payment_method_active && userComplete?.payment_method_type ? (
            <div className="space-y-4">
              {/* Current Method Display */}
              <div className="p-4 rounded-lg border border-gray-700 bg-gray-800/40">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <CreditCard className="h-5 w-5 text-blue-400 mr-3" />
                    <div>
                      <p className="text-white text-sm font-medium">
                        {userComplete.payment_method_type}
                      </p>
                      {isEditing ? (
                        <div className="space-y-3 mt-3">
                          <div>
                            <Label className="text-gray-200 text-xs font-medium">Tipo</Label>
                            <select
                              value={paymentData.payment_method_type}
                              onChange={(e) => setPaymentData({...paymentData, payment_method_type: e.target.value})}
                              className="w-full mt-1 bg-gray-700 border-gray-600 text-white text-sm rounded-md p-2 focus:border-blue-500"
                            >
                              <option value="IBAN">IBAN</option>
                              <option value="CreditCard">Cartão de Crédito</option>
                              <option value="DebitCard">Cartão de Débito</option>
                            </select>
                          </div>
                          <div>
                            <Label className="text-gray-200 text-xs font-medium">
                              {paymentData.payment_method_type === 'IBAN' ? 'IBAN' : 'Número do Cartão'}
                            </Label>
                            <Input
                              value={paymentData.payment_method_details}
                              onChange={(e) => setPaymentData({...paymentData, payment_method_details: e.target.value})}
                              className="bg-gray-700 border-gray-600 text-white text-sm mt-1 focus:border-blue-500"
                              placeholder={paymentData.payment_method_type === 'IBAN' ? 
                                'PT50 0000 0000 0000 0000 0000 0' : 
                                '**** **** **** ****'
                              }
                            />
                          </div>
                          {paymentData.payment_method_type !== 'IBAN' && (
                            <div>
                              <Label className="text-gray-200 text-xs font-medium">Data de Validade (Opcional)</Label>
                              <Input
                                type="date"
                                value={paymentData.payment_method_expiry}
                                onChange={(e) => setPaymentData({...paymentData, payment_method_expiry: e.target.value})}
                                className="bg-gray-700 border-gray-600 text-white text-sm mt-1 focus:border-blue-500"
                              />
                            </div>
                          )}
                        </div>
                      ) : (
                        <div>
                          <p className="text-gray-400 text-xs">
                            {userComplete.payment_method_type === 'IBAN' ? 
                              formatIBAN(userComplete.payment_method_details || '') :
                              userComplete.payment_method_details
                            }
                          </p>
                          {userComplete.payment_method_expiry && (
                            <div className="flex items-center mt-1">
                              <Calendar className="h-3 w-3 text-gray-500 mr-1" />
                              <p className="text-gray-500 text-xs">
                                Validade: {formatDate(userComplete.payment_method_expiry)}
                              </p>
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-2">
                    <Badge className="bg-green-100 text-green-800">
                      <Shield className="h-4 w-4 mr-1" />
                      Ativo
                    </Badge>
                    
                    {isEditing ? (
                      <div className="flex gap-1">
                        <Button 
                          size="sm" 
                          onClick={handleSave}
                          disabled={isLoading}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          {isLoading ? (
                            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white"></div>
                          ) : (
                            <Check className="h-4 w-4" />
                          )}
                        </Button>
                        <Button 
                          size="sm" 
                          variant="outline" 
                          onClick={handleCancel}
                          className="bg-gray-800/40 border-gray-600/60 text-gray-100 hover:bg-gray-700/60 hover:border-gray-500 hover:text-white backdrop-blur-sm transition-all duration-200"
                        >
                          <X className="h-4 w-4" />
                        </Button>
                      </div>
                    ) : (
                      <Button 
                        size="sm" 
                        variant="outline" 
                        onClick={() => setIsEditing(true)} 
                        className="bg-blue-900/30 border-blue-600/50 text-blue-200 hover:bg-blue-800/40 hover:border-blue-500 hover:text-white backdrop-blur-sm transition-all duration-200"
                      >
                        <Edit className="h-4 w-4 mr-1" />
                        Editar
                      </Button>
                    )}
                  </div>
                </div>
              </div>

              {/* Messages */}
              {error && (
                <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
                  <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
                  <p className="text-red-300 text-sm">{error}</p>
                </div>
              )}

              {success && (
                <div className="flex items-center p-3 rounded-lg bg-green-950/50 border border-green-800/40">
                  <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                  <p className="text-green-300 text-sm">{success}</p>
                </div>
              )}
            </div>
          ) : (
            /* No Payment Method */
            <div className="text-center py-8">
              <CreditCard className="h-16 w-16 mx-auto mb-4 text-gray-500" />
              <h3 className="text-lg font-medium text-white mb-2">Nenhum método de pagamento configurado</h3>
              <p className="text-gray-400 text-sm mb-6">
                Configure um método de pagamento para processar depósitos e subscriptions
              </p>
              
              {!isEditing ? (
                <Button 
                  onClick={() => setIsEditing(true)}
                  className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800"
                >
                  <Plus className="h-4 w-4 mr-2" />
                  Adicionar Método de Pagamento
                </Button>
              ) : (
                <div className="max-w-md mx-auto space-y-4">
                  <div>
                    <Label className="text-white text-sm">Tipo de Método</Label>
                    <select
                      value={paymentData.payment_method_type}
                      onChange={(e) => setPaymentData({...paymentData, payment_method_type: e.target.value})}
                      className="w-full mt-1 bg-gray-700 border-gray-600 text-white rounded-md p-2"
                    >
                      <option value="IBAN">IBAN</option>
                      <option value="CreditCard">Cartão de Crédito</option>
                      <option value="DebitCard">Cartão de Débito</option>
                    </select>
                  </div>
                  <div>
                    <Label className="text-white text-sm">
                      {paymentData.payment_method_type === 'IBAN' ? 'IBAN' : 'Número do Cartão'}
                    </Label>
                    <Input
                      value={paymentData.payment_method_details}
                      onChange={(e) => setPaymentData({...paymentData, payment_method_details: e.target.value})}
                      className="bg-gray-700 border-gray-600 text-white mt-1"
                      placeholder={paymentData.payment_method_type === 'IBAN' ? 
                        'PT50 0000 0000 0000 0000 0000 0' : 
                        '**** **** **** ****'
                      }
                    />
                  </div>
                  {paymentData.payment_method_type !== 'IBAN' && (
                    <div>
                      <Label className="text-white text-sm">Data de Validade (Opcional)</Label>
                      <Input
                        type="date"
                        value={paymentData.payment_method_expiry}
                        onChange={(e) => setPaymentData({...paymentData, payment_method_expiry: e.target.value})}
                        className="bg-gray-700 border-gray-600 text-white mt-1"
                      />
                    </div>
                  )}

                  {/* Messages */}
                  {error && (
                    <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
                      <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
                      <p className="text-red-300 text-sm">{error}</p>
                    </div>
                  )}

                  {success && (
                    <div className="flex items-center p-3 rounded-lg bg-green-950/50 border border-green-800/40">
                      <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
                      <p className="text-green-300 text-sm">{success}</p>
                    </div>
                  )}

                  <div className="flex gap-2 justify-center">
                    <Button 
                      onClick={handleSave}
                      disabled={isLoading}
                      className="bg-green-600 hover:bg-green-700"
                    >
                      {isLoading ? (
                        <div className="flex items-center">
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                          A guardar...
                        </div>
                      ) : (
                        <>
                          <Check className="h-4 w-4 mr-2" />
                          Guardar
                        </>
                      )}
                    </Button>
                    <Button 
                      variant="outline" 
                      onClick={handleCancel}
                      className="bg-gray-800/40 border-gray-600/60 text-gray-100 hover:bg-gray-700/60 hover:border-gray-500 hover:text-white backdrop-blur-sm transition-all duration-200"
                    >
                      <X className="h-4 w-4 mr-2" />
                      Cancelar
                    </Button>
                  </div>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Fund Transaction History */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <History className="h-5 w-5 text-blue-400" />
            Histórico de Movimentos de Fundos
          </CardTitle>
          <CardDescription className="text-gray-400">
            Histórico completo de depósitos, levantamentos e transferências de fundos
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isLoadingTransactions ? (
            <div className="flex items-center justify-center py-8">
              <RefreshCw className="h-6 w-6 animate-spin text-blue-400 mr-3" />
              <span className="text-gray-300">A carregar histórico...</span>
            </div>
          ) : fundTransactions.length === 0 ? (
            <div className="text-center py-8">
              <History className="h-16 w-16 mx-auto mb-4 text-gray-500" />
              <h3 className="text-lg font-medium text-white mb-2">Nenhuma transação encontrada</h3>
              <p className="text-gray-400 text-sm">
                As suas transações de fundos aparecerão aqui quando realizadas
              </p>
            </div>
          ) : (
            <div className="space-y-3">
              {fundTransactions.slice(0, 10).map((transaction) => (
                <div 
                  key={transaction.fund_transaction_id} 
                  className="flex items-center justify-between p-4 bg-gray-800/40 rounded-lg border border-gray-700/50"
                >
                  <div className="flex items-center gap-3">
                    {getTransactionIcon(transaction.transaction_type)}
                    <div>
                      <p className="text-white font-medium">
                        {getTransactionLabel(transaction.transaction_type)}
                      </p>
                      <p className="text-gray-400 text-sm">
                        {formatDate(transaction.created_at)}
                      </p>
                      {transaction.description && (
                        <p className="text-gray-500 text-xs mt-1">
                          {transaction.description}
                        </p>
                      )}
                    </div>
                  </div>
                  <div className="text-right">
                    <p className={`font-medium ${
                      ['Deposit', 'AssetSale', 'Deallocation'].includes(transaction.transaction_type) 
                        ? 'text-green-400' 
                        : 'text-red-400'
                    }`}>
                      {['Deposit', 'AssetSale', 'Deallocation'].includes(transaction.transaction_type) ? '+' : '-'}
                      {formatCurrency(transaction.amount)}
                    </p>
                    <p className="text-gray-500 text-sm">
                      Saldo: {formatCurrency(transaction.balance_after)}
                    </p>
                  </div>
                </div>
              ))}
              {fundTransactions.length > 10 && (
                <div className="text-center pt-4">
                  <Button
                    variant="outline"
                    onClick={fetchFundTransactions}
                    className="bg-gray-800/40 border-gray-600/60 text-gray-100 hover:bg-gray-700/60 hover:border-gray-500 hover:text-white"
                  >
                    Ver Mais Transações
                  </Button>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Payment Method Information */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Info className="h-5 w-5 mr-2" />
            Informação sobre Métodos de Pagamento
          </CardTitle>
          <CardDescription className="text-gray-400">
            Detalhes importantes sobre os métodos de pagamento suportados
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* IBAN Information */}
            <div className="space-y-3">
              <h4 className="text-white font-medium">IBAN (Recomendado)</h4>
              <div className="space-y-2">
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Transferências diretas para a sua conta bancária</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Sem taxas adicionais</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Processamento em 1-2 dias úteis</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Máxima segurança</p>
                </div>
              </div>
            </div>

            {/* Card Information */}
            <div className="space-y-3">
              <h4 className="text-white font-medium">Cartões de Crédito/Débito</h4>
              <div className="space-y-2">
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Processamento instantâneo</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Aceita Visa, Mastercard, American Express</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-yellow-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Taxa de processamento: 2.9% + €0.30</p>
                </div>
                <div className="flex items-start">
                  <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
                  <p className="text-gray-300 text-sm">Ideal para depósitos rápidos</p>
                </div>
              </div>
            </div>
          </div>

          {/* Security Notice */}
          <div className="p-4 rounded-lg bg-green-950/30 border border-green-800/40 mt-6">
            <div className="flex items-start">
              <Shield className="h-5 w-5 text-green-400 mr-3 mt-0.5 flex-shrink-0" />
              <div>
                <h5 className="text-green-300 font-medium mb-1">Segurança Garantida</h5>
                <p className="text-green-200 text-sm">
                  Todos os dados de pagamento são encriptados e processados através de sistemas certificados PCI DSS. 
                  Nunca armazenamos informações completas de cartões de crédito nos nossos servidores.
                </p>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 