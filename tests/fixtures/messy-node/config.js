// Configuration
const config = {
    port: 3000,
    dbHost: "localhost",
    dbUser: "root",
    dbPassword: "example_db_password",
    dbName: "myapp",
    apiUrl: "http://localhost:3000",
    adminEmail: "admin@localhost",
    jwtSecret: "example_jwt_secret",
    sessionTimeout: 3600,
    maxUploadSize: 10485760,
    allowedOrigins: ["http://localhost:3000", "http://localhost:8080"],
    smtpHost: "smtp.gmail.com",
    smtpPort: 587,
    smtpUser: "myapp@gmail.com",
    smtpPass: "example_smtp_pass",
    redisUrl: "redis://localhost:6379",
    logLevel: "debug",
    env: "development"
};

module.exports = config;
