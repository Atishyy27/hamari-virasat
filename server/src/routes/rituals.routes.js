import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily } from '../middleware/auth.js';
import * as rituals from '../controllers/rituals.controller.js';

const router = Router();

router.use(requireAuth, requireFamily);

router.get('/', h(rituals.listRituals));
router.get('/:id', h(rituals.getRitual));
router.post('/', h(rituals.createRitual));
router.put('/:id', h(rituals.updateRitual));
router.patch('/:id/status', h(rituals.updateRitualStatus));
router.delete('/:id', h(rituals.deleteRitual));

export default router;
