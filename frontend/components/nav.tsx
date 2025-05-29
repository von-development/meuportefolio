'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { authApi } from '@/lib/api/auth';
import { toast } from 'sonner';
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu';
import { User, LogOut, Settings, ChevronDown } from 'lucide-react';

interface UserData {
  user_id: string;
  name: string;
  email: string;
  user_type: string;
}

export function MainNav() {
  const pathname = usePathname();

  const navItems = [
    { href: '/', label: 'Visão Geral' },
    { href: '/assets', label: 'Ativos' },
    { href: '/portfolios', label: 'Portfólios' },
    { href: '/users', label: 'Usuários' },
  ];

  return (
    <nav className="flex items-center space-x-4 lg:space-x-6 mx-6">
      {navItems.map(item => {
        const isActive = pathname === item.href || 
          (item.href !== '/' && pathname.startsWith(item.href));

        return (
          <Link 
            key={item.href}
            href={item.href} 
            className={cn(
              "text-sm font-medium transition-colors hover:text-primary",
              isActive 
                ? "text-primary" 
                : "text-muted-foreground"
            )}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}

export function UserNav() {
  const router = useRouter();
  const [user, setUser] = useState<UserData | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Check for user data in localStorage on component mount
    const userData = localStorage.getItem('user');
    if (userData) {
      try {
        setUser(JSON.parse(userData));
      } catch (error) {
        console.error('Error parsing user data:', error);
        localStorage.removeItem('user');
      }
    }
  }, []);

  const handleLogout = async () => {
    setLoading(true);
    try {
      await authApi.logout();
      localStorage.removeItem('user');
      setUser(null);
      toast.success('Logout realizado com sucesso!');
      router.push('/');
    } catch (error) {
      console.error('Logout error:', error);
      toast.error('Erro ao fazer logout');
    } finally {
      setLoading(false);
    }
  };

  if (user) {
    return (
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="relative h-8 w-auto px-3 text-sm">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center">
                <User className="h-4 w-4 text-white" />
              </div>
              <div className="hidden md:block text-left">
                <p className="text-sm font-medium text-white">{user.name}</p>
                <p className="text-xs text-slate-400">{user.user_type}</p>
              </div>
              <ChevronDown className="h-4 w-4 text-slate-400" />
            </div>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent className="w-56 bg-slate-800 border-slate-700" align="end" forceMount>
          <DropdownMenuLabel className="font-normal">
            <div className="flex flex-col space-y-1">
              <p className="text-sm font-medium leading-none text-white">{user.name}</p>
              <p className="text-xs leading-none text-slate-400">{user.email}</p>
            </div>
          </DropdownMenuLabel>
          <DropdownMenuSeparator className="bg-slate-700" />
          <DropdownMenuItem className="text-slate-300 hover:bg-slate-700 hover:text-white cursor-pointer">
            <Settings className="mr-2 h-4 w-4" />
            <span>Configurações</span>
          </DropdownMenuItem>
          <DropdownMenuSeparator className="bg-slate-700" />
          <DropdownMenuItem 
            className="text-red-400 hover:bg-red-600 hover:text-white cursor-pointer"
            onClick={handleLogout}
            disabled={loading}
          >
            <LogOut className="mr-2 h-4 w-4" />
            <span>{loading ? 'Saindo...' : 'Sair'}</span>
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    );
  }

  return (
    <div className="flex items-center space-x-2">
      <Button variant="outline" asChild className="border-slate-600 text-slate-300 hover:bg-slate-800">
        <Link href="/login">Entrar</Link>
      </Button>
      <Button asChild className="bg-blue-600 hover:bg-blue-700">
        <Link href="/register">Cadastrar</Link>
      </Button>
    </div>
  );
}

export function Header() {
  return (
    <header className="border-b border-slate-700 bg-slate-900">
      <div className="flex h-16 items-center px-4">
        <Link href="/" className="font-bold text-xl text-white">
          meuPortefólio
        </Link>
        <MainNav />
        <div className="ml-auto flex items-center space-x-4">
          <UserNav />
        </div>
      </div>
    </header>
  );
} 