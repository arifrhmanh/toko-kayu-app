require('dotenv').config();

const app = require('./src/app');
const db = require('./src/config/database');
const { initializeStorage } = require('./src/config/storage');
const { cleanExpiredTokens } = require('./src/utils/jwt');

const PORT = process.env.PORT || 3000;

// Test database connection and start server
async function startServer() {
    try {
        // Test database connection with retry
        let retries = 5;
        while (retries > 0) {
            try {
                await db.raw('SELECT 1');
                console.log('✅ Database connected successfully');
                break;
            } catch (err) {
                console.error(`⚠️ Database connection attempt failed (${err.message}). Retrying in 2s...`);
                retries--;
                if (retries === 0) throw err;
                await new Promise(resolve => setTimeout(resolve, 2000));
            }
        }

        // Initialize Supabase storage bucket
        if (process.env.SUPABASE_URL && process.env.SUPABASE_KEY) {
            await initializeStorage();
            console.log('✅ Storage initialized');
        } else {
            console.warn('⚠️ Supabase credentials not configured, storage features disabled');
        }

        // Clean expired refresh tokens periodically (every hour)
        setInterval(async () => {
            const deleted = await cleanExpiredTokens();
            if (deleted > 0) {
                console.log(`🧹 Cleaned ${deleted} expired refresh tokens`);
            }
        }, 60 * 60 * 1000);

        // Start server
        app.listen(PORT, () => {
            console.log(`
╔════════════════════════════════════════════════╗
║                                                ║
║   🪵 Kayu Adi Backend Server                   ║
║                                                ║
║   Environment: ${(process.env.NODE_ENV || 'development').padEnd(29)}║
║   Port: ${PORT.toString().padEnd(36)}║
║   URL: http://localhost:${PORT}${' '.repeat(22 - PORT.toString().length)}║
║                                                ║
║   API Docs: http://localhost:${PORT}/api${' '.repeat(17 - PORT.toString().length)}║
║                                                ║
╚════════════════════════════════════════════════╝
      `);
        });

    } catch (error) {
        console.error('❌ Failed to start server:', error.message);
        process.exit(1);
    }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM received. Shutting down gracefully...');
    await db.destroy();
    process.exit(0);
});

process.on('SIGINT', async () => {
    console.log('SIGINT received. Shutting down gracefully...');
    await db.destroy();
    process.exit(0);
});

startServer();
