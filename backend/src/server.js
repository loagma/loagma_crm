import './config/env.js';
import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import { startExpiryJob, stopExpiryJob } from './jobs/approvalExpiryJob.js';
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import locationRoutes from './routes/locationRoutes.js';
import accountRoutes from './routes/accountRoutes.js';
import employeeRoutes from './routes/employeeRoutes.js';
import masterRoutes from './routes/masterRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import roleRoutes from './routes/roleRoutes.js';
import expenseRoutes from './routes/expenseRoutes.js';
import pincodeRoutes from './routes/pincodeRoutes.js';
import taskAssignmentRoutes from './routes/taskAssignmentRoutes.js';
import salesmanRoutes from './routes/salesmanRoutes.js';
import salaryRoutes from './routes/salaryRoutes.js';
import attendanceRoutes from './routes/attendanceRoutes.js';
import areaAssignmentRoutes from './routes/areaAssignmentRoutes.js';
import salesmanReportsRoutes from './routes/salesmanReportsRoutes.js';
import routeRoutes from './routes/routeRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import latePunchApprovalRoutes from './routes/latePunchApprovalRoutes.js';
import earlyPunchOutApprovalRoutes from './routes/earlyPunchOutApprovalRoutes.js';
import employeeWorkingHoursRoutes from './routes/employeeWorkingHoursRoutes.js';
import punchStatusRoutes from './routes/punchStatusRoutes.js';
import leaveRoutes from './routes/leaveRoutes.js';
import beatPlanRoutes from './routes/beatPlanRoutes.js';


const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();

// Middleware
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true,
}));

// Body parser with size limits for image uploads
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Health check routes
app.get('/', (req, res) => {
    res.json({
        success: true,
        message: 'Loagma CRM API',
        version: '1.0.0',
        timestamp: new Date().toISOString()
    });
});

app.get('/health', (req, res) => {
    res.json({
        success: true,
        message: 'Server is healthy',
        timestamp: new Date().toISOString()
    });
});

// API Routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/locations', locationRoutes);
app.use('/accounts', accountRoutes);
app.use('/employees', employeeRoutes);
app.use('/masters', masterRoutes);
app.use('/admin', adminRoutes);
app.use('/roles', roleRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/pincode', pincodeRoutes);
app.use('/task-assignments', taskAssignmentRoutes);
app.use('/salesman', salesmanRoutes);
app.use('/salary', salaryRoutes);
app.use('/attendance', attendanceRoutes);
app.use('/area-assignments', areaAssignmentRoutes);
app.use('/salesman-reports', salesmanReportsRoutes);
app.use('/api/routes', routeRoutes);
app.use('/notifications', notificationRoutes);
app.use('/late-punch-approval', latePunchApprovalRoutes);
app.use('/early-punch-out-approval', earlyPunchOutApprovalRoutes);
app.use('/employee-working-hours', employeeWorkingHoursRoutes);
app.use('/punch', punchStatusRoutes);
app.use('/leaves', leaveRoutes);
app.use('/beat-plans', beatPlanRoutes);

// 404 Handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: 'Endpoint not found',
        path: req.originalUrl,
        method: req.method
    });
});

// Global Error Handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        success: false,
        message: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

// Start server with WebSocket support
const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';
const WS_PORT = process.env.WS_PORT || 8081;

// Auto-migrate beat planning tables in production
if (process.env.NODE_ENV === 'production') {
    console.log('🔄 Running auto-migration for beat planning...');
    import('./utils/autoMigrateBeatPlanning.js').catch(error => {
        console.error('❌ Auto-migration failed:', error.message);
    });
}

const server = app.listen(PORT, HOST, () => {
    console.log(`✅ Server running on http://${HOST}:${PORT}`);
    console.log(`📝 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Initialize WebSocket server for live tracking
import LiveTrackingServer from './ws/liveTrackingServer.js';
const liveTrackingServer = new LiveTrackingServer();

// Always use the same HTTP server for WebSocket (both production and development)
liveTrackingServer.initialize(PORT, server);
console.log(`🔗 WebSocket server attached to HTTP server on port ${PORT}`);

// Start background jobs
startExpiryJob();

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('🛑 SIGTERM received, shutting down gracefully');
    stopExpiryJob();
    liveTrackingServer.shutdown();
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    console.log('🛑 SIGINT received, shutting down gracefully');
    stopExpiryJob();
    liveTrackingServer.shutdown();
    server.close(() => {
        console.log('✅ Server closed');
        process.exit(0);
    });
});
