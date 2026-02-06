require('dotenv').config();

const app = require('./src/app');
const connectDB = require('./src/config/db');
const config = require('./src/config');

const startServer = async () => {
  try {
    // Connect to MongoDB
    await connectDB();

    // Start server
    const server = app.listen(config.port, () => {
      console.log(`
╔════════════════════════════════════════╗
║       Clear Dues API Server            ║
╠════════════════════════════════════════╣
║  Status:    Running                    ║
║  Port:      ${config.port.toString().padEnd(27)}║
║  Mode:      ${config.nodeEnv.padEnd(27)}║
║  API:       http://localhost:${config.port}/api    ║
╚════════════════════════════════════════╝
      `);
    });

    // Graceful shutdown handler
    const gracefulShutdown = (signal) => {
      console.log(`\n${signal} received. Shutting down gracefully...`);
      server.close(() => {
        console.log('HTTP server closed.');
        process.exit(0);
      });

      // Force close after 10s
      setTimeout(() => {
        console.error('Forcing shutdown...');
        process.exit(1);
      }, 10000);
    };

    // Handle shutdown signals
    process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
    process.on('SIGINT', () => gracefulShutdown('SIGINT'));

    // Handle unhandled promise rejections
    process.on('unhandledRejection', (err) => {
      console.error('Unhandled Rejection:', err.message);
      server.close(() => process.exit(1));
    });

    // Handle uncaught exceptions
    process.on('uncaughtException', (err) => {
      console.error('Uncaught Exception:', err.message);
      process.exit(1);
    });

  } catch (error) {
    console.error('Failed to start server:', error.message);
    process.exit(1);
  }
};

startServer();
