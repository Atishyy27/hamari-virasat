import { Router } from 'express';
import authRoutes from './auth.routes.js';
import familyRoutes from './family.routes.js';
import membersRoutes from './members.routes.js';
import ritualsRoutes from './rituals.routes.js';
import categoriesRoutes from './categories.routes.js';
import ordersRoutes from './orders.routes.js';
import waitlistRoutes from './waitlist.routes.js';
import enquiriesRoutes from './enquiries.routes.js';
import memoriesRoutes from './memories.routes.js';
import superadminRoutes from './superadmin.routes.js';

const router = Router();

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Hamari Virasat API Backend',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

router.use('/auth', authRoutes);
router.use('/family', familyRoutes);
router.use('/members', membersRoutes);
router.use('/rituals', ritualsRoutes);
router.use('/categories', categoriesRoutes);
router.use('/orders', ordersRoutes);
router.use('/waitlist', waitlistRoutes);
router.use('/enquiries', enquiriesRoutes);
router.use('/memories', memoriesRoutes);
router.use('/super-admin', superadminRoutes);

export default router;
