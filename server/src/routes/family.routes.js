import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily, requireFamilyAdmin } from '../middleware/auth.js';
import * as family from '../controllers/family.controller.js';

const router = Router();

router.get('/me', requireAuth, requireFamily, h(family.getMyFamily));
router.patch('/me', requireAuth, requireFamily, requireFamilyAdmin, h(family.updateMyFamily));

export default router;
