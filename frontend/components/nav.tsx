'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';

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
  return (
    <div className="flex items-center space-x-2">
      <Button variant="outline">Entrar</Button>
      <Button>Cadastrar</Button>
    </div>
  );
}

export function Header() {
  return (
    <header className="border-b">
      <div className="flex h-16 items-center px-4">
        <Link href="/" className="font-bold text-xl">
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