'use client'

import { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { 
  ArrowUpCircle, 
  Wallet, 
  CreditCard, 
  AlertCircle,
  CheckCircle,
  DollarSign,
  Banknote,
  Info,
  Plus,
  Minus,
  RefreshCw
} from 'lucide-react'

interface AddFundsTabProps {
  userId: string
  currentBalance: number
  onRefresh: () => void
  formatCurrency: (amount: number) => string
  userComplete?: any
  fetchCompleteUser?: () => Promise<void>
}

export default function AddFundsTab({ userId, currentBalance, onRefresh, formatCurrency, userComplete, fetchCompleteUser }: AddFundsTabProps) {
  const [depositAmount, setDepositAmount] = useState('')
  const [withdrawAmount, setWithdrawAmount] = useState('')
  const [activeOperation, setActiveOperation] = useState<'deposit' | 'withdraw'>('deposit')
  const [isDepositing, setIsDepositing] = useState(false)
  const [depositError, setDepositError] = useState('')
  const [depositSuccess, setDepositSuccess] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const handleDeposit = async () => {
    if (!depositAmount || parseFloat(depositAmount) <= 0) {
      setDepositError('Por favor, insira um valor válido maior que €0')
      return
    }

    if (parseFloat(depositAmount) > 100000) {
      setDepositError('O valor máximo por depósito é €100,000')
      return
    }

    setIsDepositing(true)
    setDepositError('')
    setDepositSuccess('')

    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/deposit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: parseFloat(depositAmount),
          description: 'Depósito via plataforma web'
        }),
      })

      if (response.ok) {
        const result = await response.json()
        setDepositSuccess(`Depósito de ${formatCurrency(result.amount)} adicionado com sucesso! Novo saldo: ${formatCurrency(result.new_balance)}`)
        setDepositAmount('')
        
        // Add delay to let user see the success message before refreshing
        setTimeout(() => {
          onRefresh() // Refresh the dashboard data
        }, 2000) // 2 second delay
      } else {
        const errorData = await response.text()
        setDepositError(`Erro ao processar depósito: ${errorData}`)
      }
    } catch (error) {
      console.error('Deposit failed:', error)
      setDepositError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsDepositing(false)
    }
  }

  const handleWithdraw = async () => {
    if (!withdrawAmount || parseFloat(withdrawAmount) <= 0) {
      setError('Por favor, insira um valor válido de levantamento')
      return
    }

    if (parseFloat(withdrawAmount) > (userComplete?.account_balance || 0)) {
      setError('Fundos insuficientes para este levantamento')
      return
    }

    setIsLoading(true)
    setError('')
    setSuccess('')

    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/withdraw`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          amount: parseFloat(withdrawAmount),
          description: 'Levantamento via plataforma web'
        })
      })

      console.log('Withdraw response status:', response.status)
      console.log('Withdraw response ok:', response.ok)

      if (response.ok) {
        const result = await response.json()
        console.log('Withdraw result:', result)
        
        // Handle different possible response structures
        const amount = result.amount || parseFloat(withdrawAmount)
        const newBalance = result.new_balance || userComplete?.account_balance
        
        if (result.status === 'Success' || response.status === 200) {
          setSuccess(`Fundos de ${formatCurrency(amount)} retirados com sucesso!${newBalance ? ` Novo saldo: ${formatCurrency(newBalance)}` : ''}`)
        } else {
          setSuccess(`Levantamento processado com sucesso!`)
        }
        
        setWithdrawAmount('')
        
        // Add delay to let user see the success message before refreshing
        setTimeout(async () => {
          // Refresh both user data and dashboard
          if (fetchCompleteUser) {
            await fetchCompleteUser()
          }
          // Also call the main refresh function
          onRefresh()
        }, 2000) // 2 second delay
      } else {
        const errorData = await response.text()
        console.error('Withdraw error response:', errorData)
        setError(errorData || 'Withdrawal failed')
      }
    } catch (error) {
      console.error('Withdraw network error:', error)
      setError('Network error during withdrawal')
    } finally {
      setIsLoading(false)
    }
  }

  const clearMessages = () => {
    setDepositError('')
    setDepositSuccess('')
    setError('')
    setSuccess('')
  }

  const suggestedAmounts = [50, 100, 250, 500, 1000, 2500]

  return (
    <div className="space-y-6">
      {/* Current Balance Display */}
      <Card className="bg-gradient-to-br from-blue-800/60 to-blue-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center">
            <Wallet className="h-5 w-5 mr-2" />
            Saldo Atual
          </CardTitle>
          <CardDescription className="text-blue-200">
            Fundos disponíveis na sua conta
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="text-center">
            <div className="text-4xl font-bold text-white mb-2">
              {formatCurrency(currentBalance)}
            </div>
            <p className="text-blue-200">Disponível para investimento</p>
          </div>
        </CardContent>
      </Card>

      {/* Deposit Form */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <DollarSign className="h-5 w-5 text-green-400" />
            Fundos
          </CardTitle>
          <CardDescription className="text-gray-400">
            Depositar ou retirar fundos da sua conta
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Operation Toggle */}
          <div className="flex rounded-lg bg-gray-800/60 p-1">
            <Button
              variant={activeOperation === 'deposit' ? 'default' : 'ghost'}
              onClick={() => {
                setActiveOperation('deposit')
              }}
              className={`flex-1 ${activeOperation === 'deposit' 
                ? 'bg-blue-600 text-white' 
                : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }`}
            >
              <Plus className="h-4 w-4 mr-2" />
              Depositar
            </Button>
            <Button
              variant={activeOperation === 'withdraw' ? 'default' : 'ghost'}
              onClick={() => {
                setActiveOperation('withdraw')
              }}
              className={`flex-1 ${activeOperation === 'withdraw' 
                ? 'bg-orange-600 text-white' 
                : 'text-gray-300 hover:bg-gray-700 hover:text-white'
              }`}
            >
              <Minus className="h-4 w-4 mr-2" />
              Retirar
            </Button>
          </div>

          {activeOperation === 'deposit' ? (
            <>
              {/* Deposit Form */}
              <div className="space-y-4">
                <div>
                  <Label className="text-white text-sm font-medium">Valor a Depositar</Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    value={depositAmount}
                    onChange={(e) => {
                      setDepositAmount(e.target.value)
                      if (depositError || depositSuccess) {
                        clearMessages()
                      }
                    }}
                    placeholder="0.00"
                    className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>

                {/* Suggested Amounts */}
                <div>
                  <Label className="text-white text-sm font-medium">Valores Sugeridos</Label>
                  <div className="grid grid-cols-3 gap-2 mt-2">
                    {suggestedAmounts.map((amount) => (
                      <Button
                        key={amount}
                        variant="outline"
                        size="sm"
                        onClick={() => {
                          setDepositAmount(amount.toString())
                          clearMessages()
                        }}
                        className="bg-gray-800/60 border-gray-500/60 text-gray-100 hover:bg-blue-600/20 hover:border-blue-500/60 hover:text-blue-200 backdrop-blur-sm transition-all duration-200"
                      >
                        {formatCurrency(amount)}
                      </Button>
                    ))}
                  </div>
                </div>

                <Button 
                  onClick={handleDeposit} 
                  disabled={isLoading || !depositAmount || parseFloat(depositAmount) <= 0}
                  className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800"
                >
                  {isLoading ? (
                    <>
                      <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                      Processando...
                    </>
                  ) : (
                    <>
                      <Plus className="mr-2 h-4 w-4" />
                      Depositar {depositAmount ? formatCurrency(parseFloat(depositAmount)) : 'Fundos'}
                    </>
                  )}
                </Button>
              </div>
            </>
          ) : (
            <>
              {/* Withdraw Form */}
              <div className="space-y-4">
                <div className="bg-blue-900/30 border border-blue-600/50 rounded-lg p-3">
                  <p className="text-blue-200 text-sm">
                    <span className="font-medium">Saldo Disponível:</span> {formatCurrency(userComplete?.account_balance || 0)}
                  </p>
                </div>

                <div>
                  <Label className="text-white text-sm font-medium">Valor a Retirar</Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0"
                    max={userComplete?.account_balance || 0}
                    value={withdrawAmount}
                    onChange={(e) => {
                      setWithdrawAmount(e.target.value)
                      if (error || success) {
                        clearMessages()
                      }
                    }}
                    placeholder="0.00"
                    className="bg-gray-700 border-gray-600 text-white placeholder-gray-400"
                  />
                </div>

                {/* Quick Withdraw Amounts */}
                <div>
                  <Label className="text-white text-sm font-medium">Retirada Rápida</Label>
                  <div className="grid grid-cols-3 gap-2 mt-2">
                    {[25, 50, 100].map((percentage) => {
                      const amount = (userComplete?.account_balance || 0) * (percentage / 100)
                      return (
                        <Button
                          key={percentage}
                          variant="outline"
                          size="sm"
                          onClick={() => {
                            setWithdrawAmount(amount.toString())
                            clearMessages()
                          }}
                          className="bg-gray-800/60 border-gray-500/60 text-gray-100 hover:bg-orange-600/20 hover:border-orange-500/60 hover:text-orange-200 backdrop-blur-sm transition-all duration-200"
                          disabled={amount <= 0}
                        >
                          {percentage}%
                        </Button>
                      )
                    })}
                  </div>
                </div>

                <Button 
                  onClick={handleWithdraw} 
                  disabled={isLoading || !withdrawAmount || parseFloat(withdrawAmount) <= 0 || parseFloat(withdrawAmount) > (userComplete?.account_balance || 0)}
                  className="w-full bg-gradient-to-r from-orange-600 to-orange-700 hover:from-orange-700 hover:to-orange-800"
                >
                  {isLoading ? (
                    <>
                      <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
                      Processando...
                    </>
                  ) : (
                    <>
                      <Minus className="mr-2 h-4 w-4" />
                      Retirar {withdrawAmount ? formatCurrency(parseFloat(withdrawAmount)) : 'Fundos'}
                    </>
                  )}
                </Button>
              </div>
            </>
          )}

          {/* Messages */}
          {(depositError || error) && (
            <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
              <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
              <p className="text-red-300 text-sm">{depositError || error}</p>
            </div>
          )}

          {(depositSuccess || success) && (
            <div className="flex items-center p-3 rounded-lg bg-green-950/50 border border-green-800/40">
              <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
              <p className="text-green-300 text-sm">{depositSuccess || success}</p>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Information Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Deposit Information */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center text-lg">
              <Info className="h-5 w-5 mr-2" />
              Informação sobre Depósitos
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-start">
              <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Depósitos são processados instantaneamente</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Valor mínimo: €1.00</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Valor máximo por transação: €100,000</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-blue-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Sem taxas de depósito</p>
            </div>
          </CardContent>
        </Card>

        {/* Security Information */}
        <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-green-800/40">
          <CardHeader>
            <CardTitle className="text-white flex items-center text-lg">
              <CreditCard className="h-5 w-5 mr-2" />
              Segurança dos Pagamentos
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-start">
              <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Encriptação SSL de 256 bits</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Conformidade PCI DSS</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Monitorização anti-fraude 24/7</p>
            </div>
            <div className="flex items-start">
              <div className="w-2 h-2 bg-green-400 rounded-full mt-2 mr-3 flex-shrink-0"></div>
              <p className="text-gray-300 text-sm">Dados nunca armazenados localmente</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Deposit Limits Notice */}
      <Card className="bg-gradient-to-br from-yellow-900/40 to-orange-900/40 border-yellow-600/40">
        <CardHeader>
          <CardTitle className="text-yellow-300 flex items-center text-lg">
            <Banknote className="h-5 w-5 mr-2" />
            Limites de Depósito
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-2">
            <div className="flex justify-between items-center">
              <span className="text-yellow-100">Limite diário:</span>
              <Badge className="bg-yellow-100 text-yellow-800">€25,000</Badge>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-yellow-100">Limite mensal:</span>
              <Badge className="bg-yellow-100 text-yellow-800">€500,000</Badge>
            </div>
            <p className="text-yellow-200 text-sm mt-3">
              Para aumentar os seus limites, contacte o nosso suporte.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 