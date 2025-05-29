import { useState, useCallback } from 'react';
import { riskApi, type RiskAnalysis, type PortfolioRiskAnalysis, type RiskSummary } from '../api/risk';

export function useRisk() {
    const [userRiskMetrics, setUserRiskMetrics] = useState<RiskAnalysis | null>(null);
    const [portfolioRiskAnalysis, setPortfolioRiskAnalysis] = useState<PortfolioRiskAnalysis | null>(null);
    const [riskSummary, setRiskSummary] = useState<RiskSummary | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<Error | null>(null);

    const fetchUserRiskMetrics = useCallback(async (userId: string) => {
        setLoading(true);
        setError(null);
        try {
            const data = await riskApi.getUserRiskMetrics(userId);
            setUserRiskMetrics(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch user risk metrics'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchPortfolioRiskAnalysis = useCallback(async (portfolioId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await riskApi.getPortfolioRiskAnalysis(portfolioId);
            setPortfolioRiskAnalysis(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch portfolio risk analysis'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchRiskSummary = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await riskApi.getRiskSummary();
            setRiskSummary(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch risk summary'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchPortfolioRiskSummary = useCallback(async (portfolioId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await riskApi.getPortfolioRiskSummary(portfolioId);
            setRiskSummary(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch portfolio risk summary'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchUserRiskSummary = useCallback(async (userId: string) => {
        setLoading(true);
        setError(null);
        try {
            const data = await riskApi.getUserRiskSummary(userId);
            setRiskSummary(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch user risk summary'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    return {
        userRiskMetrics,
        portfolioRiskAnalysis,
        riskSummary,
        loading,
        error,
        fetchUserRiskMetrics,
        fetchPortfolioRiskAnalysis,
        fetchRiskSummary,
        fetchPortfolioRiskSummary,
        fetchUserRiskSummary,
    };
} 