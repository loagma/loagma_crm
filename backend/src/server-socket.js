import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import dotenv from 'dotenv';
import { initializeSocketServer, getActiveConnectionsCount } from './socket/socketServer.js';

// Import existing routes
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import attendanceRoutes from './routes/attendanceRoutes.js';
import trackingRoutes from './routes/trackingRoutes.js';
// ... import other routes

dotenv.config();

const app = express();
const httpServer = createServer(app);

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Initialize Socket.IO
const io = initializeSocketServer(httpServer);

// Health check endpoint
app.get('/health', (req, res) => {
    const connections = getActiveConnectionsCount();
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        connections,
    });
});

// Socket.IO status endpoint
app.get('/socket/status', (req, res) => {
    const connections = getActiveConnectionsCount();
    res.json({
        socketIO: 'active',
        connections,
    });
});

// API Routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/tracking', trackingRoutes);
// ... other routes

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal server error',
    });
});

// Start server
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`🔌 Socket.IO ready for connections`);
    console.log(`📊 Health check: http://localhost:${PORT}/health`);
});

export { app, httpServer, io };
