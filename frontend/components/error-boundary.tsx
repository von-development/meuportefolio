'use client';

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { AlertCircle, RefreshCcw } from "lucide-react";

interface ErrorBoundaryProps {
  error: Error;
  reset: () => void;
}

export function ErrorBoundary({ error, reset }: ErrorBoundaryProps) {
  return (
    <div className="min-h-screen flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-red-600">
            <AlertCircle className="h-5 w-5" />
            Erro
          </CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-sm text-gray-600 mb-4">
            {error.message === 'API Error: 404' 
              ? 'O servidor não está disponível no momento. Por favor, verifique se o servidor está rodando e tente novamente.'
              : error.message}
          </p>
          <div className="text-xs text-gray-500">
            <p>Possíveis soluções:</p>
            <ul className="list-disc list-inside mt-2">
              <li>Verifique se o servidor está rodando na porta 8080</li>
              <li>Verifique sua conexão com a internet</li>
              <li>Tente novamente em alguns instantes</li>
            </ul>
          </div>
        </CardContent>
        <CardFooter>
          <Button onClick={reset} className="w-full">
            <RefreshCcw className="h-4 w-4 mr-2" />
            Tentar Novamente
          </Button>
        </CardFooter>
      </Card>
    </div>
  );
} 