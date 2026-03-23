# Arise
personal development app

## Data Entry App (Frontend + Backend)

This project now includes:

- Frontend form: `Arise_Data_Entry/frontend_1/index.html`
- Backend API: `Arise_Data_Entry/backend/app.py`
- Target CSV file: `dataset/data3.csv`

### 1) Start Backend

```powershell
cd Arise_Data_Entry/backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python app.py
```

The backend runs at `http://127.0.0.1:5000`.

### 2) Open Frontend

Open `Arise_Data_Entry/frontend_1/index.html` in your browser.

### 3) Submit Logs

Fill the form and click **Add Log**.
Each successful submission is appended as a new row in `dataset/data3.csv`.
