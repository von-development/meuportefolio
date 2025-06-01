import { config } from './config'

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

export interface CompleteUser extends User {
  account_balance: number
  auto_renew_subscription: boolean
  days_remaining_in_subscription: number
  is_premium: boolean
  last_subscription_payment: string
  monthly_subscription_rate: number
  next_subscription_payment: string
  payment_method_active: boolean
  payment_method_details: string
  payment_method_expiry: string
  payment_method_type: string
  premium_end_date: string
  premium_start_date: string
  subscription_expired: boolean
}

export interface AccountSummary {
  account_balance: number
  name: string
  portfolio_count: number
  total_net_worth: number
  total_portfolio_value: number
  user_id: string
  user_type: string
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

export interface UpdateUserRequest {
  name?: string
  email?: string
  password?: string
  country_of_residence?: string
  iban?: string
  user_type?: string
}

export interface PaymentMethodRequest {
  payment_method_type: string
  payment_method_details: string
  payment_method_expiry: string
}

export interface SubscriptionRequest {
  action: 'ACTIVATE' | 'RENEW' | 'CANCEL'
  monthly_rate?: number
  months_to_add?: number
}

export interface UpgradePremiumRequest {
  monthly_rate: number
  subscription_months: number
}

export interface DepositRequest {
  amount: number
  description: string
}

export interface WithdrawRequest {
  amount: number
  description: string
}

export interface AllocateRequest {
  amount: number
  portfolio_id: number
}

export interface DeallocateRequest {
  amount: number
  portfolio_id: number
}

export interface FinancialResponse {
  amount: number
  new_balance: number
  new_portfolio_funds?: number
  status: string
}

export interface SubscriptionResponse {
  amount_paid?: number
  message: string
  months_added?: number
  new_balance?: number
  status: string
}

export interface PaymentMethodResponse {
  message: string
  status: string
}

export interface ApiResponse<T> {
  data?: T
  success: boolean
  message?: string
  errors?: string[]
}

class ApiService {
  private baseURL: string

  constructor() {
    this.baseURL = config.api.baseURL
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const url = `${this.baseURL}${endpoint}`
      const configOptions: RequestInit = {
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
        ...options,
      }

      const response = await fetch(url, configOptions)
      
      // Handle different response types
      let data: any
      const contentType = response.headers.get('content-type')
      
      if (contentType && contentType.includes('application/json')) {
        data = await response.json()
      } else {
        data = await response.text()
      }

      if (!response.ok) {
        return {
          success: false,
          message: typeof data === 'string' ? data : (data.message || 'Erro na requisição'),
          errors: typeof data === 'object' ? data.errors || [] : [],
        }
      }

      return {
        success: true,
        data,
      }
    } catch (error) {
      console.error('Erro na API:', error)
      return {
        success: false,
        message: 'Erro de conexão com o servidor',
      }
    }
  }
}

export const apiService = new ApiService() 