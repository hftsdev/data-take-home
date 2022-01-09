/* Average transaction value overall */
SELECT ROUND(AVG(amount), 2) AS amount FROM transactions

/* Average transaction value by user */
SELECT user_id, ROUND(AVG(amount), 2) as amount FROM transactions GROUP BY user_id ORDER BY 1

/* Report showing number of days a user spent per week */
SELECT user_id, week_of_year, COUNT(DISTINCT day_of_week) FROM transactions_full GROUP BY user_id, week_of_year ORDER BY 1

/* Top 10 spenders overall */
SELECT user_id, CAST(SUM(amount) AS DECIMAL(38,2)) AS amount FROM transactions GROUP BY user_id ORDER BY 2 DESC LIMIT 10;

/* Bottom 10 spenders overall */
SELECT user_id, CAST(SUM(amount) AS DECIMAL(38,2)) AS amount FROM transactions GROUP BY user_id ORDER BY 2 ASC LIMIT 10;

/* Monthly Spend per User */
SELECT	d.month_name,
		t.user_id,
		ROUND(SUM(t.amount), 2) AS total_amount

FROM 	transactions AS t

JOIN 	dim_date AS d
ON 		d.date_key = CAST(DATE(t.created_at) AS SIGNED)

GROUP BY d.month_name, t.user_id

ORDER BY d.month_of_year ASC, t.user_id ASC;

/* Adding Date Dimension to transactions */
CREATE OR REPLACE VIEW transactions_full AS 
SELECT *, HOUR(t.created_at) AS hour_num 
FROM transactions AS t 
JOIN dim_date AS d 
ON d.date_key = CAST(DATE(t.created_at) AS SIGNED)

CREATE OR REPLACE VIEW change_in_spend AS
SELECT 	month_name,
		user_id,
		amount,
		LAG(amount) OVER(ORDER BY month_of_year) AS prev_amount,
		CAST((amount - LAG(amount) OVER(ORDER BY month_of_year)) / LAG(amount) OVER(ORDER BY month_of_year) * 100 AS DECIMAL(38,2)) AS percent_change
FROM 	(
			SELECT 	month_of_year,
					month_name,
					user_id,
					CAST(SUM(amount) AS DECIMAL(38,2)) AS amount
			FROM	transactions_full
			GROUP BY month_of_year, month_name, user_id
) AS t


SELECT * FROM change_in_spend WHERE percent_change >= 0
SELECT * FROM change_in_spend WHERE percent_change < 0


/* Data model built to support linear regression prediction */
CREATE OR REPLACE VIEW users_spend AS
SELECT 	dd.user_id,
		dd.month,
		tf.amount AS amount
FROM (
	SELECT	*
	FROM	(
		SELECT DISTINCT user_id AS user_id FROM transactions_full WHERE month_of_year != 1
	) AS t
	CROSS JOIN (
		SELECT '2021-11-01' AS month
		UNION ALL
		SELECT '2021-12-01'
	) AS m
) AS dd
LEFT JOIN (
	SELECT 	user_id,
			DATE_FORMAT(full_date, '%Y-%m-01') as month,
			SUM(amount) AS amount
	FROM transactions_full 
	WHERE month_of_year != 1
	GROUP BY user_id, DATE_FORMAT(full_date, '%Y-%m-01')
) AS tf
ON dd.user_id = tf.user_id
AND dd.month = tf.month
WHERE tf.amount IS NOT NULL
ORDER BY 1, 2 ASC



/* Date Dimension table build out and population */

CREATE TABLE IF NOT EXISTS dim_date(
 date_key int NOT NULL,
 full_date date NULL,
 date_name char(11) NOT NULL,
 date_name_us char(11) NOT NULL,
 date_name_eu char(11) NOT NULL,
 day_of_week tinyint NOT NULL,
 day_name_of_week char(10) NOT NULL,
 day_of_month tinyint NOT NULL,
 day_of_year smallint NOT NULL,
 weekday_weekend char(10) NOT NULL,
 week_of_year tinyint NOT NULL,
 month_name char(10) NOT NULL,
 month_of_year tinyint NOT NULL,
 is_last_day_of_month char(1) NOT NULL,
 calendar_quarter tinyint NOT NULL,
 calendar_year smallint NOT NULL,
 calendar_year_month char(10) NOT NULL,
 calendar_year_qtr char(10) NOT NULL,
 fiscal_month_of_year tinyint NOT NULL,
 fiscal_quarter tinyint NOT NULL,
 fiscal_year int NOT NULL,
 fiscal_year_month char(10) NOT NULL,
 fiscal_year_qtr char(10) NOT NULL,
  PRIMARY KEY (`date_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE PROCEDURE PopulateDateDimension(BeginDate DATETIME, EndDate DATETIME)
BEGIN

 DECLARE LastDayOfMon CHAR(1);

 DECLARE FiscalYearMonthsOffset INT;

 DECLARE DateCounter DATETIME;
 DECLARE FiscalCounter DATETIME;

 SET FiscalYearMonthsOffset = 0;

 SET DateCounter = BeginDate;

 WHILE DateCounter <= EndDate DO
 
            SET FiscalCounter = DATE_ADD(DateCounter, INTERVAL FiscalYearMonthsOffset MONTH);

            IF MONTH(DateCounter) = MONTH(DATE_ADD(DateCounter, INTERVAL 1 DAY)) THEN
               SET LastDayOfMon = 'N';
            ELSE
               SET LastDayOfMon = 'Y';
   END IF;

            INSERT  INTO dim_date
       (date_key
       ,full_date
       ,date_name
       ,date_name_us
       ,date_name_eu
       ,day_of_week
       ,day_name_of_week
       ,day_of_month
       ,day_of_year
       ,weekday_weekend
       ,week_of_year
       ,month_name
       ,month_of_year
       ,is_last_day_of_month
       ,calendar_quarter
       ,calendar_year
       ,calendar_year_month
       ,calendar_year_qtr
       ,fiscal_month_of_year
       ,fiscal_quarter
       ,fiscal_year
       ,fiscal_year_month
       ,fiscal_year_qtr)
            VALUES  (
                      ( YEAR(DateCounter) * 10000 ) + ( MONTH(DateCounter)
                                                         * 100 )
                      + DAY(DateCounter)  #DateKey
                    , DateCounter # FullDate
                    , CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'/',DATE_FORMAT(DateCounter,'%m'),'/',DATE_FORMAT(DateCounter,'%d')) #DateName
                    , CONCAT(DATE_FORMAT(DateCounter,'%m'),'/',DATE_FORMAT(DateCounter,'%d'),'/',CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameUS
                    , CONCAT(DATE_FORMAT(DateCounter,'%d'),'/',DATE_FORMAT(DateCounter,'%m'),'/',CAST(YEAR(DateCounter) AS CHAR(4)))#DateNameEU
                    , DAYOFWEEK(DateCounter) #DayOfWeek
                    , DAYNAME(DateCounter) #DayNameOfWeek
                    , DAYOFMONTH(DateCounter) #DayOfMonth
                    , DAYOFYEAR(DateCounter) #DayOfYear
                    , CASE DAYNAME(DateCounter)
                        WHEN 'Saturday' THEN 'Weekend'
                        WHEN 'Sunday' THEN 'Weekend'
                        ELSE 'Weekday'
                      END #WeekdayWeekend
                    , WEEKOFYEAR(DateCounter) #WeekOfYear
                    , MONTHNAME(DateCounter) #MonthName
                    , MONTH(DateCounter) #MonthOfYear
                    , LastDayOfMon #IsLastDayOfMonth
                    , QUARTER(DateCounter) #CalendarQuarter
                    , YEAR(DateCounter) #CalendarYear
                    , CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'-',DATE_FORMAT(DateCounter,'%m')) #CalendarYearMonth
                    , CONCAT(CAST(YEAR(DateCounter) AS CHAR(4)),'Q',QUARTER(DateCounter)) #CalendarYearQtr
                    , MONTH(FiscalCounter) #[FiscalMonthOfYear]
                    , QUARTER(FiscalCounter) #[FiscalQuarter]
                    , YEAR(FiscalCounter) #[FiscalYear]
                    , CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'-',DATE_FORMAT(FiscalCounter,'%m')) #[FiscalYearMonth]
                    , CONCAT(CAST(YEAR(FiscalCounter) AS CHAR(4)),'Q',QUARTER(FiscalCounter)) #[FiscalYearQtr]
                    );
            SET DateCounter = DATE_ADD(DateCounter, INTERVAL 1 DAY);
      END WHILE;

END

CALL PopulateDateDimension('2010-01-01', '2029-12-31');
