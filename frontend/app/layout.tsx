import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Header } from "@/components/nav";
import { cn } from "@/lib/utils";
import { Toaster } from "sonner";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "meuPortefólio",
  description: "Sua plataforma de gestão de investimentos",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR" className="dark">
      <body className={cn(inter.className, "min-h-screen bg-background antialiased")}>
        <div className="relative min-h-screen bg-background">
          {/* Background gradient */}
          <div className="absolute inset-0 bg-gradient-to-b from-background via-background to-background/80 pointer-events-none" />
          
          {/* Background pattern */}
          <div className="absolute inset-0 bg-grid-white/[0.02] bg-[size:20px_20px] pointer-events-none" />
          
          {/* Content */}
          <div className="relative">
            <Header />
            <main className="flex-1">{children}</main>
          </div>
          <Toaster richColors position="top-right" />
        </div>
      </body>
    </html>
  );
}
