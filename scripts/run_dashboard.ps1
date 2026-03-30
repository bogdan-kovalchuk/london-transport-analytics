$ErrorActionPreference = "Stop"

if (-not (Test-Path ".venv")) {
    Write-Host "Creating Python virtual environment..."
    python -m venv .venv
}

Write-Host "Installing dashboard dependencies..."
& ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
& ".\.venv\Scripts\python.exe" -m pip install -r "dashboard\requirements.txt"

Write-Host "Starting Streamlit dashboard..."
& ".\.venv\Scripts\python.exe" -m streamlit run "dashboard\app.py"
