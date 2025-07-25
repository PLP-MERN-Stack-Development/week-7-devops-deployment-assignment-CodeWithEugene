#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "---------------------------------------------------------"
echo "🚀 MERN Stack Project Structure Creator"
echo "---------------------------------------------------------"

read -p "Enter the name for your MERN project (e.g., my-mern-app): " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Project name cannot be empty. Exiting."
    exit 1
fi

if [ -d "$PROJECT_NAME" ]; then
    read -p "Directory '$PROJECT_NAME' already exists. Overwrite? (y/N): " OVERWRITE
    if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
        echo "Exiting without creating files."
        exit 0
    else
        echo "Removing existing directory '$PROJECT_NAME'..."
        rm -rf "$PROJECT_NAME"
    fi
fi

echo "Creating project directory: $PROJECT_NAME"
mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "Creating client (React) directory and files..."
mkdir -p client/public client/src/components client/src/pages

cat << EOF > client/.env.development
REACT_APP_API_URL=http://localhost:5000/api
EOF

cat << EOF > client/.env.production
REACT_APP_API_URL=https://your-backend-app.onrender.com/api # Placeholder: Update with your Render URL
EOF

cat << EOF > client/package.json
{
  "name": "client",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "@sentry/react": "^7.x.x",
    "@sentry/tracing": "^7.x.x",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.x.x",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false",
    "eject": "react-scripts eject",
    "lint": "eslint src/"
  },
  "eslintConfig": {
    "extends": [
      "react-app",
      "react-app/jest"
    ]
  },
  "browserslist": {
    "production": [
      ">0.2%",
      "not dead",
      "not op_mini all"
    ],
    "development": [
      "last 1 chrome version",
      "last 1 firefox version",
      "last 1 safari version"
    ]
  }
}
EOF

cat << EOF > client/src/App.js
import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';

// Lazy load components/pages
const HomePage = lazy(() => import('./pages/HomePage'));
const AboutPage = lazy(() => import('./pages/AboutPage'));
const Dashboard = lazy(() => import('./pages/Dashboard')); // Example

function App() {
  return (
    <Router>
      <Suspense fallback={<div>Loading...</div>}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/about" element={<AboutPage />} />
          <Route path="/dashboard" element={<Dashboard />} />
          {/* Add more routes here */}
        </Routes>
      </Suspense>
    </Router>
  );
}

export default App;
EOF

cat << EOF > client/src/index.js
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import * as Sentry from '@sentry/react';
import { BrowserTracing } from '@sentry/tracing';

// Initialize Sentry only in production
if (process.env.NODE_ENV === 'production') {
  Sentry.init({
    dsn: "YOUR_SENTRY_FRONTEND_DSN", // Replace with your Sentry Frontend DSN
    integrations: [new BrowserTracing()],
    tracesSampleRate: 1.0, // Adjust as needed
    environment: process.env.NODE_ENV,
  });
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    {/* Wrap App with Sentry.ErrorBoundary for better error catching in production */}
    {process.env.NODE_ENV === 'production' ? (
      <Sentry.ErrorBoundary fallback={<p>An error has occurred in the frontend.</p>}>
        <App />
      </Sentry.ErrorBoundary>
    ) : (
      <App />
    )}
  </React.StrictMode>
);
EOF

touch client/src/pages/HomePage.js
cat << EOF > client/src/pages/HomePage.js
import React from 'react';

const HomePage = () => {
  return (
    <div>
      <h1>Welcome to the Home Page!</h1>
      <p>This is your MERN Stack application.</p>
    </div>
  );
};

export default HomePage;
EOF

echo "Creating server (Express) directory and files..."
mkdir -p server/config server/controllers server/models server/routes server/middleware

cat << EOF > server/.env
PORT=5000
NODE_ENV=development # Will be 'production' on Render
MONGO_URI=mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/your-app-db?retryWrites=true&w=majority # Placeholder: Replace with your MongoDB Atlas URI
JWT_SECRET=SUPER_SECRET_CHANGE_THIS_IN_PRODUCTION # Placeholder: Generate a strong, random key
EOF

cat << EOF > server/package.json
{
  "name": "server",
  "version": "1.0.0",
  "description": "MERN Stack Backend",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "echo \"Error: no test specified\" && exit 1",
    "lint": "eslint ."
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "@sentry/node": "^7.x.x",
    "@sentry/tracing": "^7.x.x",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.18.3",
    "helmet": "^7.1.0",
    "mongoose": "^8.2.1",
    "morgan": "^1.10.0",
    "winston": "^3.13.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.0",
    "eslint": "^8.57.0"
  }
}
EOF

cat << EOF > server/server.js
require('dotenv').config(); // Load .env file at the very top

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const winston = require('winston');
const connectDB = require('./config/db');
const { errorHandler } = require('./middleware/errorMiddleware');
const path = require('path');
const Sentry = require('@sentry/node');
const Tracing = require('@sentry/tracing');

const app = express();

// Initialize Sentry before other middleware (production only)
if (process.env.NODE_ENV === 'production') {
    Sentry.init({
        dsn: "YOUR_SENTRY_BACKEND_DSN", // Replace with your Sentry Backend DSN
        integrations: [
            new Sentry.Integrations.Http({ tracing: true }),
            new Tracing.Integrations.Express({ app: app }),
            // Add other integrations as needed, e.g., for MongoDB
            new Tracing.Integrations.Mongo({ use ).
        ],
        tracesSampleRate: 1.0, // Adjust as needed for performance monitoring
        environment: process.env.NODE_ENV,
    });
    // The request handler must be the first middleware on the app
    app.use(Sentry.Handlers.requestHandler());
    // TracingHandler creates a trace for every incoming request
    app.use(Sentry.Handlers.tracingHandler());
}


// Connect Database
connectDB();

// Middleware
app.use(express.json()); // Body parser for JSON
app.use(express.urlencoded({ extended: false })); // Body parser for URL-encoded data

// Security Middleware
app.use(helmet()); // Set various HTTP headers for security
app.use(cors()); // Enable CORS for all origins (adjust in production for specific frontend origin)

// Logging Middleware
const logger = winston.createLogger({
    level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
    format: winston.format.json(),
    defaultMeta: { service: 'mern-app-backend' },
    transports: [
        new winston.transports.File({ filename: 'error.log', level: 'error' }),
        new winston.transports.File({ filename: 'combined.log' }),
    ],
});

if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: winston.format.simple(),
    }));
    app.use(morgan('dev')); // Concise logging for development
} else {
    app.use(morgan('combined')); // Detailed logging for production
}

// Health Check Endpoint (for monitoring)
app.get('/api/health', (req, res) => {
    res.status(200).json({ status: 'OK', message: 'Backend is healthy' });
});

// Routes (example)
app.use('/api/users', (req, res) => res.send('User API endpoint')); // Replace with your actual routes
app.use('/api/items', (req, res) => res.send('Item API endpoint')); // Replace with your actual routes

// Serve frontend in production
if (process.env.NODE_ENV === 'production') {
    // Set static folder
    app.use(express.static(path.join(__dirname, '../client/build')));

    app.get('*', (req, res) => {
        res.sendFile(path.resolve(__dirname, '../client', 'build', 'index.html'));
    });
} else {
    app.get('/', (req, res) => {
        res.send('Backend is running. Please set NODE_ENV to production for frontend serving.');
    });
}

// Sentry error handler (must be before your custom error handler)
if (process.env.NODE_ENV === 'production') {
    app.use(Sentry.Handlers.errorHandler());
}

// Custom Error Handling Middleware (MUST be last middleware)
app.use(errorHandler);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(\`Server running on port \${PORT} in \${process.env.NODE_ENV} mode\`));

// Example of using logger
logger.info('Server started successfully', { port: PORT, env: process.env.NODE_ENV });
// logger.error('Example error message', { stack: new Error('Test error').stack });
EOF

cat << EOF > server/config/db.js
const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const conn = await mongoose.connect(process.env.MONGO_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
            // connection pooling is handled by Mongoose itself by default with these options
            // and connection string specific parameters like maxPoolSize (e.g., ?maxPoolSize=10)
        });

        console.log(\`MongoDB Connected: \${conn.connection.host}\`);
    } catch (error) {
        console.error(\`Error connecting to MongoDB: \${error.message}\`);
        process.exit(1); // Exit process with failure
    }
};

module.exports = connectDB;
EOF

cat << EOF > server/middleware/errorMiddleware.js
const errorHandler = (err, req, res, next) => {
    const statusCode = res.statusCode && res.statusCode !== 200 ? res.statusCode : 500;

    res.status(statusCode);

    res.json({
        message: err.message,
        stack: process.env.NODE_ENV === 'production' ? null : err.stack, // Don't expose stack in production
    });
};

module.exports = { errorHandler };
EOF

echo "Creating root level files..."
cat << EOF > .gitignore
# Git Ignore for MERN App
node_modules/
.env
client/.env.development
client/.env.production
server/.env
dist/
build/
.DS_Store
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.vercel/
.sentryclirc
# Logs
*.log
logs/
EOF

cat << EOF > README.md
# $PROJECT_NAME

This is a MERN (MongoDB, Express, React, Node.js) stack application.

## Project Structure

- \`client/\`: React frontend application.
- \`server/\`: Express.js backend application.
- \`.github/workflows/\`: GitHub Actions CI/CD pipeline configurations.

## Setup & Installation

### Prerequisites

- Node.js (v18 or higher recommended)
- npm (v8 or higher recommended)
- Git

### Initial Setup (after cloning)

1.  **Install Root Dependencies (if any, though often none for MERN):**
    \`\`\`bash
    npm install
    \`\`\`
2.  **Install Backend Dependencies:**
    \`\`\`bash
    cd server
    npm install
    \`\`\`
    - Create a \`.env\` file in \`server/\` and add:
      \`\`\`env
      PORT=5000
      NODE_ENV=development
      MONGO_URI=mongodb+srv://<username>:<password>@cluster0.abcde.mongodb.net/your-app-db?retryWrites=true&w=majority
      JWT_SECRET=YOUR_VERY_STRONG_RANDOM_SECRET
      \`\`\`
      (Replace with your MongoDB Atlas URI and a strong secret key)
    - To start the backend in development:
      \`\`\`bash
      npm run dev
      \`\`\`

3.  **Install Frontend Dependencies:**
    \`\`\`bash
    cd ../client
    npm install
    \`\`\`
    - Create \`.env.development\` in \`client/\` and add:
      \`\`\`env
      REACT_APP_API_URL=http://localhost:5000/api
      \`\`\`
    - To start the frontend in development:
      \`\`\`bash
      npm start
      \`\`\`

## Deployment

Refer to the CI/CD and deployment instructions in the project documentation for production setup.

## Monitoring

- **Uptime Monitoring:** Configured via UptimeRobot (or similar) pointing to \`/api/health\` on backend.
- **Error Tracking & Performance:** Integrated with Sentry for both frontend and backend.

EOF

cat << EOF > package.json
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "A full MERN stack application for learning deployment.",
  "main": "index.js",
  "scripts": {
    "test": "echo \"Error: no test specified in root\" && exit 1"
  },
  "keywords": [],
  "author": "",
  "license": "ISC"
}
EOF

echo "Creating GitHub Actions workflow directory and files..."
mkdir -p .github/workflows

cat << EOF > .github/workflows/ci.yml
# .github/workflows/ci.yml
name: MERN CI Pipeline

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18' # Use your Node.js version

      # --- Backend CI ---
      - name: Install Backend Dependencies
        run: npm install
        working-directory: ./server

      - name: Run Backend Tests (if any)
        # Add your backend test command here, e.g., 'npm test'
        run: echo "No backend tests configured for this example. Add 'npm test' if you have them."

      - name: Run Backend Linting (if any)
        # Add your backend lint command here, e.g., 'npm run lint'
        run: echo "No backend linting configured for this example. Add 'npm run lint' if you have it."

      # --- Frontend CI ---
      - name: Install Frontend Dependencies
        run: npm install
        working-directory: ./client

      - name: Run Frontend Tests (if any)
        # Add your frontend test command here, e.g., 'npm test'
        run: echo "No frontend tests configured for this example. Add 'npm test' if you have them."

      - name: Run Frontend Linting (if any)
        # Add your frontend lint command here, e.g., 'npm run lint'
        run: echo "No frontend linting configured for this example. Add 'npm run lint' if you have it."

      - name: Build Frontend for Production
        run: npm run build
        working-directory: ./client

      - name: Upload Frontend Build Artifact (Optional)
        uses: actions/upload-artifact@v3
        with:
          name: react-build
          path: client/build
EOF

echo "---------------------------------------------------------"
echo "✅ Project '$PROJECT_NAME' structure created successfully!"
echo "---------------------------------------------------------"
echo "Next Steps:"
echo "1. Change into your new project directory: cd $PROJECT_NAME"
echo "2. Initialize Git: git init"
echo "3. Install dependencies:"
echo "   cd server && npm install"
echo "   cd ../client && npm install"
echo "   # (Optional) npm install in the root if you add root-level packages"
echo "4. Update placeholder values in .env files (MongoDB URI, JWT Secret, Sentry DSNs)."
echo "5. Start building your MERN application!"
echo "   # To run backend: cd server && npm run dev"
echo "   # To run frontend: cd client && npm start"
echo "---------------------------------------------------------"