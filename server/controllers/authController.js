require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../config/database');

const register = async (req, res) => {
    const { username, dept, password } = req.body;

    if (!username || !dept || !password) {
        return res.status(400).json({
            success: false,
            message: '请填写完整信息'
        });
    }

    if (username.length < 2 || username.length > 20) {
        return res.status(400).json({
            success: false,
            message: '姓名长度应为2-20个字符'
        });
    }

    if (password.length < 6) {
        return res.status(400).json({
            success: false,
            message: '密码长度不能少于6位'
        });
    }

    try {
        const [existingUsers] = await db.query(
            'SELECT id FROM users WHERE username = ?',
            [username]
        );

        if (existingUsers.length > 0) {
            return res.status(400).json({
                success: false,
                message: '该姓名已被注册'
            });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        await db.query(
            'INSERT INTO users (username, dept, password, status) VALUES (?, ?, ?, ?)',
            [username, dept, hashedPassword, 'pending']
        );

        res.status(201).json({
            success: true,
            message: '注册成功，请等待管理员审核通过后登录'
        });
    } catch (error) {
        console.error('注册错误:', error);
        res.status(500).json({
            success: false,
            message: '注册失败，请稍后重试'
        });
    }
};

const login = async (req, res) => {
    const { username, password } = req.body;

    if (!username || !password) {
        return res.status(400).json({
            success: false,
            message: '请输入用户名和密码'
        });
    }

    try {
        const [users] = await db.query(
            'SELECT id, username, dept, password AS password_hash, status FROM users WHERE username = ?',
            [username]
        );

        if (users.length === 0) {
            return res.status(401).json({
                success: false,
                message: '用户名或密码错误'
            });
        }

        const user = users[0];

        if (user.status === 'pending') {
            return res.status(403).json({
                success: false,
                message: '账号待审核，请等待管理员审核通过后登录'
            });
        }

        if (user.status === 'rejected') {
            return res.status(403).json({
                success: false,
                message: '账号审核未通过，请联系管理员'
            });
        }

        // 兼容明文密码和加密密码
        let isMatch = false;
        if (user.password_hash.startsWith('$2')) {
            // 加密密码，使用bcrypt比较
            isMatch = await bcrypt.compare(password, user.password_hash);
        } else {
            // 明文密码，直接比较
            isMatch = password === user.password_hash;
        }

        if (!isMatch) {
            return res.status(401).json({
                success: false,
                message: '用户名或密码错误'
            });
        }

        await db.query(
            'UPDATE users SET last_login = NOW() WHERE id = ?',
            [user.id]
        );

        res.json({
            success: true,
            message: '登录成功',
            data: {
                username: user.username,
                dept: user.dept
            }
        });
    } catch (error) {
        console.error('登录错误:', error);
        res.status(500).json({
            success: false,
            message: '登录失败，请稍后重试'
        });
    }
};

const getApiKeys = async (req, res) => {
    const { username } = req.query;

    if (!username) {
        return res.status(400).json({
            success: false,
            message: '请提供用户名'
        });
    }

    try {
        const [users] = await db.query(
            'SELECT doubao_api_key, google_api_key FROM users WHERE username = ?',
            [username]
        );

        if (users.length === 0) {
            return res.status(404).json({
                success: false,
                message: '用户不存在'
            });
        }

        const user = users[0];

        res.json({
            success: true,
            data: {
                doubao_api_key: user.doubao_api_key || '',
                google_api_key: user.google_api_key || ''
            }
        });
    } catch (error) {
        console.error('获取API密钥错误:', error);
        res.status(500).json({
            success: false,
            message: '获取API密钥失败'
        });
    }
};

const verifyUser = async (req, res) => {
    const { username } = req.query;

    if (!username) {
        return res.json({
            success: false,
            valid: false,
            message: '未提供用户名'
        });
    }

    try {
        const [users] = await db.query(
            'SELECT id, status FROM users WHERE username = ?',
            [username]
        );

        if (users.length === 0) {
            return res.json({
                success: false,
                valid: false,
                message: '用户不存在'
            });
        }

        const user = users[0];

        if (user.status !== 'approved') {
            return res.json({
                success: false,
                valid: false,
                message: '账号状态异常'
            });
        }

        res.json({
            success: true,
            valid: true,
            message: '用户验证通过'
        });
    } catch (error) {
        console.error('验证用户错误:', error);
        res.status(500).json({
            success: false,
            valid: false,
            message: '验证失败'
        });
    }
};

module.exports = { register, login, getApiKeys, verifyUser };
