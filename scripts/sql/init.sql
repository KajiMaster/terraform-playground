-- Create contacts table
CREATE TABLE IF NOT EXISTS contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert initial data (only if table is empty)
INSERT INTO contacts (name, address, phone)
SELECT 'John Doe', '123 Main St, City, State', '555-0101'
WHERE NOT EXISTS (SELECT 1 FROM contacts LIMIT 1);

INSERT INTO contacts (name, address, phone)
SELECT 'Jane Smith', '456 Oak Ave, Town, State', '555-0102'
WHERE NOT EXISTS (SELECT 1 FROM contacts LIMIT 1);

INSERT INTO contacts (name, address, phone)
SELECT 'Bob Johnson', '789 Pine Rd, Village, State', '555-0103'
WHERE NOT EXISTS (SELECT 1 FROM contacts LIMIT 1);

INSERT INTO contacts (name, address, phone)
SELECT 'Alice Brown', '321 Elm St, City, State', '555-0104'
WHERE NOT EXISTS (SELECT 1 FROM contacts LIMIT 1);

INSERT INTO contacts (name, address, phone)
SELECT 'Charlie Wilson', '654 Maple Dr, Town, State', '555-0105'
WHERE NOT EXISTS (SELECT 1 FROM contacts LIMIT 1); 