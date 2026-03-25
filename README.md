# Arise
Personal development chat app with wellness logging and local AI guidance.

## Quick Start

### Prerequisites
- Python 3.10+
- ~2GB free disk (for model download on first run)

### 1) Install Dependencies

```powershell
cd C:\Users\MaharshiJB\Downloads\Projects\Arise\Arise
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2) Run the App

```powershell
streamlit run app.py
```

The app opens at `http://localhost:8501`.

## Features

### Chat Interface (Main)
- **Local AI Model**: Uses Google Flan-T5-Small (100M params), runs on CPU
- **Mood-Aware**: Context from your daily wellness logs injected into responses
- **Personalized**: Learns from your sleep, energy, stress, and mood patterns
- **No Cloud Dependency**: Everything runs locally on your machine

### Wellness Logger (Sidebar)
- Log daily metrics: sleep hours, energy level, stress level, mood rating
- Data persists to `data/user_data.csv`
- Automatically used to personalize chat responses

### Data Entry Backend (Optional)
- Separate REST API for bulk logging if needed
- Located in `Arise_Data_Entry/backend/`
- Routes to `dataset/data3.csv`

Arise/
│
├── app.py                 # Main Streamlit entrypoint
├── requirements.txt       # All dependencies
├── README.md
│
├── data/
│   ├── user_data.csv      # Stores user inputs
│   └── model_data.pkl     # Optional: saved ML model
│
├── models/
│   ├── llm_model/         # Hugging Face small LLM or GPT-J checkpoint
│   └── ml_models/         # Any trained scikit-learn models
│
├── utils/
│   ├── data_handler.py    # Load/save CSV, preprocess
│   ├── ml_predictor.py    # Train & predict moods/emotions
│   └── llm_chat.py        # Chat logic + LLM integration
│
└── assets/                # Images, icons, CSS for Streamlit