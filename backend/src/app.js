const express = require('express');
const cors = require('cors');
const { errorHandler, notFoundHandler } = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./routes/auth.routes');
const produkRoutes = require('./routes/produk.routes');
const kulakanRoutes = require('./routes/kulakan.routes');
const orderRoutes = require('./routes/order.routes');
const alamatRoutes = require('./routes/alamat.routes');
const keuanganRoutes = require('./routes/keuangan.routes');
const notifikasiRoutes = require('./routes/notifikasi.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const paymentRoutes = require('./routes/payment.routes');

const app = express();

// CORS configuration
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    credentials: true
}));

// Body parser
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        environment: process.env.NODE_ENV || 'development'
    });
});

// API info endpoint
app.get('/api', (req, res) => {
    res.json({
        name: 'Kayu Adi API',
        version: '1.0.0',
        description: 'Backend API for Kayu Adi - Wood Trading Application',
        endpoints: {
            auth: '/api/auth',
            produk: '/api/produk',
            kulakan: '/api/kulakan',
            order: '/api/order',
            alamat: '/api/alamat',
            keuangan: '/api/keuangan',
            notifikasi: '/api/notifikasi',
            dashboard: '/api/dashboard',
            payment: '/api/payment'
        }
    });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/produk', produkRoutes);
app.use('/api/kulakan', kulakanRoutes);
app.use('/api/order', orderRoutes);
app.use('/api/alamat', alamatRoutes);
app.use('/api/keuangan', keuanganRoutes);
app.use('/api/notifikasi', notifikasiRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/payment', paymentRoutes);

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

module.exports = app;
