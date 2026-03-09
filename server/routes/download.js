const express = require('express');
const router = express.Router();

router.get('/proxy', async (req, res) => {
    const { url } = req.query;
    
    if (!url) {
        return res.status(400).json({ success: false, message: '缺少图片URL' });
    }

    try {
        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        });

        if (!response.ok) {
            return res.status(response.status).json({ 
                success: false, 
                message: `获取图片失败: ${response.status}` 
            });
        }

        const contentType = response.headers.get('content-type') || 'image/png';
        const buffer = await response.arrayBuffer();

        res.set('Content-Type', contentType);
        res.set('Content-Length', buffer.byteLength);
        res.set('Cache-Control', 'public, max-age=86400');
        res.send(Buffer.from(buffer));
    } catch (error) {
        console.error('图片代理下载失败:', error);
        res.status(500).json({ 
            success: false, 
            message: '图片下载失败: ' + error.message 
        });
    }
});

router.post('/batch', async (req, res) => {
    const { urls } = req.body;
    
    if (!urls || !Array.isArray(urls) || urls.length === 0) {
        return res.status(400).json({ success: false, message: '缺少图片URL列表' });
    }

    try {
        const results = [];
        
        for (const url of urls) {
            try {
                const response = await fetch(url, {
                    method: 'GET',
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                    }
                });

                if (response.ok) {
                    const contentType = response.headers.get('content-type') || 'image/png';
                    const buffer = await response.arrayBuffer();
                    const base64 = Buffer.from(buffer).toString('base64');
                    
                    results.push({
                        url: url,
                        success: true,
                        data: `data:${contentType};base64,${base64}`
                    });
                } else {
                    results.push({
                        url: url,
                        success: false,
                        error: `HTTP ${response.status}`
                    });
                }
            } catch (error) {
                results.push({
                    url: url,
                    success: false,
                    error: error.message
                });
            }
        }

        res.json({ success: true, results });
    } catch (error) {
        console.error('批量下载失败:', error);
        res.status(500).json({ 
            success: false, 
            message: '批量下载失败: ' + error.message 
        });
    }
});

module.exports = router;
