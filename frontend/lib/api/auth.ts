import { fetchApi } from './base';

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  message: string;
  user_id?: string;
  name?: string;
  email?: string;
  user_type?: string;
}

export interface RegisterRequest {
  name: string;
  email: string;
  password: string;
  country_of_residence: string;
  iban: string;
  user_type: 'basic' | 'premium';
}

export interface User {
  user_id: string;
  name: string;
  email: string;
  country_of_residence: string;
  iban: string;
  user_type: string;
  created_at: string;
  updated_at: string;
}

export const authApi = {
  // User login
  login: (credentials: LoginRequest) => 
    fetchApi<LoginResponse>('/users/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
      credentials: 'include', // Include cookies for session management
    }),

  // User registration
  register: (userData: RegisterRequest) => 
    fetchApi<User>('/users', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(userData),
      credentials: 'include',
    }),

  // User logout
  logout: () => 
    fetchApi<void>('/users/logout', {
      method: 'POST',
      credentials: 'include',
    }),
}; 