import { verifyToken } from '../config/jwt.js';

export const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        success: false,
        error: 'Token não fornecido' 
      });
    }

    const token = authHeader.substring(7);
    const decoded = verifyToken(token);

    if (!decoded) {
      return res.status(401).json({ 
        success: false,
        error: 'Token inválido ou expirado' 
      });
    }

    req.user = decoded;
    next();
  } catch (error) {
    res.status(500).json({ 
      success: false,
      error: 'Erro ao autenticar' 
    });
  }
};

export const isAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ 
      success: false,
      error: 'Acesso restrito a administradores' 
    });
  }
  next();
};

export const isModerator = (req, res, next) => {
  if (req.user.role !== 'admin' && req.user.role !== 'moderator') {
    return res.status(403).json({ 
      success: false,
      error: 'Acesso restrito a moderadores' 
    });
  }
  next();
};
