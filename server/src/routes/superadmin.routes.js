import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireSuperAdmin } from '../middleware/auth.js';
import * as superadmin from '../controllers/superadmin.controller.js';

const router = Router();

router.use(requireAuth, requireSuperAdmin);

router.get('/families', h(superadmin.listFamilies));
router.put('/families/:id/status', h(superadmin.setFamilyStatus));
router.get('/test-rls-rituals-leak', h(superadmin.testRitualsLeak));

export default router;
