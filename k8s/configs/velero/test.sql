-- Create test table
CREATE TABLE test_table (
    id SERIAL PRIMARY KEY,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Example insert statements (only need to specify the date column)
-- The id will auto-increment, created_at will default to current timestamp

-- Insert with current timestamp (default)
INSERT INTO test_table (created_at) VALUES (CURRENT_TIMESTAMP);

-- View the data
SELECT * FROM test_table;