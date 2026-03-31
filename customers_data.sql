-- 1. Chuẩn Bị Dữ Liệu:
-- Tạo bản copy
SELECT *
INTO customers_data
FROM [capstone].[dbo].[Customers]

-- Xử lý missing ở Profession
UPDATE customers_data
SET Profession = 'Unknown'
WHERE Profession = '' OR Profession IS NULL;

-- Loại bỏ duplicates 
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY customerID
               ORDER BY (SELECT NULL)  
           ) as row_num
    FROM customers_data
    )
DELETE FROM duplicates
WHERE row_num > 1;

-- Xử lý outliers ở Annual Income.
WITH Stats AS (
    SELECT 
        AVG(Annual_Income) AS mean_income,
        STDEV(Annual_Income) AS std_income
    FROM customers_data
)
DELETE FROM customers_data
WHERE ABS(Annual_Income - (SELECT mean_income FROM Stats)) 
      > 3 * (SELECT std_income FROM Stats);

-- Tạo cột Income Group
ALTER TABLE customers_data
ADD Income_Group VARCHAR(20);

UPDATE customers_data
SET Income_Group = 
    CASE
        WHEN Annual_Income < 50000 THEN 'Low'
        WHEN Annual_Income BETWEEN 50000 AND 100000 THEN 'Medium'
        ELSE 'High'
    END;

-- Tạo cột Spending Category
ALTER TABLE customers_data
ADD Spending_Category VARCHAR(20);

UPDATE customers_data
SET Spending_Category = 
    CASE
        WHEN Spending_Score < 33 THEN 'Low Performer'
        WHEN Spending_Score BETWEEN 33 AND 66 THEN 'Mid Performer'
        ELSE 'High Performer'
    END;

-- 2. Khám Phá Dữ Liệu:
-- Trung bình Spending Score theo Age 
SELECT 
    Age,
    ROUND(AVG(Spending_Score), 2) AS Avg_Spending_Score
FROM customers_data
GROUP BY Age
ORDER BY Age

--Tỷ lệ theo Family Size
SELECT 
    Family_Size,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Customers) AS Ratio
FROM customers_data
GROUP BY  Family_Size
ORDER BY  Family_Size;

-- Mối quan hệ giữa Work Experience và Annual Income
SELECT
    Work_Experience,
    ROUND(AVG(Annual_Income), 2) AS Avg_Annual_Income
FROM customers_data
GROUP BY Work_Experience
ORDER BY Work_Experience;

-- Clustering cơ bản cho phân khúc 
WITH RawClustering AS (
SELECT *,
    CASE
        WHEN Income_Group = 'High' AND Spending_Category = 'High Performer' THEN 'High Income - High Spending'
        WHEN Income_Group = 'High' AND Spending_Category = 'Mid Performer' THEN 'High Income - Mid Spending'
        WHEN Income_Group = 'High' AND Spending_Category = 'Low Performer' THEN 'High Income - Low Spending'
        WHEN Income_Group = 'Medium' AND Spending_Category = 'High Performer' THEN 'Medium Income - High Spending'
        WHEN Income_Group = 'Medium' AND Spending_Category = 'Mid Performer' THEN 'Medium Income - Mid Spending'
        WHEN Income_Group = 'Medium' AND Spending_Category = 'Low Performer' THEN 'Medium Income - Low Spending'
        WHEN Income_Group = 'Low' AND Spending_Category = 'High Performer' THEN 'Low Income - High Spending'
        WHEN Income_Group = 'Low' AND Spending_Category = 'Mid Performer' THEN 'Low Income - Mid Spending'
        ELSE 'Low Income - Low Spending'
    END AS Clustering
FROM customers_data)
SELECT 
    Clustering,
    ROUND(AVG(Annual_Income), 0) AS Avg_Annual_Income,
    ROUND(AVG(Spending_Score), 2) AS Avg_Spending_Score,
    COUNT(*) AS Total
FROM RawClustering
GROUP BY Clustering
ORDER BY Total DESC




