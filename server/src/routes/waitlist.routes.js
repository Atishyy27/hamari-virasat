import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth } from '../middleware/auth.js';
import * as waitlist from '../controllers/waitlist.controller.js';

const router = Router();

router.post('/', requireAuth, h(waitlist.joinWaitlist));
router.get('/', requireAuth, h(waitlist.listWaitlist));

export default router;
