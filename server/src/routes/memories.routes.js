import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily } from '../middleware/auth.js';
import * as memories from '../controllers/memories.controller.js';

const router = Router();

router.get('/', requireAuth, requireFamily, h(memories.listMemories));
router.post('/', requireAuth, requireFamily, h(memories.addMemory));
router.delete('/:id', requireAuth, requireFamily, h(memories.deleteMemory));

export default router;
