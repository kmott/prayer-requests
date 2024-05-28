const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const http = require('http');
const WebSocket = require('ws');
const session = require('express-session');
const app = express();
const port = 3000;

// Use body-parser middleware
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Use session middleware
app.use(session({
    secret: 'your-secret-key',
    resave: false,
    saveUninitialized: true
}));

// Store prayer requests and submission state in memory
let prayerRequests = [];
let submissionsEnabled = true; // This variable controls if submissions are allowed

// Dummy admin credentials
const adminCredentials = {
    username: 'admin',
    password: 'admin123'
};

// Authentication middleware
function isAuthenticated(req, res, next) {
    if (req.session.isAuthenticated) {
        next();
    } else {
        res.redirect('/admin');
    }
}

// Admin login endpoint
app.post('/admin-login', (req, res) => {
    const { username, password } = req.body;
    if (username === adminCredentials.username && password === adminCredentials.password) {
        req.session.isAuthenticated = true;
        res.status(200).send('Login successful');
    } else {
        res.status(401).send('Invalid credentials');
    }
});

// Admin dashboard route
app.get('/admin-dashboard', isAuthenticated, (req, res) => {
    res.sendFile(path.join(__dirname, 'html/admin_dashboard.html'));
});

// Admin login page route
app.get('/admin', (req, res) => {
    res.sendFile(path.join(__dirname, 'html/admin.html'));
});

// Endpoint to toggle prayer request submissions
app.post('/toggle-submissions', isAuthenticated, (req, res) => {
    submissionsEnabled = !submissionsEnabled;

    // Broadcast submission status to all connected clients
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({ submissionsEnabled }));
        }
    });

    res.json({ submissionsEnabled });
});

// Endpoint to get submission status
app.get('/submission-status', (req, res) => {
    res.json({ submissionsEnabled });
});

// Endpoint to handle prayer request submission
app.post('/submit-prayer', (req, res) => {
    if (!submissionsEnabled) {
        return res.status(403).send('Submissions are currently disabled');
    }

    const prayer = req.body.prayer;
    if (prayer) {
        prayerRequests.push(prayer);
        console.log('New prayer request submitted:', prayer);

        // Broadcast new prayer request to all connected clients
        wss.clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify({ prayerRequests }));
            }
        });

        res.status(200).send('Prayer request submitted successfully');
    } else {
        res.status(400).send('Invalid prayer request');
    }
});

// Endpoint to get all prayer requests
app.get('/prayer-requests', (req, res) => {
    res.json({ prayerRequests: prayerRequests });
});

// Endpoint to reset prayer requests
app.post('/reset-requests', isAuthenticated, (req, res) => {
    prayerRequests = [];

    // Broadcast reset event to all connected clients
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(JSON.stringify({ reset: true }));
        }
    });

    res.json({ success: true });
});

// Serve the submit.html file
app.get('/submit', (req, res) => {
    res.sendFile(path.join(__dirname, 'html/submit.html'));
});

// Serve the display.html file
app.get('/display', (req, res) => {
    res.sendFile(path.join(__dirname, 'html/display.html'));
});

app.get(['/', '/index', '/index.html'], (req, res) => {
    res.redirect('/submit');
});

// Serve static files
app.use(express.static(path.join(__dirname)));

// Create HTTP server and WebSocket server
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Start the server
server.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});
