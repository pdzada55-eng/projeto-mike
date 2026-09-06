import pool from '../config/database.js';

export const getQuestions = async (req, res) => {
  try {
    const { stateId, subjectId, topicId, difficulty, search, page = 1, limit = 20 } = req.query;

    let query = 'SELECT q.id, q.uuid, q.state_id, q.subject_id, q.topic_id, q.enunciation, q.difficulty_level, q.exam_year, q.banca, q.source FROM questions q WHERE q.status = \'ativo\'';
    const params = [];
    let paramCount = 1;

    if (stateId) {
      query += ` AND q.state_id = $${paramCount}`;
      params.push(stateId);
      paramCount++;
    }

    if (subjectId) {
      query += ` AND q.subject_id = $${paramCount}`;
      params.push(subjectId);
      paramCount++;
    }

    if (topicId) {
      query += ` AND q.topic_id = $${paramCount}`;
      params.push(topicId);
      paramCount++;
    }

    if (difficulty) {
      query += ` AND q.difficulty_level = $${paramCount}`;
      params.push(difficulty);
      paramCount++;
    }

    if (search) {
      query += ` AND q.enunciation ILIKE $${paramCount}`;
      params.push(`%${search}%`);
      paramCount++;
    }

    // Contar total
    const countResult = await pool.query(`SELECT COUNT(*) FROM (${query}) as total`, params);
    const total = parseInt(countResult.rows[0].count);

    // Paginar
    const offset = (page - 1) * limit;
    query += ` ORDER BY q.created_at DESC LIMIT $${paramCount} OFFSET $${paramCount + 1}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Erro ao buscar questões:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar questões' 
    });
  }
};

export const getQuestionById = async (req, res) => {
  try {
    const { id } = req.params;

    const questionResult = await pool.query(
      `SELECT q.id, q.uuid, q.state_id, q.subject_id, q.topic_id, q.enunciation, q.explanation, 
              q.difficulty_level, q.exam_year, q.banca, q.source, q.correct_answer, q.image_url
       FROM questions q
       WHERE q.id = $1 AND q.status = 'ativo'`,
      [id]
    );

    if (questionResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Questão não encontrada' 
      });
    }

    const question = questionResult.rows[0];

    const alternativesResult = await pool.query(
      'SELECT id, letter, content, image_url FROM alternatives WHERE question_id = $1 ORDER BY letter',
      [id]
    );

    // Incrementar visualizações
    await pool.query(
      'UPDATE questions SET views_count = views_count + 1 WHERE id = $1',
      [id]
    );

    res.json({
      success: true,
      data: {
        ...question,
        alternatives: alternativesResult.rows
      }
    });
  } catch (error) {
    console.error('Erro ao buscar questão:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar questão' 
    });
  }
};

export const submitAnswer = async (req, res) => {
  try {
    const { questionId, selectedAnswer } = req.body;
    const userId = req.user.id;

    if (!questionId || !selectedAnswer) {
      return res.status(400).json({ 
        success: false, 
        error: 'Question ID e resposta são obrigatórios' 
      });
    }

    const questionResult = await pool.query(
      'SELECT id, subject_id, correct_answer FROM questions WHERE id = $1',
      [questionId]
    );

    if (questionResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Questão não encontrada' 
      });
    }

    const question = questionResult.rows[0];
    const isCorrect = selectedAnswer === question.correct_answer;

    // Registrar resposta
    const answerResult = await pool.query(
      `INSERT INTO user_answers (user_id, question_id, selected_answer, is_correct, source)
       VALUES ($1, $2, $3, $4, 'study')
       RETURNING id, is_correct`,
      [userId, questionId, selectedAnswer, isCorrect]
    );

    // Atualizar contador na questão
    if (isCorrect) {
      await pool.query(
        'UPDATE questions SET correct_count = correct_count + 1 WHERE id = $1',
        [questionId]
      );
    } else {
      await pool.query(
        'UPDATE questions SET wrong_count = wrong_count + 1 WHERE id = $1',
        [questionId]
      );
    }

    res.json({
      success: true,
      message: isCorrect ? 'Resposta correta!' : 'Resposta incorreta!',
      data: {
        isCorrect,
        correctAnswer: question.correct_answer
      }
    });
  } catch (error) {
    console.error('Erro ao enviar resposta:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao enviar resposta' 
    });
  }
};
