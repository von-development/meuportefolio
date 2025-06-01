// Authentication types and API functions
export interface User {
  user_id: string
  name: string
  email: string
  country_of_residence: string
  iban: string
  user_type: string
  created_at: string
  updated_at: string
}

export interface LoginRequest {
  email: string
  password: string
}

export interface LoginResponse {
  token: string
  user: User
}

export interface CreateUserRequest {
  name: string
  email: string
  password: string
  country_of_residence: string
  iban: string
  user_type: string
}

const API_BASE_URL = 'http://localhost:8080/api/v1'

// Login user
export async function loginUser(credentials: LoginRequest): Promise<LoginResponse> {
  console.log('🔐 Attempting login with:', { email: credentials.email, password: credentials.password ? '[HIDDEN]' : 'NO_PASSWORD' })
  console.log('🌐 API URL:', `${API_BASE_URL}/users/login`)
  
  try {
    const response = await fetch(`${API_BASE_URL}/users/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(credentials),
    })

    console.log('📡 Response status:', response.status, response.statusText)
    console.log('📡 Response headers:', Object.fromEntries(response.headers.entries()))

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ Login failed with error:', errorText)
      throw new Error(errorText || 'Login failed')
    }

    const data = await response.json()
    console.log('✅ Login successful:', { token: data.token ? '[TOKEN_RECEIVED]' : 'NO_TOKEN', user: data.user?.name })
    
    return data
  } catch (error) {
    console.error('💥 Login error:', error)
    throw error
  }
}

// Create new user account
export async function createUser(userData: CreateUserRequest): Promise<User> {
  console.log('📝 Attempting user creation with:', { ...userData, password: '[HIDDEN]' })
  
  try {
    const response = await fetch(`${API_BASE_URL}/users`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(userData),
    })

    console.log('📡 Create user response status:', response.status, response.statusText)

    if (!response.ok) {
      const errorText = await response.text()
      console.error('❌ User creation failed with error:', errorText)
      throw new Error(errorText || 'Account creation failed')
    }

    const user = await response.json()
    console.log('✅ User created successfully:', user.name)
    return user
  } catch (error) {
    console.error('💥 User creation error:', error)
    throw error
  }
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

// Get current user from localStorage (simplified approach)
export async function getCurrentUser(): Promise<User | null> {
  try {
    const userStr = getUserFromStorage()
    if (!userStr) return null
    
    const user = JSON.parse(userStr)
    return user
  } catch {
    removeUserFromStorage()
    return null
  }
}

// User management utilities
export function getUserFromStorage(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem('auth_user')
}

export function setUserInStorage(user: User): void {
  if (typeof window === 'undefined') return
  localStorage.setItem('auth_user', JSON.stringify(user))
}

export function removeUserFromStorage(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem('auth_user')
}

// Token management utilities
export function getTokenFromStorage(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem('auth_token')
}

export function setTokenInStorage(token: string): void {
  if (typeof window === 'undefined') return
  localStorage.setItem('auth_token', token)
}

export function removeTokenFromStorage(): void {
  if (typeof window === 'undefined') return
  localStorage.removeItem('auth_token')
}

// Check if user is authenticated
export function isAuthenticated(): boolean {
  return getTokenFromStorage() !== null && getUserFromStorage() !== null
} 