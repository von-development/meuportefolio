'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Alert, AlertDescription } from '@/components/ui/alert'
import { Loader2, User, Mail, Lock, MapPin, CreditCard, ArrowLeft } from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'
import Navbar from '@/components/layout/Navbar'

export default function SignupPage() {
  const router = useRouter()
  const { signup, loading } = useAuth()
  
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    country_of_residence: '',
    iban: '',
  })
  const [error, setError] = useState<string | null>(null)
  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
    // Clear error when user starts typing
    if (error) setError(null)
  }

  const handleSelectChange = (value: string, field: string) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }))
    if (error) setError(null)
  }

  const validateForm = () => {
    if (!formData.name.trim()) {
      return 'Por favor, insira o seu nome.'
    }
    if (!formData.email.trim() || !formData.email.includes('@')) {
      return 'Por favor, insira um email válido.'
    }
    if (formData.password.length < 3) {
      return 'A palavra-passe deve ter pelo menos 3 caracteres.'
    }
    if (!formData.country_of_residence.trim()) {
      return 'Por favor, selecione o seu país de residência.'
    }
    if (!formData.iban.trim()) {
      return 'Por favor, insira o seu IBAN.'
    }
    // Basic IBAN validation (starts with 2 letters)
    if (!/^[A-Z]{2}/.test(formData.iban.replace(/\s/g, '').toUpperCase())) {
      return 'Por favor, insira um IBAN válido.'
    }
    return null
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    const validationError = validateForm()
    if (validationError) {
      setError(validationError)
      return
    }

    try {
      setIsSubmitting(true)
      setError(null)
      
      await signup({
        name: formData.name.trim(),
        email: formData.email.trim(),
        password: formData.password,
        country_of_residence: formData.country_of_residence,
        iban: formData.iban.replace(/\s/g, '').toUpperCase(), // Remove spaces and uppercase
        user_type: 'Basic', // Always send Basic
      })
      
      // Redirect to dashboard
      router.push('/')
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Erro na criação da conta'
      setError(errorMessage)
    } finally {
      setIsSubmitting(false)
    }
  }

  const countries = [
    'Portugal', 'Espanha', 'França', 'Alemanha', 'Itália', 'Reino Unido',
    'Holanda', 'Bélgica', 'Áustria', 'Suíça', 'Brasil', 'Outro'
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      {/* Navbar */}
      <Navbar />

      {/* Signup Form */}
      <div className="flex items-center justify-center px-4 py-8">
        <div className="w-full max-w-md">
          {/* Back button */}
          <Button 
            variant="ghost" 
            className="text-gray-300 hover:text-white mb-6"
            onClick={() => router.back()}
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar
          </Button>

          <Card className="bg-gradient-to-br from-gray-800/60 to-gray-900/60 backdrop-blur-sm border border-blue-800/40">
            <CardHeader className="space-y-1">
              <CardTitle className="text-2xl font-bold text-center text-white">
                Criar Conta
              </CardTitle>
              <p className="text-center text-gray-400">
                Junte-se ao meuPortfólio e comece a investir
              </p>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                {error && (
                  <Alert className="border-red-500/50 bg-red-500/10">
                    <AlertDescription className="text-red-400">
                      {error}
                    </AlertDescription>
                  </Alert>
                )}
                
                <div className="space-y-2">
                  <Label htmlFor="name" className="text-gray-300">Nome Completo</Label>
                  <div className="relative">
                    <User className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="name"
                      name="name"
                      type="text"
                      placeholder="O seu nome completo"
                      value={formData.name}
                      onChange={handleInputChange}
                      className="pl-10 bg-gray-700/50 border-gray-600 text-white placeholder-gray-400 focus:border-blue-500"
                      required
                    />
                  </div>
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="email" className="text-gray-300">Email</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      placeholder="seuemail@exemplo.com"
                      value={formData.email}
                      onChange={handleInputChange}
                      className="pl-10 bg-gray-700/50 border-gray-600 text-white placeholder-gray-400 focus:border-blue-500"
                      required
                    />
                  </div>
                </div>
                
                <div className="space-y-2">
                  <Label htmlFor="password" className="text-gray-300">Palavra-passe</Label>
                  <div className="relative">
                    <Lock className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="password"
                      name="password"
                      type="password"
                      placeholder="Digite a sua palavra-passe"
                      value={formData.password}
                      onChange={handleInputChange}
                      className="pl-10 bg-gray-700/50 border-gray-600 text-white placeholder-gray-400 focus:border-blue-500"
                      required
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="country" className="text-gray-300">País de Residência</Label>
                  <Select onValueChange={(value) => handleSelectChange(value, 'country_of_residence')}>
                    <SelectTrigger className="bg-gray-700/50 border-gray-600 text-white focus:border-blue-500">
                      <MapPin className="h-4 w-4 text-gray-400 mr-2" />
                      <SelectValue placeholder="Selecione o seu país" />
                    </SelectTrigger>
                    <SelectContent className="bg-gray-800 border-gray-600">
                      {countries.map((country) => (
                        <SelectItem key={country} value={country} className="text-white hover:bg-gray-700">
                          {country}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="iban" className="text-gray-300">IBAN</Label>
                  <div className="relative">
                    <CreditCard className="absolute left-3 top-3 h-4 w-4 text-gray-400" />
                    <Input
                      id="iban"
                      name="iban"
                      type="text"
                      placeholder="PT50 0000 0000 0000 0000 0000 0"
                      value={formData.iban}
                      onChange={handleInputChange}
                      className="pl-10 bg-gray-700/50 border-gray-600 text-white placeholder-gray-400 focus:border-blue-500"
                      required
                    />
                  </div>
                  <p className="text-xs text-gray-400">
                    Necessário para depósitos e levantamentos
                  </p>
                </div>

                <Button 
                  type="submit" 
                  className="w-full bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800"
                  disabled={isSubmitting || loading}
                >
                  {isSubmitting ? (
                    <>
                      <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                      A criar conta...
                    </>
                  ) : (
                    'Criar Conta'
                  )}
                </Button>
              </form>

              <div className="mt-6 text-center">
                <p className="text-gray-400 text-sm">
                  Já tem conta?{' '}
                  <Link 
                    href="/login" 
                    className="text-blue-400 hover:text-blue-300 font-medium"
                  >
                    Entrar
                  </Link>
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
} 