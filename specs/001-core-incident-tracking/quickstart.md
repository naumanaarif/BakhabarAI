# Quickstart: core-incident-tracking

## Backend (FastAPI)

1. Navigate to the `backend/` directory.
2. Ensure you have the required `.env` file populated with your API keys (`GOOGLE_MAPS_API_KEY`, `GEMINI_API_KEY`).
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the FastAPI server:
   ```bash
   uvicorn main:app --reload --port 8000
   ```
5. The API will be available at `http://localhost:8000`. 
   - Mock data is loaded from `backend/data/`.
   - The agents will run simulated workflows when `/api/run-scenario` is triggered.

## Mobile (Flutter)

1. Navigate to the `mobile/` directory.
2. Ensure you have added the `MAPS_API_KEY` to `android/app/src/main/AndroidManifest.xml`.
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app on an Android emulator or physical device:
   ```bash
   flutter run
   ```
5. The app will connect to the local FastAPI backend (ensure `constants.dart` points to `http://10.0.2.2:8000` if using an Android emulator).
