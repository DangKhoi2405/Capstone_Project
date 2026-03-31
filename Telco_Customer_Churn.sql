-- 1. Chuẩn Bị Dữ Liệu:
-- Tạo bản copy
SELECT *
INTO telco_customer_churn
FROM [capstone].[dbo].[Telco-Customer-Churn];

-- Xử lý giá trị missing
UPDATE telco_customer_churn
SET TotalCharges = '0'
WHERE TotalCharges = '' OR TotalCharges IS NULL;

-- Chuyển đổi cột SeniorCitizen sang Yes/No
ALTER TABLE telco_customer_churn
ALTER COLUMN SeniorCitizen VARCHAR(5);
UPDATE telco_customer_churn
SET SeniorCitizen = 
CASE
    WHEN SeniorCitizen = 1 THEN 'Yes'
    ELSE 'No'
END;

-- Loại bỏ duplicates 
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY customerID
               ORDER BY (SELECT NULL)  
           ) as row_num
    FROM telco_customer_churn
    )
DELETE FROM duplicates
WHERE row_num > 1;

-- Tạo cột Tenure Group
ALTER TABLE telco_customer_churn 
ADD TenureGroup VARCHAR(20);

UPDATE telco_customer_churn
SET TenureGroup = 
    CASE
        when tenure < 12 then '<12 tháng'
        when tenure between 12 and 36 then '12-36 tháng'
        else '>36 thang'
    END;

-- Tạo cột Total Services
ALTER TABLE telco_customer_churn
ADD TotalServices INT;

UPDATE telco_customer_churn
SET TotalServices = (
    CASE WHEN PhoneService     = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN MultipleLines    = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN InternetService  NOT IN ('No') THEN 1 ELSE 0 END +
    CASE WHEN OnlineSecurity   = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN OnlineBackup     = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN DeviceProtection = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN TechSupport      = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN StreamingTV      = 'Yes' THEN 1 ELSE 0 END +
    CASE WHEN StreamingMovies  = 'Yes' THEN 1 ELSE 0 END
);

-- 2. Khám Phá Dữ Liệu:
--  Churn Rate tổng
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS total_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS churn_rate
FROM telco_customer_churn;

-- Churn Rate theo InternetService
SELECT
    InternetService,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS total_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS churn_rate
FROM telco_customer_churn
GROUP BY InternetService

-- Trung bình Tenure theo InternetService
SELECT
    InternetService,
    ROUND(AVG(tenure), 2) AS avg_tenure 
FROM telco_customer_churn
GROUP BY InternetService;

-- Mối quan hệ OnlineSecurity vs Churn
SELECT
    OnlineSecurity,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS total_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS churn_rate
FROM telco_customer_churn
GROUP BY OnlineSecurity

-- phân bố theo Gender 
SELECT 
    gender,
    COUNT(*) as total,
    SUM(CASE WHEN Churn = 'Yes' Then 1 ELSE 0 END) AS total_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS churn_rate
FROM telco_customer_churn
GROUP BY gender




