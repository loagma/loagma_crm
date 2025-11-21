import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
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

dotenv.config();
const app = express();

// Middleware
app.use(cors({
  origin: '*', // Allow all origins for now
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  credentials: true,
}));

// Increase body size limit to handle image uploads (50MB)
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Health check route
app.get('/', (req, res) => {
  res.send('Loagma CRM Backend running well!!');
});

app.get('/health', (req, res) => {
  res.json({ 
    success: true, 
    message: 'Server is healthy',
    timestamp: new Date().toISOString()
  });
});

// Routes
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

// 404 Handler - Must be after all routes
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Page Not Found',
    error: `Cannot ${req.method} ${req.originalUrl}`,
    availableRoutes: [
      '/auth',
      '/users',
      '/locations',
      '/accounts',
      '/employees',
      '/masters',
      '/admin',
      '/roles',
      '/api/expenses'
    ]
  });
});

// Error Handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`✅ Server running and accessible on http://0.0.0.0:${PORT}`);
});


export default app;
