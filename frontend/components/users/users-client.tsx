'use client';

import { User, api } from "@/lib/api";
import { UserCard } from "./user-card";
import { Button } from "@/components/ui/button";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { toast } from "sonner";

interface UsersClientProps {
  users: User[];
}

export function UsersClient({ users: initialUsers }: UsersClientProps) {
  const [users, setUsers] = useState<User[]>(initialUsers);
  const router = useRouter();

  const handleDelete = async (user: User) => {
    try {
      await api.deleteUser(user.user_id);
      setUsers(users.filter(u => u.user_id !== user.user_id));
      toast.success("Usuário excluído com sucesso");
      router.refresh();
    } catch (error) {
      console.error('Error deleting user:', error);
      toast.error("Não foi possível excluir o usuário. Tente novamente.");
    }
  };

  return (
    <div className="container mx-auto py-10">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Usuários</h1>
        <Button>Novo Usuário</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {users.map((user) => (
          <UserCard 
            key={user.user_id}
            user={user}
            onDelete={handleDelete}
          />
        ))}
      </div>
    </div>
  );
} 