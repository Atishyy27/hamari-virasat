import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily } from '../middleware/auth.js';
import * as orders from '../controllers/orders.controller.js';

const router = Router();

router.get('/', requireAuth, requireFamily, h(orders.listOrders));
router.post('/', requireAuth, requireFamily, h(orders.createOrder));

export default router;
