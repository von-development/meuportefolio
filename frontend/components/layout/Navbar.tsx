'use client'

import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter, usePathname } from 'next/navigation'
import { Button } from '@/components/ui/button'
import { 
  DropdownMenu, 
  DropdownMenuContent, 
  DropdownMenuItem, 
  DropdownMenuLabel, 
  DropdownMenuSeparator, 
  DropdownMenuTrigger 
} from '@/components/ui/dropdown-menu'
import { Badge } from '@/components/ui/badge'
import { 
  User, 
  LogOut, 
  Settings, 
  CreditCard, 
  Crown,
  ChevronDown,
  Home,
  PieChart,
  TrendingUp,
  Menu,
  X,
  Search,
  Briefcase,
  Plus,
  Wallet,
  Activity
} from 'lucide-react'
import { useAuth } from '@/contexts/AuthContext'

interface NavigationItem {
  name: string
  href: string
  icon: any
  current: boolean
}

interface Portfolio {
  portfolio_id: number
  user_id: string
  name: string
  creation_date: string
  current_funds: number
  current_profit_pct: number
  last_updated: string
}

export default function Navbar() {
  const { user, logout, isAuthenticated } = useAuth()
  const router = useRouter()
  const pathname = usePathname()
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [portfolios, setPortfolios] = useState<Portfolio[]>([])

  useEffect(() => {
    if (isAuthenticated && user?.user_id) {
      fetchPortfolios()
    }
  }, [isAuthenticated, user?.user_id])

  const fetchPortfolios = async () => {
    try {
      const response = await fetch(`http://localhost:8080/api/v1/portfolios?user_id=${user?.user_id}`)
      if (response.ok) {
        const data = await response.json()
        setPortfolios(data)
      }
    } catch (error) {
      console.error('Failed to fetch portfolios:', error)
    }
  }

  const handleLogout = async () => {
    try {
      await logout()
      router.push('/')
    } catch (error) {
      console.error('Logout failed:', error)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('pt-PT', {
      style: 'currency',
      currency: 'EUR'
    }).format(amount)
  }

  const formatPercentage = (percentage: number) => {
    return `${percentage >= 0 ? '+' : ''}${percentage.toFixed(2)}%`
  }

  // Navigation for authenticated users
  const authNavigation: NavigationItem[] = [
    {
      name: 'Dashboard',
      href: '/dashboard',
      icon: Home,
      current: pathname === '/dashboard'
    },
    {
      name: 'Trading',
      href: '/trading',
      icon: Activity,
      current: pathname === '/trading'
    },
    {
      name: 'Ativos',
      href: '/assets',
      icon: TrendingUp,
      current: pathname.startsWith('/assets')
    }
  ]

  // Navigation for unauthenticated users
  const publicNavigation: NavigationItem[] = [
    {
      name: 'Ativos',
      href: '/assets',
      icon: Search,
      current: pathname.startsWith('/assets')
    }
  ]

  const navigation = isAuthenticated ? authNavigation : publicNavigation

  if (!isAuthenticated) {
    return (
      <nav className="bg-gray-900/95 backdrop-blur-sm border-b border-blue-800/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            {/* Logo */}
            <Link href="/" className="flex items-center">
              <span className="text-2xl font-bold text-white">
                meu<span className="text-blue-400">Portfólio</span>
              </span>
            </Link>

            {/* Navigation Links */}
            <div className="hidden md:flex items-center space-x-8">
              {publicNavigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className="text-gray-300 hover:text-white transition-colors duration-200 flex items-center gap-2"
                >
                  <item.icon className="h-4 w-4" />
                  {item.name}
                </Link>
              ))}
            </div>

            {/* Auth Buttons */}
            <div className="flex items-center space-x-4">
              <Button 
                asChild
                variant="ghost" 
                className="text-gray-300 hover:text-white hover:bg-blue-600/20"
              >
                <Link href="/login">Entrar</Link>
              </Button>
              <Button 
                asChild
                className="bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white"
              >
                <Link href="/signup">Criar Conta</Link>
              </Button>
            </div>
          </div>
        </div>
      </nav>
    )
  }

  return (
    <>
      <nav className="bg-gray-900/95 backdrop-blur-sm border-b border-blue-800/30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between h-16">
            {/* Logo */}
            <div className="flex items-center">
              <Link href="/dashboard" className="flex-shrink-0 flex items-center">
                <span className="text-2xl font-bold text-white">
                  meu<span className="text-blue-400">Portfólio</span>
                </span>
              </Link>
            </div>

            {/* Desktop Navigation - Simplified */}
            <div className="hidden md:flex md:items-center md:space-x-8">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`text-gray-300 hover:text-white transition-colors duration-200 flex items-center gap-2 px-3 py-2 rounded-md ${
                    item.current ? 'text-blue-400 bg-blue-600/20' : ''
                  }`}
                >
                  <item.icon className="h-5 w-5" />
                  <span className="font-medium">{item.name}</span>
                </Link>
              ))}

              {/* Portfolio Dropdown */}
              {isAuthenticated && (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button 
                      variant="ghost" 
                      className={`text-gray-300 hover:text-white transition-colors duration-200 flex items-center gap-2 px-3 py-2 rounded-md ${
                        pathname.startsWith('/portfolios') ? 'text-blue-400 bg-blue-600/20' : ''
                      }`}
                    >
                      <PieChart className="h-5 w-5" />
                      <span className="font-medium">Portfólios</span>
                      <ChevronDown className="h-3 w-3" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent 
                    align="center" 
                    className="w-80 bg-gray-800 border-gray-700"
                  >
                    <DropdownMenuLabel className="font-normal">
                      <div className="flex items-center justify-between">
                        <span className="text-sm font-medium text-white">Meus Portfólios</span>
                        <Link href="/dashboard?tab=portfolios">
                          <Button variant="ghost" size="sm" className="h-6 text-xs text-gray-400 hover:text-white">
                            Ver Todos
                          </Button>
                        </Link>
                      </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator className="bg-gray-700" />
                    
                    {portfolios.length === 0 ? (
                      <DropdownMenuItem disabled className="text-gray-400 py-4">
                        <div className="text-center w-full">
                          <PieChart className="h-8 w-8 mx-auto mb-2 text-gray-600" />
                          <p className="text-sm">Nenhum portfólio criado</p>
                        </div>
                      </DropdownMenuItem>
                    ) : (
                      portfolios.slice(0, 3).map((portfolio) => (
                        <DropdownMenuItem key={portfolio.portfolio_id} asChild>
                          <Link 
                            href={`/portfolios/${portfolio.portfolio_id}`}
                            className="cursor-pointer text-gray-300 hover:text-white hover:bg-gray-700 py-3"
                          >
                            <div className="flex items-center justify-between w-full">
                              <div className="flex items-center gap-3">
                                <div className="bg-blue-600/20 rounded-lg p-2">
                                  <Wallet className="h-4 w-4 text-blue-400" />
                                </div>
                                <div>
                                  <p className="font-medium text-white">{portfolio.name}</p>
                                  <p className="text-xs text-gray-400">
                                    {formatCurrency(portfolio.current_funds)}
                                  </p>
                                </div>
                              </div>
                              <div className="text-right">
                                <p className={`text-sm font-medium ${
                                  portfolio.current_profit_pct >= 0 ? 'text-green-400' : 'text-red-400'
                                }`}>
                                  {formatPercentage(portfolio.current_profit_pct)}
                                </p>
                              </div>
                            </div>
                          </Link>
                        </DropdownMenuItem>
                      ))
                    )}

                    <DropdownMenuSeparator className="bg-gray-700" />
                    <DropdownMenuItem asChild>
                      <Link 
                        href="/dashboard?tab=portfolios" 
                        className="cursor-pointer text-blue-400 hover:text-blue-300 hover:bg-blue-500/10"
                      >
                        <Plus className="mr-2 h-4 w-4" />
                        <span>Criar Novo Portfólio</span>
                      </Link>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              )}
            </div>

            {/* User Menu */}
            <div className="flex items-center space-x-4">
              {/* Premium Badge */}
              {user?.user_type === 'Premium' && (
                <Badge variant="secondary" className="bg-yellow-100 text-yellow-800">
                  <Crown className="h-3 w-3 mr-1" />
                  Premium
                </Badge>
              )}

              {/* User Dropdown */}
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button 
                    variant="ghost" 
                    className="flex items-center gap-2 text-gray-300 hover:text-white hover:bg-blue-600/20"
                  >
                    <User className="h-4 w-4" />
                    <span className="hidden sm:inline">{user?.name?.split(' ')[0]}</span>
                    <ChevronDown className="h-3 w-3" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent 
                  align="end" 
                  className="w-56 bg-gray-800 border-gray-700"
                >
                  <DropdownMenuLabel className="font-normal">
                    <div className="flex flex-col space-y-1">
                      <p className="text-sm font-medium text-white">{user?.name}</p>
                      <p className="text-xs text-gray-400">{user?.email}</p>
                    </div>
                  </DropdownMenuLabel>
                  <DropdownMenuSeparator className="bg-gray-700" />
                  
                  <DropdownMenuItem asChild>
                    <Link href="/profile" className="cursor-pointer text-gray-300 hover:text-white hover:bg-gray-700">
                      <User className="mr-2 h-4 w-4" />
                      <span>Meu Perfil</span>
                    </Link>
                  </DropdownMenuItem>

                  <DropdownMenuItem asChild>
                    <Link href="/account" className="cursor-pointer text-gray-300 hover:text-white hover:bg-gray-700">
                      <CreditCard className="mr-2 h-4 w-4" />
                      <span>Conta & Fundos</span>
                    </Link>
                  </DropdownMenuItem>
                  
                  <DropdownMenuItem asChild>
                    <Link href="/settings" className="cursor-pointer text-gray-300 hover:text-white hover:bg-gray-700">
                      <Settings className="mr-2 h-4 w-4" />
                      <span>Definições</span>
                    </Link>
                  </DropdownMenuItem>

                  {user?.user_type !== 'Premium' && (
                    <>
                      <DropdownMenuSeparator className="bg-gray-700" />
                      <DropdownMenuItem asChild>
                        <Link href="/premium" className="cursor-pointer text-yellow-400 hover:text-yellow-300 hover:bg-yellow-500/10">
                          <Crown className="mr-2 h-4 w-4" />
                          <span>Upgrade para Premium</span>
                        </Link>
                      </DropdownMenuItem>
                    </>
                  )}

                  <DropdownMenuSeparator className="bg-gray-700" />
                  <DropdownMenuItem 
                    onClick={handleLogout} 
                    className="cursor-pointer text-red-400 hover:text-red-300 hover:bg-red-500/10"
                  >
                    <LogOut className="mr-2 h-4 w-4" />
                    <span>Terminar Sessão</span>
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>

              {/* Mobile menu button */}
              <div className="md:hidden">
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                  className="text-gray-300 hover:text-white"
                >
                  {isMobileMenuOpen ? (
                    <X className="h-6 w-6" />
                  ) : (
                    <Menu className="h-6 w-6" />
                  )}
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Mobile Navigation */}
        {isMobileMenuOpen && (
          <div className="md:hidden border-t border-gray-700">
            <div className="px-2 pt-2 pb-3 space-y-1 bg-gray-900/95">
              {navigation.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`flex items-center space-x-2 px-3 py-2 rounded-md text-base font-medium transition-colors ${
                    item.current
                      ? 'text-blue-400 bg-blue-600/20'
                      : 'text-gray-300 hover:text-white hover:bg-gray-700'
                  }`}
                  onClick={() => setIsMobileMenuOpen(false)}
                >
                  <item.icon className="h-5 w-5" />
                  <span>{item.name}</span>
                </Link>
              ))}
            </div>
          </div>
        )}
      </nav>
    </>
  )
} 