import express from 'express';
import { getStates, getSubjects, getTopicsBySubject, getStatistics } from '../controllers/dataController.js';

const router = express.Router();

router.get('/states', getStates);
router.get('/subjects', getSubjects);
router.get('/subjects/:subjectId/topics', getTopicsBySubject);
router.get('/statistics', getStatistics);

export default router;
