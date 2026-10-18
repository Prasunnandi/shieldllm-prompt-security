-- ShieldLLM: SQL Analytics for Security Gateway

CREATE SCHEMA IF NOT EXISTS shieldllm;
USE shieldllm;

-- Create table for Prompt Logs
CREATE TABLE IF NOT EXISTS prompt_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id VARCHAR(50),
    ip_address VARCHAR(50),
    timestamp DATETIME,
    prompt_text TEXT,
    is_injection INT,         -- 1 if flagged as attack, 0 if safe
    risk_score DECIMAL(5,4)   -- NN output probability
);

-- Note: Assume prompt_security_dataset.csv is imported here.

-- 1. Total Prompts Processed vs Total Attacks Blocked
SELECT 
    COUNT(*) AS total_prompts,
    SUM(is_injection) AS total_attacks_blocked,
    (SUM(is_injection) * 100.0 / COUNT(*)) AS attack_percentage
FROM prompt_logs;

-- 2. Identify Top 10 Malicious IP Addresses (Attackers)
SELECT 
    ip_address,
    COUNT(*) AS total_requests,
    SUM(is_injection) AS malicious_requests
FROM prompt_logs
GROUP BY ip_address
HAVING malicious_requests > 0
ORDER BY malicious_requests DESC
LIMIT 10;

-- 3. Daily Attack Trends (Are attacks increasing over time?)
SELECT 
    DATE(timestamp) AS attack_date,
    COUNT(*) AS total_requests,
    SUM(is_injection) AS total_attacks
FROM prompt_logs
GROUP BY attack_date
ORDER BY attack_date;

-- 4. Identify Users with Suspicious Activity (Users triggering both safe and injection prompts)
SELECT 
    user_id,
    COUNT(*) AS total_prompts,
    SUM(is_injection) AS attack_attempts,
    (SUM(is_injection) * 100.0 / COUNT(*)) AS attack_ratio
FROM prompt_logs
GROUP BY user_id
HAVING attack_attempts > 5 AND attack_ratio BETWEEN 10.0 AND 90.0
ORDER BY attack_attempts DESC;

-- 5. Find High-Confidence Attacks
SELECT timestamp, ip_address, prompt_text, risk_score
FROM prompt_logs
WHERE is_injection = 1 AND risk_score > 0.95
ORDER BY risk_score DESC
LIMIT 20;
