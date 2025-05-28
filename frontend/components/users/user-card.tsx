'use client';

import { User } from "@/lib/api";
import { Card, CardContent, CardFooter, CardHeader } from "@/components/ui/card";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/utils";
import Link from "next/link";

interface UserCardProps {
  user: User;
  onDelete?: (user: User) => void;
}

export function UserCard({ user, onDelete }: UserCardProps) {
  // Get initials for avatar
  const initials = user.name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);

  return (
    <Card className="hover:shadow-lg transition-shadow">
      <CardHeader className="flex flex-row items-center gap-4 pb-2">
        <Avatar className="h-12 w-12">
          <AvatarImage src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${user.user_id}`} />
          <AvatarFallback>{initials}</AvatarFallback>
        </Avatar>
        <div className="flex flex-col">
          <p className="text-lg font-semibold">{user.name}</p>
          <p className="text-sm text-muted-foreground">{user.email}</p>
        </div>
      </CardHeader>
      <CardContent className="pb-2">
        <div className="grid gap-1">
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">País:</span>
            <span className="text-sm">{user.country_of_residence}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Tipo:</span>
            <span className={`text-sm font-medium ${user.user_type === 'Premium' ? 'text-amber-600' : 'text-slate-600'}`}>
              {user.user_type}
            </span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-sm text-muted-foreground">Criado em:</span>
            <span className="text-sm">{formatDate(user.created_at)}</span>
          </div>
        </div>
      </CardContent>
      <CardFooter className="flex justify-between pt-4">
        <Button variant="outline" asChild>
          <Link href={`/users/${user.user_id}`}>Ver Detalhes</Link>
        </Button>
        {onDelete && (
          <Button variant="destructive" size="sm" onClick={() => onDelete(user)}>
            Excluir
          </Button>
        )}
      </CardFooter>
    </Card>
  );
} 