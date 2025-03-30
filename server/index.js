const express = require('express');
const bodyParser = require('body-parser');
const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const cors = require('cors');
const jwt = require('jsonwebtoken');

// Initialize express application
const app = express();
//const PORT = process.env.PORT || 3000;
app.use(cors());  // Now this will work

app.get("/", (req, res) => {
    res.send("Hello, World!");
});

// Middleware
app.use(bodyParser.json());

// Initialize the database
const dbPath = path.resolve(__dirname, 'disaster_alert.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database', err);
    } else {
        console.log('Connected to SQLite database');
        initializeDatabase();
    }
});

// Add this function to your server.js file
function updateUserAlerts(userID, alertIDs) {
    if (!Array.isArray(alertIDs) || alertIDs.length === 0) {
        return; // No alerts to update
    }
    
    // Mark all existing alerts as inactive for this user
    db.run('UPDATE user_alerts SET isActive = 0 WHERE userID = ?', [userID], (err) => {
        if (err) {
            console.error('Error deactivating old alerts:', err);
            return;
        }
        
        // Add or activate the current alerts
        alertIDs.forEach(alertID => {
            db.run(
                'INSERT OR REPLACE INTO user_alerts (userID, alertID, isActive) VALUES (?, ?, 1)',
                [userID, alertID],
                (err) => {
                    if (err) {
                        console.error(`Error updating user_alert for user ${userID} and alert ${alertID}:`, err);
                    }
                }
            );
        });
    });
}

// Function to initialize the database schema
function initializeDatabase() {
    db.serialize(() => {
        // Original app tables
        db.run(`CREATE TABLE IF NOT EXISTS users (
            userID TEXT PRIMARY KEY,
            displayName TEXT,
            photoUrl TEXT,
            latitude REAL,
            longitude REAL,
            radius INTEGER,
            lastUpdate TEXT,
            batteryLevel INTEGER
        )`);

        db.run(`CREATE TABLE IF NOT EXISTS friends (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            requestorID TEXT NOT NULL,
            userId TEXT NOT NULL,
            status TEXT NOT NULL,
            lastLocationUpdate TEXT,
            FOREIGN KEY (requestorID) REFERENCES users (userID),
            FOREIGN KEY (userId) REFERENCES users (userID)
        )`);

        // Modify disaster table to accommodate both systems by adding fields from website schema
        db.run(`CREATE TABLE IF NOT EXISTS disaster (
            id TEXT PRIMARY KEY,
            eventID INTEGER,
            title TEXT NOT NULL,
            description TEXT,
            severity TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            expiryTime TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            radius REAL NOT NULL,
            source TEXT,
            type TEXT,
            desc TEXT
        )`);

        // User-alert association table
        db.run(`CREATE TABLE IF NOT EXISTS user_alerts (
            userID TEXT NOT NULL,
            alertID TEXT NOT NULL,
            isActive INTEGER NOT NULL DEFAULT 1,
            PRIMARY KEY (userID, alertID),
            FOREIGN KEY (userID) REFERENCES users (userID),
            FOREIGN KEY (alertID) REFERENCES disaster (id)
        )`);

        // Website's safe location table
        db.run(`CREATE TABLE IF NOT EXISTS safelocation (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            eventID INTEGER NOT NULL,
            safelat REAL NOT NULL,
            safelong REAL NOT NULL,
            type TEXT NOT NULL,
            desc TEXT NOT NULL
        )`);

        console.log('Database tables created');
    });
}app.post('/api/location/update', (req, res) => {
    try {
        const userID = getUserIDFromToken(req);
        const latitude = req.body.latitude;
        const longitude = req.body.longitude;
        const radius = req.body.radius;
        const timestamp = req.body.timestamp;
        const batteryLevel = req.body.batteryLevel;
        
        if (!latitude || !longitude) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        const now = timestamp || new Date().toISOString();
        const userRadius = radius || 100; // Default radius if not provided
        
        // Update user location in the database
        const updateSql = `
            UPDATE users
            SET latitude = ?, longitude = ?, radius = ?, lastUpdate = ?, batteryLevel = ?
            WHERE userID = ?
        `;
        
        db.run(updateSql, [latitude, longitude, userRadius, now, batteryLevel, userID], function(err) {
            if (err) {
                console.error('Error updating location:', err);
            }
            
            if (this.changes === 0) {
                // User doesn't exist yet, create the user
                const insertSql = `
    INSERT INTO users (userID, latitude, longitude, radius, lastUpdate, batteryLevel)
    VALUES (?, ?, ?, ?, ?, ?)
`;

db.run(insertSql, [
    userID,
    latitude, 
    longitude, 
    userRadius, 
    now, 
    batteryLevel
], function(err) {
                    if (err) {
                        console.error('Error creating user with location:', err);
                    }
                    
                    // Check if user is in any disaster zones from website
                    checkForWebsiteDisasters(userID, latitude, longitude);
                    
                    return res.status(200).json({ message: 'Location updated successfully' });
                });
            } else {
                // Check if user is in any disaster zones from website
                checkForWebsiteDisasters(userID, latitude, longitude);
                
                return res.status(200).json({ message: 'Location updated successfully' });
            }
        });
    } catch (e) {
        return res.status(401).json({ error: e.message });
    }
});

// Helper function to extract user ID from token (if not already defined)
function getUserIDFromToken(req) {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
        // If no auth header, use a demo user ID for development/testing
        return req.body.userID || 'demo-user';
    }
    
    try {
        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
        return decoded.userID;
    } catch (e) {
        // If token invalid, fall back to userID in request body
        return req.body.userID || 'demo-user';
    }
}
// Bridge endpoint to handle disaster reports from website
app.post("/report-disaster", (req, res) => {
    const {eventID, latitude, longitude, radius, type, desc} = req.body;

    if (!eventID || !latitude || !longitude || !radius) {
        return res.status(400).json({ error: "eventID, latitude, longitude, and radius are required" });
    }

    // Generate an ID in the format expected by the app
    const id =' disaster-${eventID}-${Date.now()}';
    
    // Current time for timestamp
    const now = new Date();
    // Default expiry time (24 hours from now)
    const expiryTime = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    
    // Map severity based on type (you may need to adjust this mapping)
    const severityMap = {
        'earthquake': 'Critical',
        'flood': 'Critical',
        'fire': 'Critical',
        'storm': 'Warning',
        'other': 'Watch'
    };
    
    const severity = severityMap[type.toLowerCase()] || 'Warning';
    const title =' ${type.charAt(0).toUpperCase() + type.slice(1)} Alert';

    // Insert into disaster table with fields for both systems
    const sql = `
        INSERT INTO disaster (
            id, eventID, title, description, severity, timestamp, expiryTime, 
            latitude, longitude, radius, source, type, desc
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `;
    
    db.run(sql, [
        id, eventID, title, desc, severity, now.toISOString(), expiryTime.toISOString(),
        latitude, longitude, radius, 'WEBSITE', type, desc
    ], function(err) {
        if (err) {
            console.error('Error creating disaster:', err);
            return res.status(500).json({ error: err.message });
        }
        
        // Now check which users are in this disaster zone and update their alerts
        const alertSql = `
            SELECT userID FROM users
            WHERE (
                (latitude BETWEEN ? - (?/111.0) AND ? + (?/111.0))
                AND (longitude BETWEEN ? - (?/(111.0 * COS(RADIANS(latitude)))) 
                     AND ? + (?/(111.0 * COS(RADIANS(latitude)))))
            )
        `;
        
        db.all(alertSql, [
            latitude, radius, latitude, radius,
            longitude, radius, longitude, radius
        ], (err, users) => {
            if (err) {
                console.error('Error finding affected users:', err);
                // Still return success for the disaster creation
            } else if (users.length > 0) {
                // Update user_alerts for affected users
                users.forEach(user => {
                    db.run(
                        'INSERT OR REPLACE INTO user_alerts (userID, alertID, isActive) VALUES (?, ?, 1)',
                        [user.userID, id]
                    );
                });
                console.log('Alert added for ${users.length} affected users');
            }
            
            res.status(201).json({ 
                message: "Disaster recorded successfully",
                id: id,
                affectedUsers: users.length
            });
        });
    });
});

// Bridge endpoint to handle safe location reports from website
app.post("/report-safelocation", (req, res) => {
    const {eventID, safelat, safelong, type, desc} = req.body;

    if (!eventID || !safelat || !safelong || !type || !desc) {
        return res.status(400).json({ error: "eventID, safelat, safelong, type and desc are required" });
    }

    const stmt = db.prepare("INSERT INTO safelocation (eventID, safelat, safelong, type, desc) VALUES (?, ?, ?, ?, ?)");
    stmt.run(eventID, safelat, safelong, type, desc, function(err) {
        if (err) {
            return res.status(500).json({ error: err.message });
        }

        // Make this safe location available to app users
        // Add it to the public API response for the app
        res.status(201).json({ 
            message: "Safe location recorded successfully",
            id: this.lastID
        });
    });
    stmt.finalize();
});

// Add safe locations to the app's alerts endpoint
app.get("/get-alerts", (req, res) => {
    try {
        const userID = getUserIDFromToken(req);
        const { latitude, longitude, radius } = req.query;
        
        if (!latitude || !longitude || !radius) {
            return res.status(400).json({ error: 'Missing required parameters' });
        }
        
        // First get disasters that affect the user
        const disasterSql = `
            SELECT d.id, d.title, d.description, d.severity, d.timestamp, d.expiryTime,
                   d.latitude, d.longitude, d.radius, d.source, d.type
            FROM disaster d
            WHERE (
                (? BETWEEN d.latitude - (d.radius/111.0) AND d.latitude + (d.radius/111.0))
                AND (? BETWEEN d.longitude - (d.radius/(111.0 * COS(RADIANS(?)))) 
                     AND d.longitude + (d.radius/(111.0 * COS(RADIANS(?)))))
            )
            AND datetime(d.expiryTime) > datetime('now')
        `;
        
        db.all(disasterSql, [latitude, longitude, latitude, latitude], (err, disasters) => {
            if (err) {
                console.error('Error fetching alerts:', err);
                return res.status(500).json({ error: 'Failed to fetch alerts' });
            }
            
            // Update user_alerts table for this user
            updateUserAlerts(userID, disasters.map(d => d.id));
            
            // Then get safe locations near these disasters
            if (disasters.length > 0) {
                // Extract event IDs from disasters
                const eventIDs = disasters
                    .map(d => d.eventID)
                    .filter(id => id != null);
                
                if (eventIDs.length > 0) {
                    // Get safe locations for these events
                    const placeholders = eventIDs.map(() => '?').join(',');
                    const safeLocationSql = `
                        SELECT eventID, safelat, safelong, type, desc
                        FROM safelocation
                        WHERE eventID IN (${placeholders})
                    `;
                    
                    db.all(safeLocationSql, eventIDs, (err, safeLocations) => {
                        if (err) {
                            console.error('Error fetching safe locations:', err);
                            // Just return disasters if safe locations fail
                            return res.json({
                                alerts: disasters,
                                safeLocations: []
                            });
                        }
                        
                        // Return both disasters and safe locations
                        res.json({
                            alerts: disasters,
                            safeLocations: safeLocations
                        });
                    });
                } else {
                    // No event IDs found, just return disasters
                    res.json({
                        alerts: disasters,
                        safeLocations: []
                    });
                }
            } else {
                // No disasters, return empty arrays
                res.json({
                    alerts: [],
                    safeLocations: []
                });
            }
        });
    } catch (e) {
        return res.status(401).json({ error: e.message });
    }
});

// Combined endpoint for both systems
app.get("/get-all-disasters", (req, res) => {
    const sql = "SELECT * FROM disaster WHERE datetime(expiryTime) > datetime('now')";
    
    db.all(sql, [], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json(rows);
    });
});

app.get("/get-all-safelocation", (req, res) => {
    const sql = "SELECT * FROM safelocation";
    
    db.all(sql, [], (err, rows) => {
        if (err) {
            return res.status(500).json({ error: err.message });
        }
        res.json(rows);
    });
});
// Combined endpoint for updating location and getting alerts
app.post('/api/location/update-and-get-alerts', (req, res) => {
    try {
        const userID = getUserIDFromToken(req);
        const latitude = res.body.latitude;
        const longitude = res.body.longitude;
        const radius = res.body.radius;
        const batteryLevel = res.body.batteryLevel;
        
        if (!latitude || !longitude || !radius) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        const now = timestamp || new Date().toISOString();
        
        // Update user location in the database
        const updateSql = `
            UPDATE users
            SET latitude = ?, longitude = ?, radius = ?, lastUpdate = ?, batteryLevel = ?
            WHERE userID = ?
        `;
        
        db.run(updateSql, [latitude, longitude, radius, now, batteryLevel, userID], function(err) {
            if (err) {
                console.error('Error updating location:', err);
                return res.status(500).json({ error: 'Failed to update location' });
            }
            
            if (this.changes === 0) {
                // User doesn't exist yet, create the user
                const insertSql = `
                    INSERT INTO users (userID, latitude, longitude, radius, lastUpdate, batteryLevel)
                    VALUES (?, ?, ?, ?, ?, ?)
                `;
                
                db.run(insertSql, [userID, latitude, longitude, radius, now, batteryLevel], function(err) {
                    if (err) {
                        console.error('Error creating user with location:', err);
                        return res.status(500).json({ error: 'Failed to create user with location' });
                    }
                });
            }
            
            // Process filters
            const filterCriteria = filters || {};
            
            // Build query to get relevant alerts
            let alertSql = `
                SELECT d.id, d.eventID, d.title, d.description, d.severity, d.timestamp, d.expiryTime,
                       d.latitude, d.longitude, d.radius, d.source, d.type
                FROM disaster d
                WHERE (
                    (? BETWEEN d.latitude - (d.radius/111.0) AND d.latitude + (d.radius/111.0))
                    AND (? BETWEEN d.longitude - (d.radius/(111.0 * COS(RADIANS(?)))) 
                         AND d.longitude + (d.radius/(111.0 * COS(RADIANS(?)))))
                )
                AND datetime(d.expiryTime) > datetime('now')
            `;
            
            const params = [latitude, longitude, latitude, latitude];
            
            // Add severity filters if provided
            if (filterCriteria.showCritical === false) {
                alertSql += " AND d.severity != 'Critical'";
            }
            if (filterCriteria.showWarning === false) {
                alertSql += " AND d.severity != 'Warning'";
            }
            if (filterCriteria.showWatch === false) {
                alertSql += " AND d.severity != 'Watch'";
            }
            if (filterCriteria.showInfo === false) {
                alertSql += " AND d.severity != 'Info'";
            }
            
            // Add friend alerts if requested
            if (filterCriteria.showFriendsAlerts) {
                alertSql = `
                    ${alertSql}
                    UNION
                    SELECT d.id, d.eventID, d.title, d.description, d.severity, d.timestamp, d.expiryTime,
                           d.latitude, d.longitude, d.radius, d.source, d.type
                    FROM disaster d
                    JOIN user_alerts ua ON d.id = ua.alertID
                    JOIN friends f ON ua.userID = f.userId
                    WHERE f.requestorID = ?
                    AND f.status = 'accepted'
                    AND ua.isActive = 1
                    AND datetime(d.expiryTime) > datetime('now')
                `;
                params.push(userID);
            }
            
            // Execute query to get alerts
            db.all(alertSql, params, (err, alerts) => {
                if (err) {
                    console.error('Error fetching alerts:', err);
                    return res.status(500).json({ error: 'Failed to fetch alerts' });
                }
                
                // Update user_alerts table for this user
                updateUserAlerts(userID, alerts.map(alert => alert.id));
                
                // Get safe locations if there are alerts
                if (alerts.length > 0) {
                    // Extract event IDs
                    const eventIDs = alerts
                        .map(a => a.eventID)
                        .filter(id => id != null);
                    
                    if (eventIDs.length > 0) {
                        // Get related safe locations
                        const placeholders = eventIDs.map(() => '?').join(',');
                        const safeLocationSql = `
                            SELECT eventID, safelat AS latitude, safelong AS longitude, type, desc AS description
                            FROM safelocation 
                            WHERE eventID IN (${placeholders})
                        `;
                        
                        db.all(safeLocationSql, eventIDs, (err, safeLocations) => {
                            if (err) {
                                console.error('Error fetching safe locations:', err);
                                // Return alerts without safe locations
                                return res.json({
                                    alerts: alerts,
                                    safeLocations: []
                                });
                            }
                            
                            // Return both alerts and safe locations
                            res.json({
                                alerts: alerts,
                                safeLocations: safeLocations
                            });
                        });
                    } else {
                        // No event IDs found
                        res.json({
                            alerts: alerts,
                            safeLocations: []
                        });
                    }
                } else {
                    // No alerts
                    res.json({
                        alerts: [],
                        safeLocations: []
                    });
                }
            });
        });
    } catch (e) {
        return res.status(401).json({ error: e.message });
    }
});
// Helper function to check if a user is in any disaster zone from website
function checkForWebsiteDisasters(userID, latitude, longitude) {
    const sql = `
        SELECT d.id, d.eventID
        FROM disaster d
        WHERE (
            (? BETWEEN d.latitude - (d.radius/111.0) AND d.latitude + (d.radius/111.0))
            AND (? BETWEEN d.longitude - (d.radius/(111.0 * COS(RADIANS(?)))) 
                 AND d.longitude + (d.radius/(111.0 * COS(RADIANS(?)))))
        )
        AND d.eventID IS NOT NULL
        AND datetime(d.expiryTime) > datetime('now')
    `;
    
    db.all(sql, [latitude, longitude, latitude, latitude], (err, rows) => {
        if (err) {
            console.error('Error checking for website disasters:', err);
            return;
        }
        
        if (rows.length > 0) {
            console.log('User ${userID} is in ${rows.length} website disaster zones');
            
            // Update user_alerts
            rows.forEach(row => {
                db.run(
                    'INSERT OR REPLACE INTO user_alerts (userID, alertID, isActive) VALUES (?, ?, 1)',
                    [userID, row.id],
                    (err) => {
                        if (err) {
                            console.error('Error updating user_alert for user ${userID} and alert ${row.id}:, err');
                        }
                    }
                );
            });
        }
    });
}

const PORT = 3000;
const HOST = '0.0.0.0';  // Listen on all available network interfaces

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});
