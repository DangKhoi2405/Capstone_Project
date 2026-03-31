-- 1. Chuẩn Bị Dữ Liệu:
-- Tạo bản copy
SELECT *
INTO bank_customer_churn
FROM [dbo].[Bank-Customer-churn]

-- Kiểm tra missing
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN CustomerId    IS NULL THEN 1 ELSE 0 END) AS null_CustomerId,
    SUM(CASE WHEN CreditScore   IS NULL THEN 1 ELSE 0 END) AS null_CreditScore,
    SUM(CASE WHEN Age           IS NULL THEN 1 ELSE 0 END) AS null_Age,
    SUM(CASE WHEN Balance       IS NULL THEN 1 ELSE 0 END) AS null_Balance,
    SUM(CASE WHEN Exited        IS NULL THEN 1 ELSE 0 END) AS null_Exited
FROM bank_customer_churn;

-- Loại bỏ duplicates 
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY CustomerID
               ORDER BY (SELECT NULL)  
           ) as row_num
    FROM bank_customer_churn
    )
DELETE FROM duplicates
WHERE row_num > 1;

-- Tạo cột Age Group
ALTER TABLE bank_customer_churn
ADD AgeGroup VARCHAR(10);

UPDATE bank_customer_churn
SET AgeGroup = 
    CASE
        WHEN Age < 30              THEN '<30'
        WHEN Age BETWEEN 30 AND 44 THEN '30-44'
        WHEN Age BETWEEN 45 AND 59 THEN '45-59'
    ELSE '60+'
END;

-- Tạo cột Balance Category
ALTER TABLE bank_customer_churn
ADD BalanceCategory VARCHAR(10);

UPDATE bank_customer_churn
SET BalanceCategory = 
    CASE 
        WHEN Balance < 50000                  THEN 'Low'
        when Balance BETWEEN 50000 AND 100000 THEN 'Medium'
    ELSE 'High'
END;

-- 2. Khám Phá Dữ Liệu:
--  Churn Rate tổng
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END)/COUNT(*), 2) AS churn_rate
FROM bank_customer_churn;

-- Churn Rate theo Geography
SELECT 
    Geography,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END)/COUNT(*), 2) AS churn_rate
FROM bank_customer_churn
GROUP BY Geography

-- Trung bình CreditScore theo NumOfProducts
SELECT 
    NumOfProducts,
    ROUND(AVG(CreditScore), 2) AS Avg_CreditScore
FROM bank_customer_churn
GROUP BY NumOfProducts
ORDER BY NumOfProducts

--  Mối quan hệ giữa Tenure và churn
SELECT
    Tenure,
    COUNT(*) AS total,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS total_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS churn_rate
FROM bank_customer_churn
GROUP BY Tenure
ORDER BY Tenure

--  Phân bố theo Surname
SELECT
    Surname,
    COUNT(*) AS total,
    SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Exited = 1 THEN 1 ELSE 0 END)/ COUNT(*), 2) AS churn_rate_pct
FROM bank_customer_churn
GROUP BY Surname
HAVING COUNT(*) >= 5
ORDER BY total DESC

-- 4.
-- Age ảnh hưởng như thế nào đến
Balance
ALTER TABLE bank_customer_churn
ALTER COLUMN Age INT;
ALTER TABLE bank_customer_churn
ALTER COLUMN Balance FLOAT;
SELECT
    ROUND(
      (SUM(Age * Balance) -
       COUNT(*) * AVG(Age) * AVG(Balance))
      /
      (SQRT(
         SUM(Age * Age) -
         COUNT(*) * AVG(Age) * AVG(Age))
       *
       SQRT(
         SUM(Balance * Balance) -
         COUNT(*) * AVG(Balance) * AVG(Balance))
      ), 4) AS Pearson_Corr_Satisfaction_Salary
FROM bank_customer_churn;

