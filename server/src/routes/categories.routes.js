import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily } from '../middleware/auth.js';
import * as categories from '../controllers/categories.controller.js';

const router = Router();

router.get('/', requireAuth, requireFamily, h(categories.listCategories));
router.post('/', requireAuth, requireFamily, h(categories.addCategory));

export default router;
