import express from 'express';
import { getQuestions, getQuestionById, submitAnswer } from '../controllers/questionsController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

router.get('/', getQuestions);
router.get('/:id', getQuestionById);
router.post('/submit-answer', authenticate, submitAnswer);

export default router;
