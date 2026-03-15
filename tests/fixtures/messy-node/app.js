// app.js - The main application file. Everything goes here.
const express = require('express');
const mysql = require('mysql');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Hardcoded credentials - bad practice
const API_KEY = "sk-test1234567890abcdefghij";
const DB_PASSWORD = "mysecretpassword123";
const JWT_SECRET = "supersecretjwtkey123";
const ADMIN_TOKEN = "admin-token-xyz-987654";

// Database connection right here in the main file
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: DB_PASSWORD,
    database: 'myapp'
});

db.connect((err) => {
    if (err) {
        console.log('Database connection failed: ' + err.message);
    } else {
        console.log('Connected to database');
    }
});

// Utility function mixed in with routes
function formatDate(date) {
    var d = new Date(date);
    var month = '' + (d.getMonth() + 1);
    var day = '' + d.getDate();
    var year = d.getFullYear();
    if (month.length < 2) month = '0' + month;
    if (day.length < 2) day = '0' + day;
    return [year, month, day].join('-');
}

// Another utility mixed in
function generateId() {
    return Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
}

// Hash password utility
function hashPassword(password) {
    return crypto.createHash('md5').update(password).digest('hex');
}

// Validate email utility
function validateEmail(email) {
    var re = /\S+@\S+\.\S+/;
    return re.test(email);
}

// Validate phone utility
function validatePhone(phone) {
    var re = /^\d{10}$/;
    return re.test(phone);
}

// Sanitize string - basic
function sanitizeString(str) {
    return str.replace(/[^a-zA-Z0-9 ]/g, '');
}

// Calculate tax
function calculateTax(amount, rate) {
    return amount * (rate / 100);
}

// Calculate discount
function calculateDiscount(price, discountPercent) {
    return price - (price * discountPercent / 100);
}

// Format currency
function formatCurrency(amount) {
    return '$' + parseFloat(amount).toFixed(2);
}

// Parse CSV inline
function parseCSV(text) {
    var lines = text.split('\n');
    var result = [];
    var headers = lines[0].split(',');
    for (var i = 1; i < lines.length; i++) {
        var obj = {};
        var currentline = lines[i].split(',');
        for (var j = 0; j < headers.length; j++) {
            obj[headers[j]] = currentline[j];
        }
        result.push(obj);
    }
    return result;
}

// Logging function
function logMessage(level, message) {
    var timestamp = new Date().toISOString();
    console.log('[' + timestamp + '] [' + level + '] ' + message);
    fs.appendFileSync('app.log', '[' + timestamp + '] [' + level + '] ' + message + '\n');
}

// Middleware - authentication check
function authMiddleware(req, res, next) {
    var token = req.headers['authorization'];
    if (!token) {
        return res.status(401).json({ error: 'No token provided' });
    }
    if (token === ADMIN_TOKEN) {
        req.isAdmin = true;
        next();
    } else if (token === API_KEY) {
        req.isAdmin = false;
        next();
    } else {
        return res.status(403).json({ error: 'Invalid token' });
    }
}

// Middleware - request logger
app.use(function(req, res, next) {
    logMessage('INFO', req.method + ' ' + req.url);
    next();
});

// ============ USER ROUTES ============

// Get all users
app.get('/api/users', function(req, res) {
    var query = 'SELECT * FROM users';
    if (req.query.search) {
        query += " WHERE name LIKE '%" + req.query.search + "%'";  // SQL injection vulnerability
    }
    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Failed to get users: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(results);
    });
});

// Get user by ID
app.get('/api/users/:id', function(req, res) {
    var query = "SELECT * FROM users WHERE id = " + req.params.id;  // SQL injection
    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Failed to get user: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(results[0]);
    });
});

// Create user
app.post('/api/users', function(req, res) {
    var name = req.body.name;
    var email = req.body.email;
    var password = req.body.password;
    var phone = req.body.phone;

    if (!name || !email || !password) {
        return res.status(400).json({ error: 'Name, email, and password are required' });
    }
    if (!validateEmail(email)) {
        return res.status(400).json({ error: 'Invalid email' });
    }

    var hashedPassword = hashPassword(password);
    var id = generateId();
    var createdAt = formatDate(new Date());

    var query = "INSERT INTO users (id, name, email, password, phone, created_at) VALUES ('" +
        id + "', '" + name + "', '" + email + "', '" + hashedPassword + "', '" + phone + "', '" + createdAt + "')";

    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to create user: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        logMessage('INFO', 'User created: ' + email);
        res.status(201).json({ id: id, name: name, email: email, created_at: createdAt });
    });
});

// Update user
app.put('/api/users/:id', authMiddleware, function(req, res) {
    var name = req.body.name;
    var email = req.body.email;
    var phone = req.body.phone;

    var query = "UPDATE users SET name = '" + name + "', email = '" + email + "', phone = '" + phone + "' WHERE id = '" + req.params.id + "'";

    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to update user: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json({ message: 'User updated' });
    });
});

// Delete user
app.delete('/api/users/:id', authMiddleware, function(req, res) {
    var query = "DELETE FROM users WHERE id = '" + req.params.id + "'";
    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to delete user: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json({ message: 'User deleted' });
    });
});

// ============ PRODUCT ROUTES ============

// Get all products
app.get('/api/products', function(req, res) {
    var query = 'SELECT * FROM products';
    if (req.query.category) {
        query += " WHERE category = '" + req.query.category + "'";
    }
    if (req.query.sort) {
        query += " ORDER BY " + req.query.sort;
    }
    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Failed to get products: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        var formatted = results.map(function(p) {
            return {
                id: p.id,
                name: p.name,
                price: formatCurrency(p.price),
                priceWithTax: formatCurrency(p.price + calculateTax(p.price, 8.5)),
                category: p.category,
                inStock: p.quantity > 0
            };
        });
        res.json(formatted);
    });
});

// Get product by ID
app.get('/api/products/:id', function(req, res) {
    var query = "SELECT * FROM products WHERE id = " + req.params.id;
    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Failed to get product: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (results.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(results[0]);
    });
});

// Create product
app.post('/api/products', authMiddleware, function(req, res) {
    var name = req.body.name;
    var price = req.body.price;
    var category = req.body.category;
    var description = req.body.description;
    var quantity = req.body.quantity || 0;

    if (!name || !price) {
        return res.status(400).json({ error: 'Name and price are required' });
    }

    var id = generateId();
    var createdAt = formatDate(new Date());

    var query = "INSERT INTO products (id, name, price, category, description, quantity, created_at) VALUES ('" +
        id + "', '" + name + "', " + price + ", '" + category + "', '" + description + "', " + quantity + ", '" + createdAt + "')";

    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to create product: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        logMessage('INFO', 'Product created: ' + name);
        res.status(201).json({ id: id, name: name, price: price });
    });
});

// Update product
app.put('/api/products/:id', authMiddleware, function(req, res) {
    var name = req.body.name;
    var price = req.body.price;
    var category = req.body.category;
    var description = req.body.description;
    var quantity = req.body.quantity;

    var query = "UPDATE products SET name = '" + name + "', price = " + price +
        ", category = '" + category + "', description = '" + description +
        "', quantity = " + quantity + " WHERE id = '" + req.params.id + "'";

    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to update product: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json({ message: 'Product updated' });
    });
});

// Delete product
app.delete('/api/products/:id', authMiddleware, function(req, res) {
    var query = "DELETE FROM products WHERE id = '" + req.params.id + "'";
    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to delete product: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json({ message: 'Product deleted' });
    });
});

// ============ ORDER ROUTES ============

// Get all orders
app.get('/api/orders', authMiddleware, function(req, res) {
    var query = 'SELECT * FROM orders';
    if (req.query.status) {
        query += " WHERE status = '" + req.query.status + "'";
    }
    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Failed to get orders: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(results);
    });
});

// Create order
app.post('/api/orders', authMiddleware, function(req, res) {
    var userId = req.body.userId;
    var productId = req.body.productId;
    var quantity = req.body.quantity;

    if (!userId || !productId || !quantity) {
        return res.status(400).json({ error: 'userId, productId, and quantity are required' });
    }

    // Get product price directly in route handler
    var productQuery = "SELECT * FROM products WHERE id = '" + productId + "'";
    db.query(productQuery, function(err, products) {
        if (err) {
            logMessage('ERROR', 'Failed to find product for order: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (products.length === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }

        var product = products[0];
        if (product.quantity < quantity) {
            return res.status(400).json({ error: 'Not enough stock' });
        }

        var subtotal = product.price * quantity;
        var tax = calculateTax(subtotal, 8.5);
        var total = subtotal + tax;
        var id = generateId();
        var createdAt = formatDate(new Date());

        var orderQuery = "INSERT INTO orders (id, user_id, product_id, quantity, subtotal, tax, total, status, created_at) VALUES ('" +
            id + "', '" + userId + "', '" + productId + "', " + quantity + ", " + subtotal + ", " + tax + ", " + total + ", 'pending', '" + createdAt + "')";

        db.query(orderQuery, function(err, result) {
            if (err) {
                logMessage('ERROR', 'Failed to create order: ' + err.message);
                return res.status(500).json({ error: 'Database error' });
            }

            // Update product stock
            var updateStockQuery = "UPDATE products SET quantity = quantity - " + quantity + " WHERE id = '" + productId + "'";
            db.query(updateStockQuery, function(err, result) {
                if (err) {
                    logMessage('ERROR', 'Failed to update stock: ' + err.message);
                }
            });

            logMessage('INFO', 'Order created: ' + id);
            res.status(201).json({
                id: id,
                total: formatCurrency(total),
                status: 'pending'
            });
        });
    });
});

// Update order status
app.put('/api/orders/:id/status', authMiddleware, function(req, res) {
    var status = req.body.status;
    var validStatuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled'];

    if (validStatuses.indexOf(status) === -1) {
        return res.status(400).json({ error: 'Invalid status' });
    }

    var query = "UPDATE orders SET status = '" + status + "' WHERE id = '" + req.params.id + "'";
    db.query(query, function(err, result) {
        if (err) {
            logMessage('ERROR', 'Failed to update order status: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json({ message: 'Order status updated to ' + status });
    });
});

// ============ AUTH ROUTES ============

// Login
app.post('/api/login', function(req, res) {
    var email = req.body.email;
    var password = req.body.password;

    if (!email || !password) {
        return res.status(400).json({ error: 'Email and password are required' });
    }

    var hashedPassword = hashPassword(password);
    var query = "SELECT * FROM users WHERE email = '" + email + "' AND password = '" + hashedPassword + "'";

    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Login error: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (results.length === 0) {
            return res.status(401).json({ error: 'Invalid credentials' });
        }

        var user = results[0];
        // Generate a "token" (not actually JWT, just pretend)
        var token = crypto.createHash('sha256').update(user.id + Date.now().toString()).digest('hex');

        logMessage('INFO', 'User logged in: ' + email);
        res.json({
            token: token,
            user: { id: user.id, name: user.name, email: user.email }
        });
    });
});

// Register
app.post('/api/register', function(req, res) {
    var name = req.body.name;
    var email = req.body.email;
    var password = req.body.password;

    if (!name || !email || !password) {
        return res.status(400).json({ error: 'All fields are required' });
    }
    if (!validateEmail(email)) {
        return res.status(400).json({ error: 'Invalid email format' });
    }
    if (password.length < 6) {
        return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }

    // Check if email exists
    var checkQuery = "SELECT id FROM users WHERE email = '" + email + "'";
    db.query(checkQuery, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Registration check error: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        if (results.length > 0) {
            return res.status(409).json({ error: 'Email already registered' });
        }

        var hashedPassword = hashPassword(password);
        var id = generateId();
        var createdAt = formatDate(new Date());

        var insertQuery = "INSERT INTO users (id, name, email, password, created_at) VALUES ('" +
            id + "', '" + name + "', '" + email + "', '" + hashedPassword + "', '" + createdAt + "')";

        db.query(insertQuery, function(err, result) {
            if (err) {
                logMessage('ERROR', 'Registration insert error: ' + err.message);
                return res.status(500).json({ error: 'Database error' });
            }
            logMessage('INFO', 'User registered: ' + email);
            res.status(201).json({ id: id, name: name, email: email });
        });
    });
});

// ============ REPORT ROUTES ============

// Sales report
app.get('/api/reports/sales', authMiddleware, function(req, res) {
    var startDate = req.query.start || '2020-01-01';
    var endDate = req.query.end || formatDate(new Date());

    var query = "SELECT DATE(created_at) as date, COUNT(*) as count, SUM(total) as revenue FROM orders WHERE created_at BETWEEN '" + startDate + "' AND '" + endDate + "' GROUP BY DATE(created_at)";

    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'Sales report error: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }

        var totalRevenue = 0;
        var totalOrders = 0;
        results.forEach(function(row) {
            totalRevenue += row.revenue;
            totalOrders += row.count;
        });

        res.json({
            period: { start: startDate, end: endDate },
            totalRevenue: formatCurrency(totalRevenue),
            totalOrders: totalOrders,
            averageOrderValue: formatCurrency(totalRevenue / totalOrders),
            daily: results
        });
    });
});

// User report
app.get('/api/reports/users', authMiddleware, function(req, res) {
    var query = "SELECT COUNT(*) as total, DATE(created_at) as date FROM users GROUP BY DATE(created_at) ORDER BY date DESC LIMIT 30";

    db.query(query, function(err, results) {
        if (err) {
            logMessage('ERROR', 'User report error: ' + err.message);
            return res.status(500).json({ error: 'Database error' });
        }
        res.json(results);
    });
});

// ============ UPLOAD ROUTE ============

app.post('/api/upload', authMiddleware, function(req, res) {
    // Pretend file upload handling
    var filename = req.body.filename;
    var data = req.body.data;

    if (!filename || !data) {
        return res.status(400).json({ error: 'Filename and data required' });
    }

    var uploadPath = path.join(__dirname, 'uploads', filename);  // Path traversal vulnerability
    fs.writeFileSync(uploadPath, Buffer.from(data, 'base64'));

    logMessage('INFO', 'File uploaded: ' + filename);
    res.json({ message: 'File uploaded', path: uploadPath });
});

// ============ SEARCH ROUTE ============

app.get('/api/search', function(req, res) {
    var term = req.query.q;
    if (!term) {
        return res.status(400).json({ error: 'Search term required' });
    }

    var userQuery = "SELECT 'user' as type, id, name FROM users WHERE name LIKE '%" + term + "%'";
    var productQuery = "SELECT 'product' as type, id, name FROM products WHERE name LIKE '%" + term + "%'";

    db.query(userQuery, function(err, userResults) {
        if (err) {
            return res.status(500).json({ error: 'Search error' });
        }
        db.query(productQuery, function(err, productResults) {
            if (err) {
                return res.status(500).json({ error: 'Search error' });
            }
            res.json({
                users: userResults,
                products: productResults,
                total: userResults.length + productResults.length
            });
        });
    });
});

// ============ STATIC FILES ============

app.use(express.static(__dirname));

// ============ ERROR HANDLER ============

app.use(function(err, req, res, next) {
    logMessage('ERROR', 'Unhandled error: ' + err.message);
    console.log(err.stack);
    res.status(500).json({ error: 'Internal server error', details: err.message });  // Leaking error details
});

// ============ START SERVER ============

var PORT = 3000;
app.listen(PORT, function() {
    console.log('Server running on http://localhost:' + PORT);
    logMessage('INFO', 'Server started on port ' + PORT);
});

module.exports = app;
