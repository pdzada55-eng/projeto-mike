import pool from '../config/database.js';

export const getUserPerformance = async (req, res) => {
  try {
    const userId = req.user.id;

    // Desempenho geral
    const generalResult = await pool.query(
      `SELECT 
        COUNT(DISTINCT id) as total_answered,
        SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) as correct_answers,
        SUM(CASE WHEN NOT is_correct THEN 1 ELSE 0 END) as wrong_answers,
        ROUND((SUM(CASE WHEN is_correct THEN 1 ELSE 0 END)::DECIMAL / NULLIF(COUNT(DISTINCT id), 0)) * 100, 2) as accuracy
       FROM user_answers
       WHERE user_id = $1`,
      [userId]
    );

    // Desempenho por matéria
    const subjectsResult = await pool.query(
      `SELECT 
        s.id, s.name, s.color_code,
        COUNT(DISTINCT ua.id) as questions_answered,
        SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END) as correct,
        SUM(CASE WHEN NOT ua.is_correct THEN 1 ELSE 0 END) as wrong,
        ROUND((SUM(CASE WHEN ua.is_correct THEN 1 ELSE 0 END)::DECIMAL / NULLIF(COUNT(DISTINCT ua.id), 0)) * 100, 2) as accuracy
       FROM user_answers ua
       JOIN questions q ON ua.question_id = q.id
       JOIN subjects s ON q.subject_id = s.id
       WHERE ua.user_id = $1
       GROUP BY s.id, s.name, s.color_code
       ORDER BY accuracy DESC`,
      [userId]
    );

    // Últimas respostas
    const recentResult = await pool.query(
      `SELECT 
        ua.id, ua.question_id, ua.selected_answer, ua.is_correct, ua.answered_at,
        q.enunciation, q.correct_answer
       FROM user_answers ua
       JOIN questions q ON ua.question_id = q.id
       WHERE ua.user_id = $1
       ORDER BY ua.answered_at DESC
       LIMIT 10`,
      [userId]
    );

    res.json({
      success: true,
      data: {
        general: generalResult.rows[0],
        bySubject: subjectsResult.rows,
        recentAnswers: recentResult.rows
      }
    });
  } catch (error) {
    console.error('Erro ao buscar desempenho:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar desempenho' 
    });
  }
};

export const getWrongQuestions = async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT 
        ua.id, ua.question_id, ua.selected_answer, ua.answered_at,
        q.id as id, q.enunciation, q.difficulty_level, q.correct_answer, q.explanation
       FROM user_answers ua
       JOIN questions q ON ua.question_id = q.id
       WHERE ua.user_id = $1 AND ua.is_correct = false
       ORDER BY ua.answered_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const countResult = await pool.query(
      'SELECT COUNT(*) FROM user_answers WHERE user_id = $1 AND is_correct = false',
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
    console.error('Erro ao buscar questões erradas:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar questões erradas' 
    });
  }
};
