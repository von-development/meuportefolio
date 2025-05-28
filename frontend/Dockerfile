# Use the latest LTS version of Node.js
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Copy the rest of your application files
COPY . .

# Expose the port your app runs on
EXPOSE 3000

# Environment variables
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=development
ENV NEXT_PUBLIC_API_URL=http://api:8080/api/v1

# Define the command to run your app in development mode
CMD ["npm", "run", "dev"] 