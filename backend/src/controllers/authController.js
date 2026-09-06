import pool from '../config/database.js';
import bcrypt from 'bcryptjs';
import { generateToken } from '../config/jwt.js';
import { validateEmail, validateCPF, validatePassword } from '../middleware/validation.js';

export const register = async (req, res) => {
  try {
    const { email, password, fullName, cpf, phone, dateOfBirth } = req.body;

    // Validações
    if (!email || !password || !fullName) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email, senha e nome são obrigatórios' 
      });
    }

    if (!validateEmail(email)) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email inválido' 
      });
    }

    if (!validatePassword(password)) {
      return res.status(400).json({ 
        success: false, 
        error: 'Senha deve ter no mínimo 6 caracteres' 
      });
    }

    if (cpf && !validateCPF(cpf)) {
      return res.status(400).json({ 
        success: false, 
        error: 'CPF inválido' 
      });
    }

    // Verificar se email já existe
    const userExists = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email]
    );

    if (userExists.rows.length > 0) {
      return res.status(409).json({ 
        success: false, 
        error: 'Email já cadastrado' 
      });
    }

    // Hash de senha
    const hashedPassword = await bcrypt.hash(password, 10);

    // Criar usuário
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, full_name, cpf, phone, date_of_birth, role, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, uuid, email, full_name, role`,
      [email, hashedPassword, fullName, cpf || null, phone || null, dateOfBirth || null, 'student', 'ativo']
    );

    const user = result.rows[0];
    const token = generateToken(user.id, user.role);

    res.status(201).json({
      success: true,
      message: 'Usuário registrado com sucesso',
      data: {
        id: user.id,
        uuid: user.uuid,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        token
      }
    });
  } catch (error) {
    console.error('Erro ao registrar:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao registrar usuário' 
    });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ 
        success: false, 
        error: 'Email e senha são obrigatórios' 
      });
    }

    const result = await pool.query(
      'SELECT id, uuid, email, full_name, password_hash, role, status FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        error: 'Credenciais inválidas' 
      });
    }

    const user = result.rows[0];

    if (user.status !== 'ativo') {
      return res.status(401).json({ 
        success: false, 
        error: 'Usuário inativo ou bloqueado' 
      });
    }

    const passwordMatch = await bcrypt.compare(password, user.password_hash);

    if (!passwordMatch) {
      return res.status(401).json({ 
        success: false, 
        error: 'Credenciais inválidas' 
      });
    }

    // Atualizar last_login
    await pool.query(
      'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    const token = generateToken(user.id, user.role);

    res.json({
      success: true,
      message: 'Login realizado com sucesso',
      data: {
        id: user.id,
        uuid: user.uuid,
        email: user.email,
        fullName: user.full_name,
        role: user.role,
        token
      }
    });
  } catch (error) {
    console.error('Erro ao fazer login:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao fazer login' 
    });
  }
};

export const getProfile = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, uuid, email, full_name, cpf, phone, date_of_birth, gender, 
              profile_image_url, role, is_verified, last_login, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Usuário não encontrado' 
      });
    }

    res.json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erro ao buscar perfil:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao buscar perfil' 
    });
  }
};

export const updateProfile = async (req, res) => {
  try {
    const { fullName, phone, dateOfBirth, gender, bio, profileImageUrl } = req.body;

    const result = await pool.query(
      `UPDATE users 
       SET full_name = COALESCE($1, full_name),
           phone = COALESCE($2, phone),
           date_of_birth = COALESCE($3, date_of_birth),
           gender = COALESCE($4, gender),
           bio = COALESCE($5, bio),
           profile_image_url = COALESCE($6, profile_image_url)
       WHERE id = $7
       RETURNING id, uuid, email, full_name, cpf, phone, date_of_birth, gender, bio, profile_image_url, role`,
      [fullName, phone, dateOfBirth, gender, bio, profileImageUrl, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Usuário não encontrado' 
      });
    }

    res.json({
      success: true,
      message: 'Perfil atualizado com sucesso',
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Erro ao atualizar perfil:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Erro ao atualizar perfil' 
    });
  }
};
