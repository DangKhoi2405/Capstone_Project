-- 1. Chuẩn Bị Dữ Liệu:
-- Tạo bản copy
SELECT *
INTO hr_dashboard_data
FROM [capstone].[dbo].[hr-dashboard-data]

-- Chuyển Joining Date sang date
ALTER TABLE hr_dashboard_data 
ADD Date_Of_Joining DATE;

UPDATE hr_dashboard_data
SET Date_Of_Joining = CAST('01-' + "Joining_Date" AS DATE);


-- Xử lý missing ở Salary
UPDATE hr_dashboard_data
SET "Salary" = (SELECT AVG("Salary") FROM hr_dashboard_data WHERE "Salary" IS NOT NULL)
WHERE "Salary" IS NULL;

-- loại bỏ duplicates dựa trên Name.
WITH duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY Name
               ORDER BY (SELECT NULL)  
           ) as row_num
    FROM hr_dashboard_data
    )
DELETE FROM duplicates
WHERE row_num > 1;

-- Tạo cột Experience Years
ALTER TABLE hr_dashboard_data 
ADD Experience_Years INT;

UPDATE hr_dashboard_data
SET "Experience_Years" = YEAR(GETDATE()) - YEAR(Date_Of_joining);

-- Tạo cột Productivity Group
ALTER TABLE hr_dashboard_data
ADD Productivity_Group VARCHAR(20);

UPDATE hr_dashboard_data
SET Productivity_Group = 
    CASE
        when Productivity < 50 then 'Low'
        when Productivity between 50 and 80 then 'Medium'
        else 'High'
    END;

-- 2. Khám Phá Dữ Liệu:
-- Trung bình Productivity theo Department
SELECT
    Department,
    ROUND(AVG(Productivity), 0) AS Avg_Productivity
FROM hr_dashboard_data
GROUP BY Department
ORDER BY Avg_Productivity

-- Tương quan giữa Satisfaction Rate và Feedback Score
ALTER TABLE hr_dashboard_data
ALTER COLUMN Satisfaction_Rate INT;
ALTER TABLE hr_dashboard_data
ALTER COLUMN Feedback_Score FLOAT;
SELECT
    ROUND(
      (SUM(Satisfaction_Rate * Feedback_Score) -
       COUNT(*) * AVG(Satisfaction_Rate) * AVG(Feedback_Score))
      /
      (SQRT(
         SUM(Satisfaction_Rate * Satisfaction_Rate) -
         COUNT(*) * AVG(Satisfaction_Rate) * AVG(Satisfaction_Rate))
       *
       SQRT(
         SUM(Feedback_Score * Feedback_Score) -
         COUNT(*) * AVG(Feedback_Score) * AVG(Feedback_Score))
      ), 4) AS Pearson_Corr_Satisfaction_Feedback
FROM hr_dashboard_data;

-- Mối liên hệ giữa Age và Projects Completed, phân bố theo Gender hoặc Position.
SELECT
    Position,
    ROUND(AVG(Age), 1)                AS Avg_Age,
    ROUND(AVG(Projects_Completed), 1) AS Avg_Projects,
    COUNT(*)                          AS Total
FROM hr_dashboard_data
GROUP BY Position
ORDER BY Position;


-- 4. Insights
-- Hệ số tương quan giữa Salary và Satisfaction Rate
ALTER TABLE hr_dashboard_data
ALTER COLUMN Satisfaction_Rate INT;
ALTER TABLE hr_dashboard_data
ALTER COLUMN Salary FLOAT;
SELECT
    ROUND(
      (SUM(Satisfaction_Rate * Salary) -
       COUNT(*) * AVG(Satisfaction_Rate) * AVG(Salary))
      /
      (SQRT(
         SUM(Satisfaction_Rate * Satisfaction_Rate) -
         COUNT(*) * AVG(Satisfaction_Rate) * AVG(Satisfaction_Rate))
       *
       SQRT(
         SUM(Salary * Salary) -
         COUNT(*) * AVG(Salary) * AVG(Salary))
      ), 4) AS Pearson_Corr_Satisfaction_Salary
FROM hr_dashboard_data;