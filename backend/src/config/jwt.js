import jwt from 'jsonwebtoken';

const secret = process.env.JWT_SECRET || 'seu-secret-key-super-seguro';
const expiresIn = process.env.JWT_EXPIRES_IN || '7d';

export const generateToken = (userId, userRole = 'student') => {
  return jwt.sign(
    { id: userId, role: userRole },
    secret,
    { expiresIn }
  );
};

export const verifyToken = (token) => {
  try {
    return jwt.verify(token, secret);
  } catch (error) {
    return null;
  }
};

export const decodeToken = (token) => {
  try {
    return jwt.decode(token);
  } catch (error) {
    return null;
  }
};
