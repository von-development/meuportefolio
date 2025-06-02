'use client'

import React, { useState } from 'react'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { 
  ShoppingCart, 
  DollarSign, 
  Wallet, 
  Bell,
  RotateCcw,
  TrendingUp,
  Plus,
  Minus,
  Settings,
  Zap,
  Target,
  BarChart3,
  RefreshCw,
  AlertCircle,
  CheckCircle
} from 'lucide-react'
import { toast } from 'sonner'
import Link from 'next/link'

interface QuickActionsSectionProps {
  portfolioId: string
  portfolioName: string
  currentFunds: number
  formatCurrency: (amount: number) => string
  onRefresh: () => void
  userId: string
}

export default function QuickActionsSection({ 
  portfolioId, 
  portfolioName, 
  currentFunds, 
  formatCurrency, 
  onRefresh,
  userId
}: QuickActionsSectionProps) {
  const [fundAmount, setFundAmount] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  const clearMessages = () => {
    setError('')
    setSuccess('')
  }

  const handleAddFunds = async () => {
    const amount = parseFloat(fundAmount)
    if (!amount || amount <= 0) {
      setError('Por favor insira um valor válido')
      return
    }

    setIsProcessing(true)
    setError('')
    setSuccess('')

    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/allocate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          portfolio_id: parseInt(portfolioId),
          amount: amount
        }),
      })

      if (response.ok) {
        const result = await response.json()
        setSuccess(`${formatCurrency(result.amount)} alocado com sucesso! Novo saldo da conta: ${formatCurrency(result.new_balance)}`)
        setFundAmount('')
        
        // Add delay to let user see the success message before refreshing
        setTimeout(() => {
          onRefresh()
        }, 2000) // 2 second delay
      } else {
        const errorData = await response.text()
        setError(`Erro ao alocar fundos: ${errorData}`)
      }
    } catch (error) {
      console.error('Allocation failed:', error)
      setError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsProcessing(false)
    }
  }

  const handleWithdrawFunds = async () => {
    const amount = parseFloat(fundAmount)
    if (!amount || amount <= 0) {
      setError('Por favor insira um valor válido')
      return
    }

    if (amount > currentFunds) {
      setError('Valor superior aos fundos disponíveis')
      return
    }

    setIsProcessing(true)
    setError('')
    setSuccess('')

    try {
      const response = await fetch(`http://localhost:8080/api/v1/users/${userId}/deallocate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          portfolio_id: parseInt(portfolioId),
          amount: amount
        }),
      })

      if (response.ok) {
        const result = await response.json()
        setSuccess(`${formatCurrency(result.amount)} desalocado com sucesso! Novo saldo da conta: ${formatCurrency(result.new_balance)}`)
        setFundAmount('')
        
        // Add delay to let user see the success message before refreshing
        setTimeout(() => {
          onRefresh()
        }, 2000) // 2 second delay
      } else {
        const errorData = await response.text()
        setError(`Erro ao desalocar fundos: ${errorData}`)
      }
    } catch (error) {
      console.error('Deallocation failed:', error)
      setError('Erro de conexão. Verifique a sua ligação à internet e tente novamente.')
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-2">
        <Zap className="h-6 w-6 text-yellow-400" />
        <h2 className="text-2xl font-bold text-white">Gestão & Trading</h2>
      </div>

      {/* Fund Management */}
      <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
        <CardHeader>
          <CardTitle className="text-white flex items-center gap-2">
            <Wallet className="h-5 w-5 text-green-400" />
            Gestão de Fundos
          </CardTitle>
          <CardDescription className="text-gray-400">
            Adicionar ou retirar fundos do portfólio {portfolioName}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 rounded-lg bg-gradient-to-r from-green-900/30 to-gray-800/30 border border-green-800/30">
            <div>
              <p className="text-gray-400 text-sm">Fundos Disponíveis</p>
              <p className="text-white font-bold text-xl">{formatCurrency(currentFunds)}</p>
            </div>
            <Wallet className="h-8 w-8 text-green-400" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="md:col-span-1">
              <Label htmlFor="fund-amount" className="text-gray-300">Valor</Label>
              <Input
                id="fund-amount"
                type="number"
                placeholder="0.00"
                min="0"
                step="0.01"
                value={fundAmount}
                onChange={(e) => {
                  setFundAmount(e.target.value)
                  if (error || success) {
                    clearMessages()
                  }
                }}
                className="bg-gray-700/50 border-gray-600 text-white mt-2"
              />
            </div>
            
            <div className="md:col-span-2 flex gap-3 items-end">
              <Button
                onClick={handleAddFunds}
                disabled={!fundAmount || isProcessing}
                className="flex-1 bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white"
              >
                {isProcessing ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Processando...
                  </>
                ) : (
                  <>
                    <Plus className="h-4 w-4 mr-2" />
                    Adicionar
                  </>
                )}
              </Button>
              
              <Button
                onClick={handleWithdrawFunds}
                disabled={!fundAmount || isProcessing}
                variant="outline"
                className="flex-1 border-red-600 text-red-400 hover:bg-red-600/20"
              >
                {isProcessing ? (
                  <>
                    <RefreshCw className="h-4 w-4 mr-2 animate-spin" />
                    Processando...
                  </>
                ) : (
                  <>
                    <Minus className="h-4 w-4 mr-2" />
                    Retirar
                  </>
                )}
              </Button>
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
        </CardContent>
      </Card>

      {/* Trading Center Card */}
      <Card className="bg-gradient-to-r from-blue-900/30 to-purple-900/30 rounded-xl border border-blue-800/30">
        <CardContent className="p-6">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="text-white font-semibold mb-2">Centro de Trading Avançado</h3>
              <p className="text-gray-300 text-sm">
                Acesse todas as funcionalidades de trading e análise de mercado
              </p>
            </div>
            <Button asChild className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800">
              <Link href="/dashboard?tab=trading">
                <TrendingUp className="h-4 w-4 mr-2" />
                Ir para Trading
              </Link>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
} 