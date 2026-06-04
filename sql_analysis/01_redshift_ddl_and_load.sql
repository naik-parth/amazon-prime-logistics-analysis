-- DDL for Amazon Redshift Serverless
CREATE TABLE dim_fc (
    fc_id VARCHAR(10) PRIMARY KEY,
    location VARCHAR(50),
    automation_level VARCHAR(20)
);

CREATE TABLE dim_carrier (
    carrier_id VARCHAR(10) PRIMARY KEY,
    carrier_name VARCHAR(50)
);

CREATE TABLE fact_orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id INT,
    is_prime BOOLEAN,
    order_value_usd DECIMAL(10,2)
);

CREATE TABLE fact_tracking_logs (
    order_id VARCHAR(20),
    fc_id VARCHAR(10),
    carrier_id VARCHAR(10),
    event_status VARCHAR(50),
    event_timestamp TIMESTAMP
);

-- S3 Ingestion Pipeline (Replace ARN with actual production IAM Role)
COPY dim_fc FROM 's3://amazon-supply-chain-portfolio-data/dim_fc.csv' IAM_ROLE 'arn:aws:iam::[ACCOUNT_ID]:role/[ROLE_NAME]' CSV IGNOREHEADER 1;
COPY dim_carrier FROM 's3://amazon-supply-chain-portfolio-data/dim_carrier.csv' IAM_ROLE 'arn:aws:iam::[ACCOUNT_ID]:role/[ROLE_NAME]' CSV IGNOREHEADER 1;
COPY fact_orders FROM 's3://amazon-supply-chain-portfolio-data/fact_orders.csv' IAM_ROLE 'arn:aws:iam::[ACCOUNT_ID]:role/[ROLE_NAME]' CSV IGNOREHEADER 1;
COPY fact_tracking_logs FROM 's3://amazon-supply-chain-portfolio-data/fact_tracking_logs.csv' IAM_ROLE 'arn:aws:iam::[ACCOUNT_ID]:role/[ROLE_NAME]' FORMAT CSV IGNOREHEADER 1 TIMEFORMAT 'auto';