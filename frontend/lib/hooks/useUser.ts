import { useState, useCallback } from 'react';
import { userApi, type User, type LoginRequest, type SignupRequest } from '../api/user';

export function useUser() {
    const [user, setUser] = useState<User | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<Error | null>(null);

    const login = useCallback(async (credentials: LoginRequest) => {
        setLoading(true);
        setError(null);
        try {
            const response = await userApi.login(credentials);
            setUser(response.user);
            // You might want to store the token in localStorage or a state management solution
            return response;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Login failed'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const signup = useCallback(async (data: SignupRequest) => {
        setLoading(true);
        setError(null);
        try {
            const newUser = await userApi.createUser(data);
            setUser(newUser);
            return newUser;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Signup failed'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const logout = useCallback(async () => {
        setLoading(true);
        setError(null);
        try {
            await userApi.logout();
            setUser(null);
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Logout failed'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    const updateUserProfile = useCallback(async (userId: string, data: Partial<User>) => {
        setLoading(true);
        setError(null);
        try {
            const updatedUser = await userApi.updateUser(userId, data);
            setUser(updatedUser);
            return updatedUser;
        } catch (err) {
            setError(err instanceof Error ? err : new Error('Update failed'));
            throw err;
        } finally {
            setLoading(false);
        }
    }, []);

    return {
        user,
        loading,
        error,
        login,
        signup,
        logout,
        updateUserProfile,
    };
} 