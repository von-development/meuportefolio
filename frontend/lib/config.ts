export const API_CONFIG = {
    BASE_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api/v1',
    HEALTH_URL: process.env.NEXT_PUBLIC_API_URL ? 
        `${process.env.NEXT_PUBLIC_API_URL.split('/api/v1')[0]}/health` : 
        'http://localhost:8080/health'
}; 