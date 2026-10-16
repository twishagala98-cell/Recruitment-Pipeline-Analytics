LEAD()
-- ==============================================================================
-- PROJECT 1: RECRUITMENT BOTTLENECK & CANDIDATE JOURNEY ANALYTICS ENGINE
-- RDBMS: SQLite
-- Description: Models chronological pipeline logs to isolate operational drag.
-- ==============================================================================

-- STEP 1: Clear existing database views to ensure schema parity.
DROP VIEW IF EXISTS view_candidate_journey;

-- STEP 2: Construct the Master Candidate Journey Analytics View.
CREATE VIEW view_candidate_journey AS
WITH RankedEvents AS (
    SELECT
        "Candidate ID" AS candidate_id,
        "Stage" AS stage,
        "Event Date" AS event_date,
        "Event Status" AS event_status,
        -- Fetch the next chronological pipeline stage for the applicant
        LEAD("Stage") OVER (
            PARTITION BY "Candidate ID" 
            ORDER BY "Event Date"
        ) AS next_stage,
        -- Fetch the timestamp of the next pipeline phase
        LEAD("Event Date") OVER (
            PARTITION BY "Candidate ID" 
            ORDER BY "Event Date"
        ) AS next_event_date
    FROM StageEvents
)
SELECT
    re.candidate_id,
    c."Vacancy ID" AS vacancy_id,
    c."Source" AS sourcing_channel,
    v.Department AS department,
    v."Role Family" AS role_family,
    re.stage,
    re.next_stage,
    re.event_date,
    re.next_event_date,
    -- Compute true chronological day delta intervals on the fly
    CAST(JULIANDAY(re.next_event_date) - JULIANDAY(re.event_date) AS INT) AS days_to_next_stage,
    c."Final Outcome" AS final_outcome
FROM RankedEvents re
JOIN Candidates c ON re.candidate_id = c."Candidate ID"
JOIN Vacancies v ON c."Vacancy ID" = v."Vacancy ID"
WHERE re.next_event_date IS NOT NULL;


-- ==============================================================================
-- EXECUTIVE SUMMARY & REPORT GENERATION QUERIES
-- ==============================================================================

-- AUDIT Q1: Stage Bottleneck Matrix & Service Level Agreement (SLA) Gap Analysis
SELECT 
    vj.stage AS Stage_Name,
    COUNT(DISTINCT vj.candidate_id) AS Total_Unique_Candidates,
    ROUND(AVG(vj.days_to_next_stage), 1) AS Actual_Avg_Days,
    st."Expected Turnaround Days" AS Target_SLA_Days,
    ROUND(AVG(vj.days_to_next_stage) - st."Expected Turnaround Days", 1) AS Days_Over_Target
FROM view_candidate_journey vj
JOIN StageTargets st ON vj.stage = st."Stage Name"
GROUP BY vj.stage, st."Expected Turnaround Days"
ORDER BY Days_Over_Target DESC;


-- AUDIT Q2: Vacancy Operational Resource Drain Deep-Dive (Top 10 High Exposure Roles)
SELECT 
    vj.vacancy_id AS Vacancy_ID,
    vj.department AS Department,
    vj.role_family AS Role_Family,
    COUNT(DISTINCT vj.candidate_id) AS Total_Applicants,
    SUM(vj.days_to_next_stage) AS Total_Days_Invested,
    ROUND(AVG(vj.days_to_next_stage), 1) AS Avg_Days_Per_Stage
FROM view_candidate_journey vj
GROUP BY vj.vacancy_id, vj.department, vj.role_family
ORDER BY Total_Days_Invested DESC
LIMIT 10;


-- AUDIT Q3: Funnel Dropout, Attrition, and Candidate Leakage Metrics
SELECT 
    "Stage" AS Leakage_Point_Stage, 
    "Event Status" AS Candidate_Outcome, 
    COUNT(*) AS Absolute_Count 
FROM StageEvents 
WHERE "Event Status" IN ('Rejected', 'Withdrawn') 
GROUP BY "Stage", "Event Status"
ORDER BY Absolute_Count DESC;


-- AUDIT Q4: Total Velocity Matrix for Successfully Hired Profiles (Time-to-Hire)
SELECT 
    candidate_id AS Candidate_ID,
    department AS Department,
    role_family AS Role_Family,
    sourcing_channel AS Acquisition_Channel,
    MIN(event_date) AS Application_Received_Date, 
    MAX(event_date) AS Start_Date_Confirmed,
    CAST(JULIANDAY(MAX(event_date)) - JULIANDAY(MIN(event_date)) AS INT) AS Total_Days_To_Hire
FROM view_candidate_journey
WHERE final_outcome = 'Hired'
GROUP BY candidate_id, department, role_family, sourcing_channel
ORDER BY Total_Days_To_Hire ASC;
