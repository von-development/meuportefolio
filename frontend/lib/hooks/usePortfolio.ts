import { useState, useCallback } from 'react';
import { portfolioApi, type Portfolio, type CreatePortfolioRequest, type PortfolioSummary } from '../api/portfolio';
import type { AssetHolding } from '../api/asset';

export function usePortfolio(userId?: string) {
    const [portfolios, setPortfolios] = useState<Portfolio[]>([]);
    const [selectedPortfolio, setSelectedPortfolio] = useState<Portfolio | null>(null);
    const [holdings, setHoldings] = useState<AssetHolding[]>([]);
    const [summary, setSummary] = useState<PortfolioSummary | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<Error | null>(null);

    const fetchPortfolios = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await portfolioApi.getPortfolios(userId);
            setPortfolios(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch portfolios'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, [userId]);

    const createPortfolio = useCallback(async (name: string) => {
        if (!userId) throw new Error('User ID is required to create a portfolio');
        
        setLoading(true);
        setError(null);
        try {
            const newPortfolio = await portfolioApi.createPortfolio({ name, user_id: userId });
            setPortfolios(prev => [...prev, newPortfolio]);
            return newPortfolio;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to create portfolio'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, [userId]);

    const updatePortfolio = useCallback(async (portfolioId: number, data: Partial<Portfolio>) => {
        setLoading(true);
        setError(null);
        try {
            const updatedPortfolio = await portfolioApi.updatePortfolio(portfolioId, data);
            setPortfolios(prev => 
                prev.map(p => p.portfolio_id === portfolioId ? updatedPortfolio : p)
            );
            if (selectedPortfolio?.portfolio_id === portfolioId) {
                setSelectedPortfolio(updatedPortfolio);
            }
            return updatedPortfolio;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to update portfolio'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, [selectedPortfolio]);

    const deletePortfolio = useCallback(async (portfolioId: number) => {
        setLoading(true);
        setError(null);
        try {
            await portfolioApi.deletePortfolio(portfolioId);
            setPortfolios(prev => prev.filter(p => p.portfolio_id !== portfolioId));
            if (selectedPortfolio?.portfolio_id === portfolioId) {
                setSelectedPortfolio(null);
            }
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to delete portfolio'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, [selectedPortfolio]);

    const fetchPortfolioHoldings = useCallback(async (portfolioId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await portfolioApi.getPortfolioHoldings(portfolioId);
            setHoldings(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch portfolio holdings'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchPortfolioSummary = useCallback(async (portfolioId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await portfolioApi.getPortfolioSummary(portfolioId);
            setSummary(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch portfolio summary'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    return {
        portfolios,
        selectedPortfolio,
        holdings,
        summary,
        loading,
        error,
        fetchPortfolios,
        createPortfolio,
        updatePortfolio,
        deletePortfolio,
        fetchPortfolioHoldings,
        fetchPortfolioSummary,
    };
} 