import pool from '../config/database.js';

export const getStates = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, abbreviation, region, active FROM states WHERE active = true ORDER BY name'
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erro ao buscar estados:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar estados' 
    });
  }
};

export const getSubjects = async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, description, color_code, icon_name, display_order FROM subjects WHERE active = true ORDER BY display_order'
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erro ao buscar matérias:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar matérias' 
    });
  }
};

export const getTopicsBySubject = async (req, res) => {
  try {
    const { subjectId } = req.params;

    const result = await pool.query(
      'SELECT id, subject_id, name, description, display_order FROM topics WHERE subject_id = $1 AND active = true ORDER BY display_order',
      [subjectId]
    );

    res.json({
      success: true,
      data: result.rows
    });
  } catch (error) {
    console.error('Erro ao buscar assuntos:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar assuntos' 
    });
  }
};

export const getStatistics = async (req, res) => {
  try {
    const statesCount = await pool.query('SELECT COUNT(*) FROM states WHERE active = true');
    const subjectsCount = await pool.query('SELECT COUNT(*) FROM subjects WHERE active = true');
    const questionsCount = await pool.query('SELECT COUNT(*) FROM questions WHERE status = \'ativo\'');
    const usersCount = await pool.query('SELECT COUNT(*) FROM users WHERE status = \'ativo\'');

    res.json({
      success: true,
      data: {
        states: parseInt(statesCount.rows[0].count),
        subjects: parseInt(subjectsCount.rows[0].count),
        questions: parseInt(questionsCount.rows[0].count),
        users: parseInt(usersCount.rows[0].count)
      }
    });
  } catch (error) {
    console.error('Erro ao buscar estatísticas:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar estatísticas' 
    });
  }
};
