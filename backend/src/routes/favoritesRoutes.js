import express from 'express';
import { addFavorite, removeFavorite, getFavorites, isFavorite } from '../controllers/favoritesController.js';
import { authenticate } from '../middleware/auth.js';

const router = express.Router();

router.post('/add', authenticate, addFavorite);
router.post('/remove', authenticate, removeFavorite);
router.get('/', authenticate, getFavorites);
router.get('/:questionId/check', authenticate, isFavorite);

export default router;
