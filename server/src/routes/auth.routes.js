import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth } from '../middleware/auth.js';
import * as auth from '../controllers/auth.controller.js';

const router = Router();

router.post('/register-family', h(auth.registerFamily));
router.post('/join-family', h(auth.joinFamily));
router.post('/login', h(auth.login));
router.post('/demo-login', h(auth.demoLogin));
router.get('/me', requireAuth, h(auth.me));

export default router;
