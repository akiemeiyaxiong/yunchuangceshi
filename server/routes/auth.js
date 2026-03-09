const express = require('express');
const router = express.Router();
const { register, login, getApiKeys, verifyUser } = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.get('/keys', getApiKeys);
router.get('/verify', verifyUser);

module.exports = router;
