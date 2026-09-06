import pool from '../config/database.js';

export const addFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { questionId } = req.body;

    if (!questionId) {
      return res.status(400).json({ 
        success: false, 
        error: 'Question ID é obrigatório' 
      });
    }

    const result = await pool.query(
      `INSERT INTO favorites (user_id, question_id)
       VALUES ($1, $2)
       ON CONFLICT (user_id, question_id) DO NOTHING
       RETURNING id`,
      [userId, questionId]
    );

    res.json({
      success: true,
      message: 'Questão adicionada aos favoritos'
    });
  } catch (error) {
    console.error('Erro ao adicionar favorito:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao adicionar favorito' 
    });
  }
};

export const removeFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { questionId } = req.body;

    await pool.query(
      'DELETE FROM favorites WHERE user_id = $1 AND question_id = $2',
      [userId, questionId]
    );

    res.json({
      success: true,
      message: 'Questão removida dos favoritos'
    });
  } catch (error) {
    console.error('Erro ao remover favorito:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao remover favorito' 
    });
  }
};

export const getFavorites = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT q.id, q.uuid, q.enunciation, q.difficulty_level, q.exam_year, s.name as subject_name
       FROM favorites f
       JOIN questions q ON f.question_id = q.id
       JOIN subjects s ON q.subject_id = s.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*) FROM favorites WHERE user_id = $1',
      [userId]
    );

    res.json({
      success: true,
      data: result.rows,
      pagination: {
        total: parseInt(countResult.rows[0].count),
        page: parseInt(page),
        limit: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Erro ao buscar favoritos:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar favoritos' 
    });
  }
};

export const isFavorite = async (req, res) => {
  try {
    const userId = req.user.id;
    const { questionId } = req.params;

    const result = await pool.query(
      'SELECT id FROM favorites WHERE user_id = $1 AND question_id = $2',
      [userId, questionId]
    );

    res.json({
      success: true,
      data: {
        isFavorite: result.rows.length > 0
      }
    });
  } catch (error) {
    console.error('Erro ao verificar favorito:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao verificar favorito' 
    });
  }
};
