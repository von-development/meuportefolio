import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { AuthProvider } from '@/contexts/AuthContext'
import { Toaster } from 'sonner'

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "meuPortfólio - Gestão Inteligente de Investimentos",
  description: "Plataforma completa para gestão inteligente do seu portfólio de investimentos",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt">
      <body className={inter.className}>
        <AuthProvider>
          {children}
          <Toaster 
            position="top-right"
            theme="dark"
            richColors
          />
        </AuthProvider>
      </body>
    </html>
  );
}
