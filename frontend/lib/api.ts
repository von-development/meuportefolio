// Types
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

export interface User {
    user_id: string;
    name: string;
    email: string;
    country_of_residence: string;
    iban: string;
    user_type: 'Basic' | 'Premium';
    created_at: string;
    updated_at: string;
}

export interface Portfolio {
    portfolio_id: number;
    user_id: string;
    name: string;
    creation_date: string;
    current_funds: number;
    current_profit_pct: number;
    last_updated: string;
}

export interface LoginRequest {
    email: string;
    password: string;
}

export interface LoginResponse {
    token: string;
    user: User;
}

export interface SignupRequest {
    name: string;
    email: string;
    password: string;
    country_of_residence: string;
    iban: string;
}

// API Configuration
const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api/v1';

// Custom error class for API errors
export class APIError extends Error {
    constructor(
        public message: string,
        public status: number
    ) {
        super(message);
        this.name = 'APIError';
    }
}

// Helper function to check if the server is available
async function checkServer(): Promise<boolean> {
    try {
        const response = await fetch('http://localhost:8080/health');
        return response.ok;
    } catch {
        return false;
    }
}

// Helper function to handle API responses
async function handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
        // Log the full response details for debugging
        console.error('API Error Response:', {
            status: response.status,
            statusText: response.statusText,
            headers: Object.fromEntries(response.headers.entries()),
        });

        let errorMessage = 'An error occurred';
        try {
            const errorData = await response.json();
            console.error('API Error Data:', errorData);
            errorMessage = errorData.message || errorMessage;
        } catch (e) {
            console.error('Failed to parse error response:', e);
            // Try to get the text response if JSON parsing fails
            try {
                const textError = await response.text();
                console.error('Error Response Text:', textError);
                errorMessage = textError || errorMessage;
            } catch (e2) {
                console.error('Failed to get error text:', e2);
            }
        }
        throw new APIError(errorMessage, response.status);
    }

    // Check if there's any content to parse
    const contentLength = response.headers.get('content-length');
    const contentType = response.headers.get('content-type');
    
    if (contentLength === '0' || !contentType?.includes('application/json')) {
        return {} as T;
    }

    try {
        return await response.json();
    } catch (error) {
        console.error('Failed to parse response as JSON:', error);
        return {} as T;
    }
}

// Helper function to make API requests
async function makeRequest<T>(
    url: string,
    options: RequestInit = {}
): Promise<T> {
    try {
        const isServerAvailable = await checkServer();
        if (!isServerAvailable) {
            throw new APIError(
                'O servidor não está disponível. Por favor, verifique se o servidor está rodando e tente novamente.',
                503
            );
        }

        const response = await fetch(url, {
            ...options,
            headers: {
                'Content-Type': 'application/json',
                ...options.headers,
            },
        });

        return handleResponse<T>(response);
    } catch (error) {
        if (error instanceof APIError) {
            throw error;
        }
        
        if (error instanceof TypeError && error.message === 'Failed to fetch') {
            throw new APIError(
                'Não foi possível conectar ao servidor. Por favor, verifique sua conexão e tente novamente.',
                503
            );
        }

        throw new APIError('Um erro inesperado ocorreu. Por favor, tente novamente.', 500);
    }
}

// API Service
export const api = {
    // Assets
    getAssets: async (): Promise<Asset[]> => {
        return makeRequest<Asset[]>(`${API_BASE}/assets`);
    },

    getAssetDetails: async (id: number): Promise<Asset> => {
        return makeRequest<Asset>(`${API_BASE}/assets/${id}`);
    },

    // Users
    getUsers: async (): Promise<User[]> => {
        return makeRequest<User[]>(`${API_BASE}/users`);
    },

    getUserDetails: async (id: string): Promise<User> => {
        return makeRequest<User>(`${API_BASE}/users/${id}`);
    },

    createUser: async (data: Partial<User>): Promise<User> => {
        return makeRequest<User>(`${API_BASE}/users`, {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    updateUser: async (id: string, data: Partial<User>, token?: string): Promise<User> => {
        const headers: Record<string, string> = {
            'Content-Type': 'application/json',
        };
        
        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }
        
        const response = await fetch(`${API_BASE}/users/${id}`, {
            method: 'PUT',
            headers,
            body: JSON.stringify(data),
        });
        return handleResponse<User>(response);
    },

    deleteUser: async (id: string): Promise<void> => {
        return makeRequest<void>(`${API_BASE}/users/${id}`, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            },
        });
    },

    login: async (credentials: LoginRequest): Promise<LoginResponse> => {
        const response = await fetch(`${API_BASE}/users/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(credentials),
        });
        return handleResponse<LoginResponse>(response);
    },

    signup: async (userData: SignupRequest): Promise<User> => {
        console.log('Signup Request Data:', userData);
        const response = await fetch(`${API_BASE}/users`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                ...userData,
                user_type: 'Basic',
            }),
        });
        return handleResponse<User>(response);
    },

    logout: async (token: string): Promise<void> => {
        const response = await fetch(`${API_BASE}/users/logout`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });
        return handleResponse<void>(response);
    },

    getUser: async (id: string, token: string): Promise<User> => {
        const response = await fetch(`${API_BASE}/users/${id}`, {
            headers: {
                'Authorization': `Bearer ${token}`,
            },
        });
        return handleResponse<User>(response);
    },

    // Portfolios
    getPortfolios: async (userId?: string): Promise<Portfolio[]> => {
        const url = userId 
            ? `${API_BASE}/portfolios?user_id=${userId}`
            : `${API_BASE}/portfolios`;
        
        return makeRequest<Portfolio[]>(url);
    },

    createPortfolio: async (userId: string, data: Partial<Portfolio>): Promise<Portfolio> => {
        return makeRequest<Portfolio>(`${API_BASE}/portfolios`, {
            method: 'POST',
            body: JSON.stringify({
                name: data.name,
                user_id: userId,
                initial_funds: 0 // Required by the backend
            }),
        });
    },

    updatePortfolio: async (portfolioId: number, data: Partial<Portfolio>): Promise<Portfolio> => {
        return makeRequest<Portfolio>(`${API_BASE}/portfolios/${portfolioId}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    deletePortfolio: async (portfolioId: number): Promise<void> => {
        return makeRequest<void>(`${API_BASE}/portfolios/${portfolioId}`, {
            method: 'DELETE',
        });
    },

    async getPortfolioDetails(portfolioId: string | number): Promise<Portfolio> {
        const response = await fetch(`${API_BASE}/portfolios/${portfolioId}`);
        if (!response.ok) {
            throw new APIError('Failed to fetch portfolio details', response.status);
        }
        return response.json();
    },
}; 