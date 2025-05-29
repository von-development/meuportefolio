import { Suspense } from 'react';
import { UsersList } from '@/components/users/users-list';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';

export default function UsersPage() {
  return (
    <div className="container mx-auto py-8 px-4">
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold">Usuários</h1>
            <p className="text-muted-foreground mt-2">
              Gerencie todos os usuários da plataforma
            </p>
          </div>
        </div>

        {/* Users List */}
        <Card>
          <CardHeader>
            <CardTitle>Lista de Usuários</CardTitle>
            <CardDescription>
              Visualize e gerencie todos os usuários cadastrados
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Suspense fallback={<div>Carregando usuários...</div>}>
              <UsersList />
            </Suspense>
          </CardContent>
        </Card>
      </div>
    </div>
  );
} 