import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js'
import userRoutes from './routes/userRoutes.js'

dotenv.config();
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Default route
app.get('/', (req, res) => {
  res.send('Loagma CRM Backend running well!!');
});

// Routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
// app.use('/accounts', accountRoutes);

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => console.log(`Server running on port http://localhost:${PORT}`));

export default app;
