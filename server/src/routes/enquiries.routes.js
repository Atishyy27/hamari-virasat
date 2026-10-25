import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireSuperAdmin } from '../middleware/auth.js';
import * as enquiries from '../controllers/enquiries.controller.js';

const router = Router();

router.post('/', h(enquiries.createEnquiry));
router.get('/', requireAuth, requireSuperAdmin, h(enquiries.listEnquiries));

export default router;
