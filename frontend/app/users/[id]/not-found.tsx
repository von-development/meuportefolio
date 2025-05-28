import { Button } from "@/components/ui/button";
import Link from "next/link";

export default function UserNotFound() {
  return (
    <div className="container mx-auto py-10">
      <div className="max-w-md mx-auto text-center">
        <h2 className="text-2xl font-bold mb-4">Usuário não encontrado</h2>
        <p className="text-muted-foreground mb-6">
          O usuário que você está procurando não existe ou foi removido.
        </p>
        <Button asChild>
          <Link href="/users">Voltar para Lista de Usuários</Link>
        </Button>
      </div>
    </div>
  );
} 