# Recruitment-Pipeline-Analytics
People Analytics project using SQL and Tableau to identify recruitment bottlenecks.
# 📊 Recruitment Pipeline Velocity & Candidate Journey Diagnostic
**Domain:** People Analytics / Human Resources (HR) Business Intelligence  
**Tech Stack:** SQLite, SQL Window Functions (`LEAD`), Tableau Desktop, Markdown  
**Project Impact:** Isolated a 100% processing delay (+3 Days) causing 25 candidate withdrawals in business-critical pipelines.

---

## 🚀 Executive Project Overview
In a highly competitive, candidate-driven talent market, hiring velocity is an acute strategic differentiator. Every day a critical vacancy sits unfilled—or an applicant stalls in administrative latency—creates an exposure window for a competing organization to poach top talent. 

This end-to-end analytics project models **40 core candidate lifecycles** to evaluate processing speed, track compliance against corporate **Expected Turnaround Days (SLAs)**, and provide prescriptive operational recommendations for executive leadership.

### 📈 Core Diagnostic Console (Tableau Dashboard)
![Recruitment Diagnostics Dashboard](Visualizations/recruitment_diagnostic_dashboard.png)
*Figure 1.0: Full-scale executive dashboard canvas detailing pipeline friction, vacancy resource drains, and funnel dropout matrices.*

---

## 🛠️ Data Architecture & SQL Pipeline Engine
To track candidate journeys across sequential processing phases without modifying raw backend table schemas, a permanent **Database View** was engineered in SQLite. 

The pipeline utilizes chronological event sequencing via the `LEAD()` window function and `JULIANDAY` date arithmetic to dynamically isolate candidate movement intervals:

```sql
DROP VIEW IF EXISTS view_candidate_journey;
CREATE VIEW view_candidate_journey AS
WITH RankedEvents AS (
    SELECT
        "Candidate ID" AS candidate_id,
        "Stage" AS stage,
        "Event Date" AS event_date,
        "Event Status" AS event_status,
        LEAD("Stage") OVER (
            PARTITION BY "Candidate ID" 
            ORDER BY "Event Date"
        ) AS next_stage,
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
    CAST(JULIANDAY(re.next_event_date) - JULIANDAY(re.event_date) AS INT) AS days_to_next_stage,
    c."Final Outcome" AS final_outcome
FROM RankedEvents re
JOIN Candidates c ON re.candidate_id = c."Candidate ID"
JOIN Vacancies v ON c."Vacancy ID" = v."Vacancy ID"
WHERE re.next_event_date IS NOT NULL;
```

---

## 🔍 Key Findings & Strategic Insights

### 1. The Operational Wall (The Offer Bottleneck)
While early funnel processing steps like shortlisting and interviewing match business expectations perfectly, the **Offer** stage represents an acute workflow exception. It averages **6.0 days against a tight 3.0-day target line**, representing a **100% latency deficit**.

### 2. Candidate Attrition & Leakage Analysis
The 3-day offer lag isn't just an administrative inconvenience—it is actively destroying pipeline yield. Funnel analysis reveals a severe attrition spike: **25 distinct candidate withdrawals occur strictly during the Offer stage**. Candidates are walking away because of processing silence.

### 3. High-Exposure Pipelines (Children's Social Care)
Vacancies under **Children's Social Care** (specifically for Social Workers and Senior Social Workers) represent the largest absolute resource sink in the dataset. Vacancy `V025` leads organizational drag with **166.0 cumulative processing days**, signaling a critical need for targeted process routing in scarcity talent domains.

---

## 👔 Advisor Operational Action Plan

To transition these diagnostic findings into immediate organizational improvements, the recruitment function has established three targeted operational interventions:

*   **Action 1: Implement Automated 48-Hour SLA Triggers**  
    Deploy an automated system flag that alerts the recruitment desk the moment a candidate's profile sits in the "Offer" phase for longer than 48 hours without an issued contract, allowing for proactive internal escalation.
*   **Action 2: Front-Load Compliance Frameworks**  
    For high-priority, high-scarcity municipal roles, decouple references and background validation checks from the post-offer phase. Move these tracking mechanisms directly into the active interview loops to compress lagging timelines.
*   **Action 3: Single-Signature Authorization Models**  
    Present the Tableau SLA Gap chart to executive leadership to secure a mandate for a streamlined, digital single-sign-off authorization matrix specifically for business-critical talent categories.

---

## 🔮 Roadmap for Continuous Improvement
To scale this data model to enterprise-grade maturity, future development phases will target:
1.  **Calendar Days vs. Working Days Transition:** Modifying the SQLite data logic to utilize a calendar dimensional lookup array, filtering out weekends and public bank holidays to prevent processing metrics from being artificially inflated by weekend extensions.
2.  **Workflow Automation Integration:** Connecting direct API endpoints between the candidate logging database and communication tools (e.g., Microsoft Power Automate) to push automatic sign-off alerts to financial decision-makers' mobile devices.

---

## 📁 Repository Structure
```text
├── data/
│   ├── Vacancies.csv                    # Cleaned raw job vacancy profiles
│   ├── Candidates.csv                   # Candidate application tracker
│   └── StageEvents.csv                  # Chronological pipeline event logging database
├── SQL_Scripts/
│   └── recruitment_view_engine.sql      # Main database view schema script
├── Visualizations/
│   └── recruitment_diagnostic_dashboard.png # High-resolution Tableau console layout
└── README.md                            # Executive portfolio project documentation
```
