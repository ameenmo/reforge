// Configuration
const config = {
    port: 3000,
    dbHost: "localhost",
    dbUser: "root",
    dbPassword: "mysecretpassword123",
    dbName: "myapp",
    apiUrl: "http://localhost:3000",
    adminEmail: "admin@localhost",
    jwtSecret: "supersecretjwtkey123",
    sessionTimeout: 3600,
    maxUploadSize: 10485760,
    allowedOrigins: ["http://localhost:3000", "http://localhost:8080"],
    smtpHost: "smtp.gmail.com",
    smtpPort: 587,
    smtpUser: "myapp@gmail.com",
    smtpPass: "emailpassword456",
    redisUrl: "redis://localhost:6379",
    logLevel: "debug",
    env: "development"
};

module.exports = config;
