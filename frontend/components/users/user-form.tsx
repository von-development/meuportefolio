'use client';

import { useState, FormEvent } from 'react';
import { type User, type SignupRequest, userApi } from '@/lib/api/user';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';

interface UserFormProps {
  user?: User;
  onUserCreated: (user: User) => void;
}

export function UserForm({ user, onUserCreated }: UserFormProps) {
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: user?.name || '',
    email: user?.email || '',
    password: '',
    country_of_residence: user?.country_of_residence || '',
    iban: user?.iban || '',
    user_type: user?.user_type || 'Basic' as 'Basic' | 'Premium',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const isEditing = !!user;

  const validateForm = () => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Nome é obrigatório';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email é obrigatório';
    } else if (!/^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i.test(formData.email)) {
      newErrors.email = 'Email inválido';
    }

    if (!isEditing && !formData.password.trim()) {
      newErrors.password = 'Senha é obrigatória';
    } else if (!isEditing && formData.password.length < 6) {
      newErrors.password = 'Senha deve ter pelo menos 6 caracteres';
    }

    if (!formData.country_of_residence.trim()) {
      newErrors.country_of_residence = 'País é obrigatório';
    }

    if (!formData.iban.trim()) {
      newErrors.iban = 'IBAN é obrigatório';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      return;
    }

    try {
      setLoading(true);
      
      let result: User;
      
      if (isEditing) {
        // Update existing user
        const updateData = {
          name: formData.name,
          email: formData.email,
          country_of_residence: formData.country_of_residence,
          iban: formData.iban,
          user_type: formData.user_type,
        };
        result = await userApi.updateUser(user.user_id, updateData);
      } else {
        // Create new user
        const createData: SignupRequest = {
          name: formData.name,
          email: formData.email,
          password: formData.password,
          country_of_residence: formData.country_of_residence,
          iban: formData.iban,
        };
        result = await userApi.createUser(createData);
      }
      
      onUserCreated(result);
    } catch (error) {
      toast.error(isEditing ? 'Erro ao atualizar usuário' : 'Erro ao criar usuário');
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: string, value: string) => {
    setFormData(prev => ({ ...prev, [field]: value }));
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: '' }));
    }
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="space-y-2">
        <Label htmlFor="name">Nome</Label>
        <Input
          id="name"
          value={formData.name}
          onChange={(e) => handleInputChange('name', e.target.value)}
          placeholder="Digite o nome completo"
        />
        {errors.name && (
          <p className="text-sm text-destructive">{errors.name}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="email">Email</Label>
        <Input
          id="email"
          type="email"
          value={formData.email}
          onChange={(e) => handleInputChange('email', e.target.value)}
          placeholder="exemplo@email.com"
        />
        {errors.email && (
          <p className="text-sm text-destructive">{errors.email}</p>
        )}
      </div>

      {!isEditing && (
        <div className="space-y-2">
          <Label htmlFor="password">Senha</Label>
          <Input
            id="password"
            type="password"
            value={formData.password}
            onChange={(e) => handleInputChange('password', e.target.value)}
            placeholder="Digite a senha"
          />
          {errors.password && (
            <p className="text-sm text-destructive">{errors.password}</p>
          )}
        </div>
      )}

      <div className="space-y-2">
        <Label htmlFor="country">País de Residência</Label>
        <Input
          id="country"
          value={formData.country_of_residence}
          onChange={(e) => handleInputChange('country_of_residence', e.target.value)}
          placeholder="Digite o país"
        />
        {errors.country_of_residence && (
          <p className="text-sm text-destructive">{errors.country_of_residence}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="iban">IBAN</Label>
        <Input
          id="iban"
          value={formData.iban}
          onChange={(e) => handleInputChange('iban', e.target.value)}
          placeholder="Digite o IBAN"
        />
        {errors.iban && (
          <p className="text-sm text-destructive">{errors.iban}</p>
        )}
      </div>

      <div className="space-y-2">
        <Label htmlFor="user_type">Tipo de Usuário</Label>
        <Select 
          value={formData.user_type} 
          onValueChange={(value: 'Basic' | 'Premium') => handleInputChange('user_type', value)}
        >
          <SelectTrigger>
            <SelectValue placeholder="Selecione o tipo" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="Basic">Básico</SelectItem>
            <SelectItem value="Premium">Premium</SelectItem>
          </SelectContent>
        </Select>
      </div>

      <Button type="submit" disabled={loading} className="w-full">
        {loading 
          ? (isEditing ? 'Atualizando...' : 'Criando...') 
          : (isEditing ? 'Atualizar Usuário' : 'Criar Usuário')
        }
      </Button>
    </form>
  );
} 