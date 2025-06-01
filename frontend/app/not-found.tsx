'use client'

import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Home, ArrowLeft } from 'lucide-react'
import Navbar from '@/components/layout/Navbar'

export default function NotFound() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-blue-950 to-gray-900">
      {/* Navbar */}
      <Navbar />
      
      <div className="flex items-center justify-center px-6" style={{ minHeight: 'calc(100vh - 64px)' }}>
        <div className="text-center">
          <div className="mb-8">
            <h1 className="text-8xl md:text-9xl font-bold text-blue-400 mb-4">404</h1>
            <h2 className="text-3xl md:text-4xl font-bold text-white mb-4">
              Página não encontrada
            </h2>
            <p className="text-xl text-gray-400 max-w-md mx-auto mb-8">
              A página que procura não existe ou foi movida para outro local.
            </p>
          </div>

          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button asChild size="lg" className="bg-blue-600 hover:bg-blue-700 text-white">
              <Link href="/">
                <Home className="h-5 w-5 mr-2" />
                Ir para Início
              </Link>
            </Button>
            
            <Button 
              onClick={() => window.history.back()} 
              variant="outline" 
              size="lg"
              className="border-gray-600 text-gray-300 hover:bg-gray-800/50"
            >
              <ArrowLeft className="h-5 w-5 mr-2" />
              Voltar
            </Button>
          </div>

          <div className="mt-12">
            <div className="text-center">
              <h3 className="text-xl font-semibold text-white mb-4">
                Explore nossos recursos
              </h3>
              <div className="flex flex-wrap gap-4 justify-center">
                <Button asChild variant="ghost" className="text-gray-300 hover:text-blue-400">
                  <Link href="/assets">Explorar Ativos</Link>
                </Button>
                <Button asChild variant="ghost" className="text-gray-300 hover:text-blue-400">
                  <Link href="/portfolios">Ver Portfólios</Link>
                </Button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
} 