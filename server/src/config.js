import dotenv from 'dotenv';
dotenv.config();

const nodeEnv = process.env.NODE_ENV || 'development';
const isProduction = nodeEnv === 'production';

// Never run production with the dev fallback secret
if (isProduction && !process.env.JWT_SECRET) {
  throw new Error('JWT_SECRET must be set when NODE_ENV=production');
}

// Demo login: explicit env flag wins, otherwise enabled outside production
const demoLoginEnabled = process.env.ENABLE_DEMO_LOGIN !== undefined
  ? process.env.ENABLE_DEMO_LOGIN !== 'false'
  : !isProduction;

export const config = {
  nodeEnv,
  isProduction,
  port: process.env.PORT || 5001,
  jwtSecret: process.env.JWT_SECRET || 'hamari-virasat-secret-key-2026', // dev-only fallback
  corsOrigin: process.env.CORS_ORIGIN || '*',
  demoLoginEnabled,
  ritualPrice: 299, // ₹ per catalogue ritual
  minPasswordLength: 8
};
