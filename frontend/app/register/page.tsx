'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { authApi, RegisterRequest } from '@/lib/api/auth';
import { toast } from 'sonner';
import { Eye, EyeOff, Mail, Lock, User, MapPin, CreditCard, UserPlus, ArrowLeft } from 'lucide-react';

export default function RegisterPage() {
  const router = useRouter();
  const [formData, setFormData] = useState<RegisterRequest>({
    name: '',
    email: '',
    password: '',
    country_of_residence: '',
    iban: '',
    user_type: 'basic',
  });
  const [loading, setLoading] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [errors, setErrors] = useState<Partial<RegisterRequest>>({});

  const countries = [
    'Brasil', 'Estados Unidos', 'Portugal', 'Espanha', 'França', 'Alemanha', 
    'Reino Unido', 'Itália', 'Canadá', 'Argentina', 'Chile', 'México'
  ];

  const userTypes = [
    { value: 'basic', label: 'Básico' },
    { value: 'premium', label: 'Premium' }
  ];

  const validateForm = (): boolean => {
    const newErrors: Partial<RegisterRequest> = {};

    if (!formData.name || formData.name.length < 2) {
      newErrors.name = 'Nome deve ter pelo menos 2 caracteres';
    }

    if (!formData.email) {
      newErrors.email = 'Email é obrigatório';
    } else if (!/\S+@\S+\.\S+/.test(formData.email)) {
      newErrors.email = 'Email inválido';
    }

    if (!formData.password) {
      newErrors.password = 'Senha é obrigatória';
    } else if (formData.password.length < 6) {
      newErrors.password = 'Senha deve ter pelo menos 6 caracteres';
    }

    if (!formData.country_of_residence) {
      newErrors.country_of_residence = 'País é obrigatório';
    }

    if (!formData.iban) {
      newErrors.iban = 'IBAN é obrigatório';
    } else if (formData.iban.length < 8) {
      newErrors.iban = 'IBAN deve ter pelo menos 8 caracteres';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    setLoading(true);
    try {
      const response = await authApi.register(formData);
      toast.success('Conta criada com sucesso!');
      
      // Store user data in localStorage
      localStorage.setItem('user', JSON.stringify({
        user_id: response.user_id,
        name: response.name,
        email: response.email,
        user_type: response.user_type
      }));
      
      // Redirect to dashboard
      router.push('/');
    } catch (error) {
      console.error('Registration error:', error);
      toast.error('Erro ao criar conta. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: keyof RegisterRequest, value: string) => {
    setFormData((prev: RegisterRequest) => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors((prev: Partial<RegisterRequest>) => ({ ...prev, [field]: undefined }));
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
      <div className="w-full max-w-lg space-y-6">
        {/* Header */}
        <div className="text-center space-y-2">
          <Button 
            variant="ghost" 
            size="sm" 
            onClick={() => router.push('/')}
            className="text-slate-400 hover:text-white mb-4"
          >
            <ArrowLeft className="h-4 w-4 mr-2" />
            Voltar ao início
          </Button>
          <h1 className="text-3xl font-bold text-white">Criar Conta</h1>
          <p className="text-slate-400">Junte-se ao meuPortefólio</p>
        </div>

        {/* Registration Form */}
        <Card className="bg-slate-800 border-slate-700">
          <CardHeader className="space-y-1">
            <CardTitle className="text-2xl text-center text-white">Registro</CardTitle>
            <CardDescription className="text-center text-slate-400">
              Preencha os dados para criar sua conta
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Name Field */}
              <div className="space-y-2">
                <Label htmlFor="name" className="text-slate-300">Nome Completo</Label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                  <Input
                    id="name"
                    type="text"
                    placeholder="Seu nome completo"
                    value={formData.name}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    className={`pl-10 bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
                      errors.name ? 'border-red-500' : ''
                    }`}
                  />
                </div>
                {errors.name && (
                  <p className="text-red-400 text-sm">{errors.name}</p>
                )}
              </div>

              {/* Email Field */}
              <div className="space-y-2">
                <Label htmlFor="email" className="text-slate-300">Email</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="seu@email.com"
                    value={formData.email}
                    onChange={(e) => handleInputChange('email', e.target.value)}
                    className={`pl-10 bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
                      errors.email ? 'border-red-500' : ''
                    }`}
                  />
                </div>
                {errors.email && (
                  <p className="text-red-400 text-sm">{errors.email}</p>
                )}
              </div>

              {/* Password Field */}
              <div className="space-y-2">
                <Label htmlFor="password" className="text-slate-300">Senha</Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                  <Input
                    id="password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Sua senha"
                    value={formData.password}
                    onChange={(e) => handleInputChange('password', e.target.value)}
                    className={`pl-10 pr-10 bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
                      errors.password ? 'border-red-500' : ''
                    }`}
                  />
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-2 top-1/2 transform -translate-y-1/2 h-8 w-8 p-0 text-slate-400 hover:text-white"
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </Button>
                </div>
                {errors.password && (
                  <p className="text-red-400 text-sm">{errors.password}</p>
                )}
              </div>

              {/* Country Field */}
              <div className="space-y-2">
                <Label htmlFor="country" className="text-slate-300">País de Residência</Label>
                <Select onValueChange={(value) => handleInputChange('country_of_residence', value)}>
                  <SelectTrigger className={`bg-slate-700 border-slate-600 text-white focus:border-blue-500 ${
                    errors.country_of_residence ? 'border-red-500' : ''
                  }`}>
                    <div className="flex items-center">
                      <MapPin className="h-4 w-4 text-slate-400 mr-2" />
                      <SelectValue placeholder="Selecione seu país" />
                    </div>
                  </SelectTrigger>
                  <SelectContent className="bg-slate-700 border-slate-600">
                    {countries.map((country) => (
                      <SelectItem key={country} value={country} className="text-white hover:bg-slate-600">
                        {country}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {errors.country_of_residence && (
                  <p className="text-red-400 text-sm">{errors.country_of_residence}</p>
                )}
              </div>

              {/* IBAN Field */}
              <div className="space-y-2">
                <Label htmlFor="iban" className="text-slate-300">IBAN</Label>
                <div className="relative">
                  <CreditCard className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-slate-400" />
                  <Input
                    id="iban"
                    type="text"
                    placeholder="BR123456789012345678901234"
                    value={formData.iban}
                    onChange={(e) => handleInputChange('iban', e.target.value.toUpperCase())}
                    className={`pl-10 bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
                      errors.iban ? 'border-red-500' : ''
                    }`}
                  />
                </div>
                {errors.iban && (
                  <p className="text-red-400 text-sm">{errors.iban}</p>
                )}
              </div>

              {/* User Type Field */}
              <div className="space-y-2">
                <Label htmlFor="userType" className="text-slate-300">Tipo de Conta</Label>
                <Select onValueChange={(value) => handleInputChange('user_type', value)} defaultValue="basic">
                  <SelectTrigger className="bg-slate-700 border-slate-600 text-white focus:border-blue-500">
                    <SelectValue placeholder="Selecione o tipo de conta" />
                  </SelectTrigger>
                  <SelectContent className="bg-slate-700 border-slate-600">
                    {userTypes.map((type) => (
                      <SelectItem key={type.value} value={type.value} className="text-white hover:bg-slate-600">
                        {type.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              {/* Submit Button */}
              <Button 
                type="submit" 
                className="w-full bg-blue-600 hover:bg-blue-700 text-white" 
                disabled={loading}
              >
                {loading ? (
                  <div className="flex items-center gap-2">
                    <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    Criando conta...
                  </div>
                ) : (
                  <div className="flex items-center gap-2">
                    <UserPlus className="h-4 w-4" />
                    Criar Conta
                  </div>
                )}
              </Button>
            </form>

            {/* Login Link */}
            <div className="mt-6 text-center">
              <p className="text-slate-400 text-sm">
                Já tem uma conta?{' '}
                <Link 
                  href="/login" 
                  className="text-blue-400 hover:text-blue-300 font-medium"
                >
                  Fazer login
                </Link>
              </p>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 