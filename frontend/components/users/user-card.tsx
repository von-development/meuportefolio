'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { type User } from '@/lib/api/user';
import { userApi } from '@/lib/api/user';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '@/components/ui/alert-dialog';
import { UserForm } from '@/components/users/user-form';
import { Edit, Trash2, User as UserIcon, MapPin, CreditCard, Eye } from 'lucide-react';
import { formatDate } from '@/lib/utils';
import { toast } from 'sonner';

interface UserCardProps {
  user: User;
  onUserUpdated: (user: User) => void;
  onUserDeleted: (userId: string) => void;
}

export function UserCard({ user, onUserUpdated, onUserDeleted }: UserCardProps) {
  const router = useRouter();
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  const handleDelete = async () => {
    try {
      setIsDeleting(true);
      await userApi.deleteUser(user.user_id);
      onUserDeleted(user.user_id);
      setIsDeleteDialogOpen(false);
    } catch (error) {
      toast.error('Erro ao remover usuário');
    } finally {
      setIsDeleting(false);
    }
  };

  const handleUserUpdated = (updatedUser: User) => {
    onUserUpdated(updatedUser);
    setIsEditDialogOpen(false);
  };

  const handleViewProfile = () => {
    router.push(`/users/${user.user_id}`);
  };

  return (
    <>
      <Card className="hover:shadow-md transition-shadow">
        <CardHeader className="pb-3">
          <CardTitle className="flex items-center justify-between text-lg">
            <div className="flex items-center gap-2">
              <UserIcon className="h-5 w-5" />
              {user.name}
            </div>
            <Badge variant={user.user_type === 'Premium' ? 'default' : 'secondary'}>
              {user.user_type}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2 text-muted-foreground">
              <span className="font-medium">Email:</span>
              <span>{user.email}</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <MapPin className="h-4 w-4" />
              <span>{user.country_of_residence}</span>
            </div>
            <div className="flex items-center gap-2 text-muted-foreground">
              <CreditCard className="h-4 w-4" />
              <span>{user.iban}</span>
            </div>
            <div className="text-xs text-muted-foreground">
              Criado em: {formatDate(user.created_at)}
            </div>
          </div>

          <div className="space-y-2 pt-2">
            {/* Primary Action - View Profile */}
            <Button
              onClick={handleViewProfile}
              className="w-full"
              size="sm"
            >
              <Eye className="h-4 w-4 mr-2" />
              Ver Perfil
            </Button>
            
            {/* Secondary Actions */}
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsEditDialogOpen(true)}
                className="flex-1"
              >
                <Edit className="h-4 w-4 mr-1" />
                Editar
              </Button>
              <Button
                variant="destructive"
                size="sm"
                onClick={() => setIsDeleteDialogOpen(true)}
                className="flex-1"
              >
                <Trash2 className="h-4 w-4 mr-1" />
                Remover
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Editar Usuário</DialogTitle>
          </DialogHeader>
          <UserForm user={user} onUserCreated={handleUserUpdated} />
        </DialogContent>
      </Dialog>

      {/* Delete Confirmation Dialog */}
      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Confirmar Remoção</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja remover o usuário <strong>{user.name}</strong>? 
              Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              disabled={isDeleting}
              className="bg-destructive hover:bg-destructive/90"
            >
              {isDeleting ? 'Removendo...' : 'Remover'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
} 