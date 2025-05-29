import { useState, useCallback } from 'react';
import { assetApi, type Asset, type AssetPriceHistory } from '../api/asset';

export function useAsset() {
    const [assets, setAssets] = useState<Asset[]>([]);
    const [selectedAsset, setSelectedAsset] = useState<Asset | null>(null);
    const [priceHistory, setPriceHistory] = useState<AssetPriceHistory[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<Error | null>(null);

    const fetchAssets = useCallback(async (query?: string, assetType?: string) => {
        setLoading(true);
        setError(null);
        try {
            const data = await assetApi.getAssets(query, assetType);
            setAssets(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch assets'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchAssetDetails = useCallback(async (assetId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await assetApi.getAsset(assetId);
            setSelectedAsset(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch asset details'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchPriceHistory = useCallback(async (assetId: number) => {
        setLoading(true);
        setError(null);
        try {
            const data = await assetApi.getPriceHistory(assetId);
            setPriceHistory(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch price history'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchCompanies = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await assetApi.getCompanies();
            setAssets(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch companies'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const fetchIndices = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            const data = await assetApi.getIndices();
            setAssets(data);
            return data;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Failed to fetch indices'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    return {
        assets,
        selectedAsset,
        priceHistory,
        loading,
        error,
        fetchAssets,
        fetchAssetDetails,
        fetchPriceHistory,
        fetchCompanies,
        fetchIndices,
    };
} 