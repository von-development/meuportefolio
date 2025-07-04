'use client'

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { User, loginUser, logoutUser, registerUser, getUserFromStorage, getTokenFromStorage, storeTokenAndUser, clearAuth, RegisterData } from '@/lib/auth'

interface LoginRequest {
  email: string
  password: string
}

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (credentials: LoginRequest) => Promise<void>
  signup: (userData: RegisterData) => Promise<void>
  logout: () => Promise<void>
  isAuthenticated: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check if user is already logged in on app load
  useEffect(() => {
    const checkAuth = () => {
      try {
        const currentUser = getUserFromStorage()
        const token = getTokenFromStorage()
        
        if (currentUser && token) {
          setUser(currentUser)
        } else {
          setUser(null)
        }
      } catch (error) {
        console.error('Auth check failed:', error)
        setUser(null)
      } finally {
        setLoading(false)
      }
    }

    checkAuth()
  }, [])

  const login = async (credentials: LoginRequest) => {
    try {
      setLoading(true)
      const response = await loginUser(credentials.email, credentials.password)
      
      // Store token and user data
      storeTokenAndUser(response.token, response.user)
      setUser(response.user)
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      setLoading(false)
    }
  }

  const signup = async (userData: RegisterData) => {
    try {
      setLoading(true)
      const response = await registerUser(userData)
      
      // After successful signup, store the returned token and user
      storeTokenAndUser(response.token, response.user)
      setUser(response.user)
    } catch (error) {
      console.error('Signup failed:', error)
      throw error
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      await logoutUser()
    } catch (error) {
      console.error('Logout failed:', error)
    } finally {
      // Always clear local state, even if API call fails
      clearAuth()
      setUser(null)
    }
  }

  const value: AuthContextType = {
    user,
    loading,
    login,
    signup,
    logout,
    isAuthenticated: user !== null,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
} 