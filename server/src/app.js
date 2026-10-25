import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config.js';
import apiRoutes from './routes/index.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';

const app = express();

// Middleware
app.use(cors({ origin: config.corsOrigin }));
app.use(express.json());
if (config.nodeEnv !== 'test') app.use(morgan('dev'));

// API routes (includes /api/health)
app.use('/api', apiRoutes);

// Root informational endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Hamari Virasat API Server',
    description: 'Backend platform for private family rituals, recipes, and heritage management.',
    docs: {
      health: '/api/health',
      auth: '/api/auth',
      family: '/api/family/me',
      members: '/api/members',
      rituals: '/api/rituals',
      categories: '/api/categories',
      orders: '/api/orders',
      superAdmin: '/api/super-admin/families'
    }
  });
});

app.use(notFoundHandler);
app.use(errorHandler);

export default app;
