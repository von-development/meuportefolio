import { Suspense } from 'react';
import { UserProfile } from '@/components/users/user-profile';

interface UserDetailPageProps {
  params: {
    id: string;
  };
}

export default async function UserDetailPage({ params }: UserDetailPageProps) {
  const { id } = await params;
  
  return (
    <div className="container mx-auto py-8 px-4">
      <Suspense fallback={<div>Carregando perfil do usuário...</div>}>
        <UserProfile userId={id} />
      </Suspense>
    </div>
  );
} 