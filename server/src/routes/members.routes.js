import { Router } from 'express';
import { asyncHandler as h } from '../utils/asyncHandler.js';
import { requireAuth, requireFamily, requireFamilyAdmin } from '../middleware/auth.js';
import * as members from '../controllers/members.controller.js';

const router = Router();
const admin = [requireAuth, requireFamily, requireFamilyAdmin];

// Flat list of people in the family (no tree stored)
router.get('/', requireAuth, requireFamily, h(members.listMembers));
router.post('/', ...admin, h(members.addMember));
router.put('/:id', ...admin, h(members.updateMember));
router.delete('/:id', ...admin, h(members.deleteMember));

export default router;
