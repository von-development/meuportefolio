import { config } from './config'

export interface User {
  user_id: string
  name: string
  email: string
  user_type: string
  country_of_residence: string
  iban: string
  created_at: string
  updated_at: string
}

export interface LoginResponse {
  token: string
  user: User
}

export interface RegisterData {
  name: string
  email: string
  password: string
  user_type?: string
}

// Use config for API base URL
const API_BASE_URL = config.api.baseURL

// Login user
export async function loginUser(email: string, password: string): Promise<LoginResponse> {
  const response = await fetch(`${API_BASE_URL}/users/login`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ email, password }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(error || 'Login failed')
  }

  return response.json()
}

// Register user
export async function registerUser(userData: RegisterData): Promise<LoginResponse> {
  const response = await fetch(`${API_BASE_URL}/users`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(userData),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(error || 'Registration failed')
  }

  return response.json()
}

// Logout user
export async function logoutUser(): Promise<void> {
  const response = await fetch(`${API_BASE_URL}/users/logout`, {
    method: 'POST',
    credentials: 'include', // Important for cookies
  })

  if (!response.ok) {
    throw new Error('Logout failed')
  }
}

// Token and user management (using localStorage)
export function storeTokenAndUser(token: string, user: User): void {
  if (typeof window !== 'undefined') {
    localStorage.setItem('meuportefolio_token', token)
    localStorage.setItem('meuportefolio_user', JSON.stringify(user))
  }
}

export function getTokenFromStorage(): string | null {
  if (typeof window !== 'undefined') {
    return localStorage.getItem('meuportefolio_token')
  }
  return null
}

export function getUserFromStorage(): User | null {
  if (typeof window !== 'undefined') {
    const userString = localStorage.getItem('meuportefolio_user')
    return userString ? JSON.parse(userString) : null
  }
  return null
}

export function clearAuth(): void {
  if (typeof window !== 'undefined') {
    localStorage.removeItem('meuportefolio_token')
    localStorage.removeItem('meuportefolio_user')
  }
}

export function isAuthenticated(): boolean {
  return getTokenFromStorage() !== null && getUserFromStorage() !== null
}