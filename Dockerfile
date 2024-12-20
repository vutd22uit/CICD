# Stage 1: Build the React App
FROM node:16 AS build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the application code
COPY . .

# Pass the API Key as a build argument
ARG REACT_APP_RAPID_API_KEY
# Set the API Key as an environment variable
ENV REACT_APP_RAPID_API_KEY=${REACT_APP_RAPID_API_KEY}

# Build the React app for production
RUN npm run build

# Stage 2: Serve the React App with Nginx
FROM nginx:alpine

# Copy the built React app to the Nginx web root
COPY --from=build /app/build /usr/share/nginx/html

# Expose port 80 to the outside world
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
