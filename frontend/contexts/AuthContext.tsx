'use client'

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { User, loginUser, logoutUser, createUser, getCurrentUser, setTokenInStorage, removeTokenFromStorage, setUserInStorage, removeUserFromStorage, LoginRequest, CreateUserRequest } from '@/lib/auth'

interface AuthContextType {
  user: User | null
  loading: boolean
  login: (credentials: LoginRequest) => Promise<void>
  signup: (userData: CreateUserRequest) => Promise<void>
  logout: () => Promise<void>
  isAuthenticated: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [loading, setLoading] = useState(true)

  // Check if user is already logged in on app load
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const currentUser = await getCurrentUser()
        setUser(currentUser)
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
      const response = await loginUser(credentials)
      
      // Store token and user data
      setTokenInStorage(response.token)
      setUserInStorage(response.user)
      setUser(response.user)
    } catch (error) {
      console.error('Login failed:', error)
      throw error
    } finally {
      setLoading(false)
    }
  }

  const signup = async (userData: CreateUserRequest) => {
    try {
      setLoading(true)
      const newUser = await createUser(userData)
      
      // After successful signup, automatically log them in
      await login({ email: userData.email, password: userData.password })
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
      removeTokenFromStorage()
      removeUserFromStorage()
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