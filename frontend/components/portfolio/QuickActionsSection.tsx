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
  BarChart3
} from 'lucide-react'
import { toast } from 'sonner'
import Link from 'next/link'

interface QuickActionsSectionProps {
  portfolioId: string
  portfolioName: string
  currentFunds: number
  formatCurrency: (amount: number) => string
  onRefresh: () => void
}

export default function QuickActionsSection({ 
  portfolioId, 
  portfolioName, 
  currentFunds, 
  formatCurrency, 
  onRefresh 
}: QuickActionsSectionProps) {
  const [fundAmount, setFundAmount] = useState('')
  const [isProcessing, setIsProcessing] = useState(false)

  const handleAddFunds = async () => {
    const amount = parseFloat(fundAmount)
    if (!amount || amount <= 0) {
      toast.error('Por favor insira um valor válido')
      return
    }

    try {
      setIsProcessing(true)
      // This would typically call an add funds endpoint
      toast.success(`${formatCurrency(amount)} adicionado com sucesso!`)
      setFundAmount('')
      onRefresh()
    } catch (error) {
      toast.error('Erro ao adicionar fundos')
    } finally {
      setIsProcessing(false)
    }
  }

  const handleWithdrawFunds = async () => {
    const amount = parseFloat(fundAmount)
    if (!amount || amount <= 0) {
      toast.error('Por favor insira um valor válido')
      return
    }

    if (amount > currentFunds) {
      toast.error('Valor superior aos fundos disponíveis')
      return
    }

    try {
      setIsProcessing(true)
      // This would typically call a withdraw funds endpoint
      toast.success(`${formatCurrency(amount)} retirado com sucesso!`)
      setFundAmount('')
      onRefresh()
    } catch (error) {
      toast.error('Erro ao retirar fundos')
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
                onChange={(e) => setFundAmount(e.target.value)}
                className="bg-gray-700/50 border-gray-600 text-white mt-2"
              />
            </div>
            
            <div className="md:col-span-2 flex gap-3 items-end">
              <Button
                onClick={handleAddFunds}
                disabled={!fundAmount || isProcessing}
                className="flex-1 bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white"
              >
                <Plus className="h-4 w-4 mr-2" />
                Adicionar
              </Button>
              
              <Button
                onClick={handleWithdrawFunds}
                disabled={!fundAmount || isProcessing}
                variant="outline"
                className="flex-1 border-red-600 text-red-400 hover:bg-red-600/20"
              >
                <Minus className="h-4 w-4 mr-2" />
                Retirar
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Navigation to Trading */}
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