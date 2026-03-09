module.exports = {
  apps: [{
    name: 'yunchuang-server',
    script: 'app.js',
    cwd: '/var/www/yunchuang/server',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/pm2/yunchuang-error.log',
    out_file: '/var/log/pm2/yunchuang-out.log',
    log_file: '/var/log/pm2/yunchuang-combined.log',
    time: true
  }]
};
