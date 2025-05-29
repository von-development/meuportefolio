import { fetchApi } from './base';

export interface Asset {
    asset_id: number;
    name: string;
    symbol: string;
    asset_type: string;
    price: number;
    volume: number;
    available_shares: number;
    last_updated: string;
}

export interface AssetPriceHistory {
    asset_id: number;
    symbol: string;
    price: number;
    volume: number;
    timestamp: string;
}

export interface AssetHolding {
    portfolio_id: number;
    portfolio_name: string;
    asset_id: number;
    asset_name: string;
    symbol: string;
    asset_type: string;
    quantity_held: number;
    current_price: number;
    market_value: number;
}

export const assetApi = {
    // List all assets with optional filtering
    getAssets: (query?: string, assetType?: string) => {
        const params = new URLSearchParams();
        if (query) params.append('query', query);
        if (assetType) params.append('asset_type', assetType);
        
        const queryString = params.toString();
        return fetchApi<Asset[]>(`/assets${queryString ? `?${queryString}` : ''}`);
    },

    // Get asset details
    getAsset: (id: number) => 
        fetchApi<Asset>(`/assets/${id}`),

    // Get asset price history
    getPriceHistory: (id: number) => 
        fetchApi<AssetPriceHistory[]>(`/assets/${id}/price-history`),

    // List company assets
    getCompanies: () => 
        fetchApi<Asset[]>('/assets/companies'),

    // List index assets
    getIndices: () => 
        fetchApi<Asset[]>('/assets/indices'),
}; 