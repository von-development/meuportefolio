'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { portfolioApi } from '@/lib/api/portfolio';
import { toast } from 'sonner';
import { Save, Loader2 } from 'lucide-react';
import type { Portfolio, CreatePortfolioRequest } from '@/lib/api/portfolio';

interface PortfolioFormProps {
  portfolio?: Portfolio;
  isEditing?: boolean;
}

export function PortfolioForm({ portfolio, isEditing = false }: PortfolioFormProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState({
    name: portfolio?.name || '',
    description: '',
    initial_funds: '',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const validateForm = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!formData.name.trim()) {
      newErrors.name = 'Nome do portfólio é obrigatório';
    } else if (formData.name.length < 3) {
      newErrors.name = 'Nome deve ter pelo menos 3 caracteres';
    }

    if (!isEditing && !formData.initial_funds) {
      newErrors.initial_funds = 'Fundos iniciais são obrigatórios';
    } else if (!isEditing && parseFloat(formData.initial_funds) <= 0) {
      newErrors.initial_funds = 'Fundos iniciais devem ser maior que zero';
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
      if (isEditing && portfolio) {
        // Update existing portfolio
        const updateData = {
          name: formData.name,
        };
        await portfolioApi.updatePortfolio(portfolio.portfolio_id, updateData);
        toast.success('Portfólio atualizado com sucesso!');
        router.push(`/portfolios/${portfolio.portfolio_id}`);
      } else {
        // Create new portfolio - try to get user from localStorage, or use default
        let userId = 'default-user'; // Default user ID
        
        try {
          const userData = localStorage.getItem('user');
          if (userData) {
            const user = JSON.parse(userData);
            userId = user.user_id;
          }
        } catch (error) {
          console.log('No user in localStorage, using default');
        }

        const createData: CreatePortfolioRequest = {
          name: formData.name,
          user_id: userId,
        };
        const newPortfolio = await portfolioApi.createPortfolio(createData);
        toast.success('Portfólio criado com sucesso!');
        router.push(`/portfolios/${newPortfolio.portfolio_id}`);
      }
    } catch (error) {
      console.error('Error saving portfolio:', error);
      toast.error(isEditing ? 'Erro ao atualizar portfólio' : 'Erro ao criar portfólio');
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
    <form onSubmit={handleSubmit} className="space-y-6">
      {/* Portfolio Name */}
      <div className="space-y-2">
        <Label htmlFor="name" className="text-slate-300">
          Nome do Portfólio *
        </Label>
        <Input
          id="name"
          type="text"
          placeholder="Ex: Meu Portfólio Tech"
          value={formData.name}
          onChange={(e) => handleInputChange('name', e.target.value)}
          className={`bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
            errors.name ? 'border-red-500' : ''
          }`}
        />
        {errors.name && (
          <p className="text-red-400 text-sm">{errors.name}</p>
        )}
      </div>

      {/* Description */}
      <div className="space-y-2">
        <Label htmlFor="description" className="text-slate-300">
          Descrição (Opcional)
        </Label>
        <textarea
          id="description"
          placeholder="Descreva o objetivo deste portfólio..."
          value={formData.description}
          onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => handleInputChange('description', e.target.value)}
          className="flex min-h-[100px] w-full rounded-md border border-slate-600 bg-slate-700 px-3 py-2 text-sm text-white placeholder:text-slate-400 focus:border-blue-500 focus:outline-none disabled:cursor-not-allowed disabled:opacity-50"
        />
      </div>

      {/* Initial Funds - Only for new portfolios */}
      {!isEditing && (
        <div className="space-y-2">
          <Label htmlFor="initial_funds" className="text-slate-300">
            Fundos Iniciais (USD) *
          </Label>
          <Input
            id="initial_funds"
            type="number"
            step="0.01"
            min="0"
            placeholder="10000.00"
            value={formData.initial_funds}
            onChange={(e) => handleInputChange('initial_funds', e.target.value)}
            className={`bg-slate-700 border-slate-600 text-white placeholder-slate-400 focus:border-blue-500 ${
              errors.initial_funds ? 'border-red-500' : ''
            }`}
          />
          {errors.initial_funds && (
            <p className="text-red-400 text-sm">{errors.initial_funds}</p>
          )}
          <p className="text-slate-400 text-xs">
            Quantidade inicial de dinheiro para investir neste portfólio
          </p>
        </div>
      )}

      {/* Action Buttons */}
      <div className="flex gap-4 pt-4">
        <Button
          type="button"
          variant="outline"
          onClick={() => router.back()}
          className="flex-1 border-slate-600 text-slate-300 hover:bg-slate-700"
        >
          Cancelar
        </Button>
        <Button
          type="submit"
          disabled={loading}
          className="flex-1 bg-blue-600 hover:bg-blue-700"
        >
          {loading ? (
            <div className="flex items-center gap-2">
              <Loader2 className="h-4 w-4 animate-spin" />
              {isEditing ? 'Atualizando...' : 'Criando...'}
            </div>
          ) : (
            <div className="flex items-center gap-2">
              <Save className="h-4 w-4" />
              {isEditing ? 'Atualizar Portfólio' : 'Criar Portfólio'}
            </div>
          )}
        </Button>
      </div>
    </form>
  );
} 