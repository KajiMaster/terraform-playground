-- Create contacts table
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO contacts (name, email, phone, created_at) VALUES
    ('John Doe', 'john.doe@example.com', '+1-555-0101', NOW()),
    ('Jane Smith', 'jane.smith@example.com', '+1-555-0102', NOW()),
    ('Bob Johnson', 'bob.johnson@example.com', '+1-555-0103', NOW()),
    ('Alice Brown', 'alice.brown@example.com', '+1-555-0104', NOW()),
    ('Charlie Wilson', 'charlie.wilson@example.com', '+1-555-0105', NOW()); 