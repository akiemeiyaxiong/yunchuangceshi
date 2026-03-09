require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth');
const downloadRoutes = require('./routes/download');
const db = require('./config/database');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use('/api/auth', authRoutes);
app.use('/api/download', downloadRoutes);

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ success: false, message: '服务器内部错误' });
});

db.getConnection()
    .then(connection => {
        console.log('✅ 数据库连接成功');
        connection.release();
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`🚀 服务器运行在端口 ${PORT}`);
        });
    })
    .catch(err => {
        console.error('❌ 数据库连接失败:', err.message);
        process.exit(1);
    });
