import { fetchApi } from './base';
import type { AssetHolding } from './asset';

export interface Portfolio {
    portfolio_id: number;
    user_id: string;
    name: string;
    creation_date: string;
    current_funds: number;
    current_profit_pct: number;
    last_updated: string;
}

export interface CreatePortfolioRequest {
    name: string;
    user_id: string;
}

export interface PortfolioSummary {
    portfolio_id: number;
    portfolio_name: string;
    owner: string;
    current_funds: number;
    current_profit_pct: number;
    creation_date: string;
    total_trades: number;
}

export const portfolioApi = {
    getPortfolios: (userId?: string) => 
        fetchApi<Portfolio[]>(userId ? `/portfolios?user_id=${userId}` : '/portfolios'),
    
    getPortfolio: (id: number) => 
        fetchApi<Portfolio>(`/portfolios/${id}`),
    
    createPortfolio: (data: CreatePortfolioRequest) => 
        fetchApi<Portfolio>('/portfolios', {
            method: 'POST',
            body: JSON.stringify(data),
        }),
    
    updatePortfolio: (id: number, data: Partial<Portfolio>) => 
        fetchApi<Portfolio>(`/portfolios/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        }),
    
    deletePortfolio: (id: number) => 
        fetchApi<void>(`/portfolios/${id}`, {
            method: 'DELETE',
        }),

    getPortfolioHoldings: (id: number) => 
        fetchApi<AssetHolding[]>(`/portfolios/${id}/holdings`),

    getPortfolioSummary: (id: number) => 
        fetchApi<PortfolioSummary>(`/portfolios/${id}/summary`),
}; 