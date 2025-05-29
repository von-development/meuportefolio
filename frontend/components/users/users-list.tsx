'use client';

import { useEffect, useState } from 'react';
import { useUser } from '@/lib/hooks/useUser';
import { userApi, type User } from '@/lib/api/user';
import { UserCard } from '@/components/users/user-card';
import { UserForm } from '@/components/users/user-form';
import { Button } from '@/components/ui/button';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { UserPlus, Loader2 } from 'lucide-react';
import { toast } from 'sonner';

export function UsersList() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const [isAddDialogOpen, setIsAddDialogOpen] = useState(false);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await userApi.getUsers();
      setUsers(data);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Failed to fetch users'));
      toast.error('Erro ao carregar usuários');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleUserCreated = (newUser: User) => {
    setUsers(prev => [...prev, newUser]);
    setIsAddDialogOpen(false);
    toast.success('Usuário criado com sucesso!');
  };

  const handleUserUpdated = (updatedUser: User) => {
    setUsers(prev => 
      prev.map(user => 
        user.user_id === updatedUser.user_id ? updatedUser : user
      )
    );
    toast.success('Usuário atualizado com sucesso!');
  };

  const handleUserDeleted = (userId: string) => {
    setUsers(prev => prev.filter(user => user.user_id !== userId));
    toast.success('Usuário removido com sucesso!');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <Loader2 className="h-6 w-6 animate-spin" />
        <span className="ml-2">Carregando usuários...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-8">
        <p className="text-destructive mb-4">Erro ao carregar usuários: {error.message}</p>
        <Button onClick={fetchUsers} variant="outline">
          Tentar novamente
        </Button>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Add User Dialog */}
      <div className="flex justify-end">
        <Dialog open={isAddDialogOpen} onOpenChange={setIsAddDialogOpen}>
          <DialogTrigger asChild>
            <Button className="flex items-center gap-2">
              <UserPlus className="h-4 w-4" />
              Adicionar Usuário
            </Button>
          </DialogTrigger>
          <DialogContent className="max-w-md">
            <DialogHeader>
              <DialogTitle>Adicionar Novo Usuário</DialogTitle>
            </DialogHeader>
            <UserForm onUserCreated={handleUserCreated} />
          </DialogContent>
        </Dialog>
      </div>

      {/* Users Grid */}
      {users.length === 0 ? (
        <div className="text-center py-8">
          <p className="text-muted-foreground">Nenhum usuário encontrado</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {users.map(user => (
            <UserCard
              key={user.user_id}
              user={user}
              onUserUpdated={handleUserUpdated}
              onUserDeleted={handleUserDeleted}
            />
          ))}
        </div>
      )}
    </div>
  );
} 