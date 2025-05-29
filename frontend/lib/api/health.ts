import { fetchApi } from './base';

export interface HealthResponse {
    status: 'ok';
    message?: string;
}

export const healthApi = {
    check: () => 
        fetchApi<HealthResponse>('/health'),
    
    checkDatabase: () => 
        fetchApi<HealthResponse>('/db-health'),
}; 