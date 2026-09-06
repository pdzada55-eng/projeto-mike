import express from 'express';
import { getUserPerformance, getWrongQuestions } from '../controllers/performanceController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

router.get('/general', authenticate, getUserPerformance);
router.get('/wrong-questions', authenticate, getWrongQuestions);

export default router;
