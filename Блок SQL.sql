CREATE TABLE customer_info (
    Id_client int primary key,
    Total_amount int,
    Gender varchar (20),
    Age int,
    Count_city int,
    Response_communcation int,
	Communication_3month int,
	Tenure int
);

CREATE TABLE transactions_info (
    date_new date,
    Id_check INT,
    ID_client int,
    Count_products DECIMAL(10, 4),
    Sum_payment DECIMAL(10, 4),
    FOREIGN KEY (ID_client) REFERENCES customer_info(Id_client)
);

SELECT * FROM `sql final`.transactions_info;
SELECT * FROM `sql final`.customer_info;

SELECT 
    ci.Id_client,
    ci.Total_amount,
    ci.Gender,
    ci.Age,
    ci.Count_city,
    ci.Response_communcation,
    ci.Communication_3month,
    ci.Tenure,
    ti.date_new,
    ti.Id_check,
    ti.Count_products,
    ti.Sum_payment
FROM 
    `sql final`.customer_info ci
JOIN 
    `sql final`.transactions_info ti ON ci.Id_client = ti.ID_client;
   
   
   # 1  
WITH monthly_purchases AS (
    SELECT 
        ci.Id_client,
        DATE_FORMAT(ti.date_new, '%Y-%m-01') AS month,  -- Получаем первый день месяца
        SUM(ti.Sum_payment) AS monthly_sum,
        COUNT(ti.Id_check) AS operation_count
    FROM 
        `sql final`.customer_info ci
    JOIN 
        `sql final`.transactions_info ti ON ci.Id_client = ti.ID_client
    WHERE 
        ti.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        ci.Id_client, month
),
clients_with_full_history AS (
    SELECT 
        Id_client,
        COUNT(DISTINCT month) AS months_count,
        AVG(monthly_sum) AS avg_monthly_sum,
        SUM(monthly_sum) AS total_sum,
        SUM(operation_count) AS total_operations
    FROM 
        monthly_purchases
    GROUP BY 
        Id_client
    HAVING 
        COUNT(DISTINCT month) = 12  -- Проверяем наличие всех 12 месяцев
)
SELECT 
    ci.Id_client,
    ci.Total_amount,
    ci.Gender,
    ci.Age,
    ci.Count_city,
    ci.Response_communcation,
    ci.Communication_3month,
    ci.Tenure,
    total_sum / 12 AS avg_check,  -- Средний чек за период
    avg_monthly_sum,
    total_operations
FROM 
    clients_with_full_history ch
JOIN 
    `sql final`.customer_info ci ON ch.Id_client = ci.Id_client;
    
# 2
WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(ti.date_new, '%Y-%m-01') AS month,
        ci.Gender,
        SUM(ti.Sum_payment) AS total_sum,
        COUNT(ti.Id_check) AS total_operations,
        COUNT(DISTINCT ti.ID_client) AS unique_clients
    FROM 
        `sql final`.transactions_info ti
    JOIN 
        `sql final`.customer_info ci ON ti.ID_client = ci.Id_client
    WHERE 
        ti.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY 
        month, ci.Gender
),
monthly_summary AS (
    SELECT 
        month,
        AVG(total_sum) AS avg_check,
        AVG(total_operations) AS avg_operations,
        SUM(total_operations) AS total_operations,
        SUM(unique_clients) AS total_clients
    FROM 
        monthly_data
    GROUP BY 
        month
),
gender_summary AS (
    SELECT 
        month,
        Gender,
        SUM(total_sum) AS gender_total_sum,
        SUM(total_operations) AS gender_operations
    FROM 
        monthly_data
    GROUP BY 
        month, Gender
),
overall_summary AS (
    SELECT 
        month,
        SUM(total_operations) AS overall_operations,
        SUM(total_sum) AS overall_sum
    FROM 
        monthly_data
    GROUP BY 
        month
)
SELECT 
    ms.month,
    ms.avg_check,
    ms.avg_operations,
    ms.total_clients,
    ms.total_operations,
    (COALESCE(SUM(CASE WHEN gs.Gender IS NOT NULL THEN gs.gender_operations END), 0) / NULLIF(os.overall_operations, 0)) * 100 AS operations_share,
    (COALESCE(SUM(CASE WHEN gs.Gender IS NOT NULL THEN gs.gender_total_sum END), 0) / NULLIF(os.overall_sum, 0)) * 100 AS sum_share,
    COALESCE(SUM(CASE WHEN gs.Gender = 'M' THEN gs.gender_total_sum END), 0) / NULLIF(SUM(gs.gender_total_sum), 0) * 100 AS male_percentage,
    COALESCE(SUM(CASE WHEN gs.Gender = 'F' THEN gs.gender_total_sum END), 0) / NULLIF(SUM(gs.gender_total_sum), 0) * 100 AS female_percentage,
    COALESCE(SUM(CASE WHEN gs.Gender IS NULL THEN gs.gender_total_sum END), 0) / NULLIF(SUM(gs.gender_total_sum), 0) * 100 AS na_percentage
FROM 
    monthly_summary ms
LEFT JOIN 
    gender_summary gs ON ms.month = gs.month
JOIN 
    overall_summary os ON ms.month = os.month
GROUP BY 
    ms.month, ms.avg_check, ms.avg_operations, ms.total_clients, ms.total_operations;
    
    
# 3 
WITH age_groups AS (
    SELECT 
        CASE 
            WHEN Age IS NULL THEN 'Unknown'
            WHEN Age < 10 THEN '0-9'
            WHEN Age < 20 THEN '10-19'
            WHEN Age < 30 THEN '20-29'
            WHEN Age < 40 THEN '30-39'
            WHEN Age < 50 THEN '40-49'
            WHEN Age < 60 THEN '50-59'
            WHEN Age < 70 THEN '60-69'
            WHEN Age < 80 THEN '70-79'
            WHEN Age < 90 THEN '80-89'
            ELSE '90+' 
        END AS age_group,
        SUM(ti.Sum_payment) AS total_sum,
        COUNT(ti.Id_check) AS total_operations
    FROM 
        `sql final`.transactions_info ti
    JOIN 
        `sql final`.customer_info ci ON ti.ID_client = ci.Id_client
    GROUP BY 
        age_group
),
quarterly_data AS (
    SELECT 
        CONCAT(YEAR(ti.date_new), '-Q', QUARTER(ti.date_new)) AS quarter,
        CASE 
            WHEN ci.Age IS NULL THEN 'Unknown'
            WHEN ci.Age < 10 THEN '0-9'
            WHEN ci.Age < 20 THEN '10-19'
            WHEN ci.Age < 30 THEN '20-29'
            WHEN ci.Age < 40 THEN '30-39'
            WHEN ci.Age < 50 THEN '40-49'
            WHEN ci.Age < 60 THEN '50-59'
            WHEN ci.Age < 70 THEN '60-69'
            WHEN ci.Age < 80 THEN '70-79'
            WHEN ci.Age < 90 THEN '80-89'
            ELSE '90+' 
        END AS age_group,
        SUM(ti.Sum_payment) AS total_sum,
        COUNT(ti.Id_check) AS total_operations
    FROM 
        `sql final`.transactions_info ti
    JOIN 
        `sql final`.customer_info ci ON ti.ID_client = ci.Id_client
    GROUP BY 
        quarter, age_group
)
SELECT 
    ag.age_group,
    SUM(ag.total_sum) AS total_sum,
    SUM(ag.total_operations) AS total_operations,
    AVG(qd.total_sum) AS avg_quarterly_sum,
    AVG(qd.total_operations) AS avg_quarterly_operations,
    COUNT(DISTINCT qd.quarter) AS quarters_count,
    (SUM(ag.total_operations) / NULLIF(SUM(qd.total_operations), 0)) * 100 AS operations_percentage
FROM 
    age_groups ag
LEFT JOIN 
    quarterly_data qd ON ag.age_group = qd.age_group
GROUP BY 
    ag.age_group;
