import { fetchApi } from './base';

export interface RiskAnalysis {
    user_id: string;
    user_name: string;
    user_type: string;
    total_portfolios: number;
    total_investment: number;
    maximum_drawdown: number | null;
    sharpe_ratio: number | null;
    risk_level: string;
    last_updated: string;
}

export interface PortfolioRiskAnalysis {
    portfolio_id: number;
    portfolio_name: string;
    current_funds: number;
    current_profit_pct: number;
    maximum_drawdown: number | null;
    beta: number | null;
    sharpe_ratio: number | null;
    risk_level: string;
}

export interface RiskSummary {
    total_users: number;
    total_portfolios: number;
    total_assets_under_management: number;
    average_system_risk: number;
    calculated_at: string;
}

export const riskApi = {
    // Get user risk metrics
    getUserRiskMetrics: (userId: string) => 
        fetchApi<RiskAnalysis>(`/risk/metrics/user/${userId}`),

    // Get portfolio risk analysis
    getPortfolioRiskAnalysis: (portfolioId: number) => 
        fetchApi<PortfolioRiskAnalysis>(`/risk/metrics/portfolio/${portfolioId}`),

    // Get overall risk summary
    getRiskSummary: () => 
        fetchApi<RiskSummary>('/risk/summary'),

    // Get portfolio-specific risk summary
    getPortfolioRiskSummary: (portfolioId: number) => 
        fetchApi<RiskSummary>(`/risk/summary/portfolio/${portfolioId}`),

    // Get user-specific risk summary
    getUserRiskSummary: (userId: string) => 
        fetchApi<RiskSummary>(`/risk/summary/user/${userId}`),
}; 