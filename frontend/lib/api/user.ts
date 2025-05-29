import { fetchApi } from './base';

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

export interface LoginRequest {
    email: string;
    password: string;
}

export interface SignupRequest {
    name: string;
    email: string;
    password: string;
    country_of_residence: string;
    iban: string;
}

export const userApi = {
    getUsers: () => fetchApi<User[]>('/users'),
    
    getUser: (id: string) => fetchApi<User>(`/users/${id}`),
    
    createUser: (data: SignupRequest) => 
        fetchApi<User>('/users', {
            method: 'POST',
            body: JSON.stringify(data),
        }),
    
    updateUser: (id: string, data: Partial<User>) => 
        fetchApi<User>(`/users/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        }),
    
    deleteUser: (id: string) => 
        fetchApi<void>(`/users/${id}`, {
            method: 'DELETE',
        }),
    
    login: (credentials: LoginRequest) => 
        fetchApi<{ token: string; user: User }>('/users/login', {
            method: 'POST',
            body: JSON.stringify(credentials),
        }),
    
    logout: () => 
        fetchApi<void>('/users/logout', {
            method: 'POST',
        }),
}; 