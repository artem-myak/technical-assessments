# Credit Risk Data Transformation & Portfolio Analysis (XML to Tabular)

## ⚠️ Data Privacy & Security Disclaimer
**Original XML datasets provided for this assessment are not included in this repository** as they contain sensitive financial structures and metadata.
* This repository uses **synthetic, anonymized sample data** for demonstration purposes.
* A `.gitignore` file is configured to prevent accidental uploads of raw `.xml` files.
* All metrics and logic are fully reproducible using the provided sample structure.

## Objective
The goal of this project is to process unstructured XML files containing credit bureau data, transform them into a flat tabular format, and calculate three key client-level risk metrics:
1. **Total count of loans** per client.
2. **Closure Ratio:** Ratio of closed loans count over total loans count.
3. **Amount at Risk (30+ DPD):** Sum of currently expired deals amount over 30+ days.

## Project Structure
- `data/` — folder containing anonymized sample XML files.
- `main.py` — core script for data parsing, cleaning, and metrics calculation.
- `requirements.txt` — list of Python dependencies.

## Methodology
To ensure maximum reliability and handle potential issues with broken chronology or "corrupt" data in source files, an ELT-inspired (Extract, Load, Transform) approach was implemented:

### 1. Data Extraction (Engineering Phase)
The script utilizes the `xml.etree.ElementTree` library for robust parsing. Instead of relying on the physical order of XML tags, the script iterates through all historical loan periods (`<deallife>`) and extracts every state, capturing the calculation date (`dldateclc`). 
* **Defensive Programming:** Implementation of `try-except` blocks to safely handle missing or malformed financial attributes (Missing/Bad values).

### 2. Data Transformation (Data Cleaning)
Raw extracted data is converted into a `pandas.DataFrame`. 
* **Chronological Integrity:** Date fields are cast to `datetime` objects. 
* **Snapshot Selection:** To guarantee the most current loan status, the data is sorted by `Report_Date`, followed by dropping historical duplicates based on the `['Client_id', 'Loan_id']` pair using `keep='last'`. This ensures that only the latest snapshot is used for final analysis, regardless of the order in the source XML.

### 3. Data Analysis (Metrics Calculation)
Analytics are performed using vectorized operations and the `.groupby()` method for high performance:
* **Total Loans:** Calculated via unique loan identifiers (`dlref`).
* **Closure Ratio:** Implemented by applying `.mean()` to a boolean status mask (e.g., status "closed"), providing a robust percentage calculation.
* **30+ DPD Exposure:** Filtered by delinquency days (`dldayexp > 30`) and aggregated by the overdue amount field (`dlamtexp`).
* **Handling Nulls:** Clients with no delinquencies are safely handled using `.fillna(0)` to ensure numerical consistency in the final report.

## How to Run (Reproducibility)
1. Ensure the `data` folder with input XML files is in the same directory as `main.py`.
2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt

Note: This project was completed as part of a technical assessment for a Risks Data Analyst role.