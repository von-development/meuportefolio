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
  Info
} from 'lucide-react'

interface AddFundsTabProps {
  userId: string | undefined
  currentBalance: number
  onRefresh: () => void
  formatCurrency: (amount: number) => string
}

export default function AddFundsTab({ userId, currentBalance, onRefresh, formatCurrency }: AddFundsTabProps) {
  const [depositAmount, setDepositAmount] = useState('')
  const [isDepositing, setIsDepositing] = useState(false)
  const [depositError, setDepositError] = useState('')
  const [depositSuccess, setDepositSuccess] = useState('')

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
        setDepositSuccess(`Depósito de ${formatCurrency(result.amount)} realizado com sucesso! Novo saldo: ${formatCurrency(result.new_balance)}`)
        setDepositAmount('')
        onRefresh() // Refresh the dashboard data
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

  const clearMessages = () => {
    setDepositError('')
    setDepositSuccess('')
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
          <CardTitle className="text-white flex items-center">
            <ArrowUpCircle className="h-5 w-5 mr-2" />
            Adicionar Fundos
          </CardTitle>
          <CardDescription className="text-gray-400">
            Deposite fundos na sua conta para começar a investir
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Amount Input */}
          <div className="space-y-4">
            <div>
              <Label htmlFor="deposit-amount" className="text-white text-base font-medium">
                Valor a Depositar
              </Label>
              <div className="relative mt-2">
                <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                  <span className="text-gray-400 text-lg">€</span>
                </div>
                <Input
                  id="deposit-amount"
                  type="number"
                  placeholder="0.00"
                  value={depositAmount}
                  onChange={(e) => {
                    setDepositAmount(e.target.value)
                    clearMessages()
                  }}
                  className="bg-gray-800 border-gray-600 text-white pl-8 text-lg h-12"
                  min="0"
                  step="0.01"
                  max="100000"
                />
              </div>
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
                    className="border-gray-600 text-gray-300 hover:bg-gray-600 hover:text-white"
                  >
                    {formatCurrency(amount)}
                  </Button>
                ))}
              </div>
            </div>
          </div>

          {/* Messages */}
          {depositError && (
            <div className="flex items-center p-3 rounded-lg bg-red-950/50 border border-red-800/40">
              <AlertCircle className="h-5 w-5 text-red-400 mr-3 flex-shrink-0" />
              <p className="text-red-300 text-sm">{depositError}</p>
            </div>
          )}

          {depositSuccess && (
            <div className="flex items-center p-3 rounded-lg bg-green-950/50 border border-green-800/40">
              <CheckCircle className="h-5 w-5 text-green-400 mr-3 flex-shrink-0" />
              <p className="text-green-300 text-sm">{depositSuccess}</p>
            </div>
          )}

          {/* Deposit Button */}
          <Button 
            onClick={handleDeposit}
            disabled={isDepositing || !depositAmount || parseFloat(depositAmount) <= 0}
            className="w-full bg-green-600 hover:bg-green-700 h-12 text-lg"
          >
            {isDepositing ? (
              <div className="flex items-center">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-3"></div>
                A processar depósito...
              </div>
            ) : (
              <>
                <ArrowUpCircle className="h-5 w-5 mr-2" />
                Depositar {depositAmount && formatCurrency(parseFloat(depositAmount))}
              </>
            )}
          </Button>
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
              Para aumentar os seus limites, contacte o nosso suporte ou faça upgrade para Premium.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 