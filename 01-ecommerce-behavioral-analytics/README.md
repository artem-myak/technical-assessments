# E-commerce Behavioral Analytics & A/B Test Evaluation

## Business Task
Analyze user acquisition, conversion funnels, and retention patterns for an international e-commerce platform. Additionally, evaluate the results of a UI experiment (A/B test) and propose a framework for investigating conversion drops.

## 🛠 Tech Stack
* **SQL:** Window functions, Cohort analysis (Retention), Complex aggregations.
* **Statistics:** A/B test significance, Conversion Rate (CR) analysis.
* **Product Analytics:** Hypothesis prioritization, Funnel troubleshooting.

## Key Insights & Solutions

### Part 1: SQL Analytics
* **Retention Analysis:** Built a cohort model to track user return rates at Day 1, Day 7, and Day 30.
* **Conversion Optimization:** Calculated monthly registration-to-first-purchase rates.
* **Operational Monitoring:** Developed a query to track Weekly AOV (Average Order Value) dynamics with Wow % change.
* [View SQL Script](./solution.sql)

### Part 2: A/B Test Audit
* **Finding:** While the Test group showed a 0.25% absolute lift in CR, a statistical significance check (p-value) is required before implementation.
* **Data Gaps:** Identified the need for sample variance, segment-specific data, and guardrail metrics (e.g., Refund Rate).

### Part 3: Product Thinking (Root Cause Analysis)
* Developed a 4-step framework to investigate a 15% conversion drop:
  1. **Technical Health Check** (Bugs/Errors).
  2. **External Factors** (Seasonality/Competitors).
  3. **Traffic Source Analysis** (Quality of acquisition).
  4. **Funnel Friction** (Specific step drop-offs).

---
Note: This project was completed as part of a professional pivot into Data Analysis. Data has been anonymized.