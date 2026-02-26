# Deploy CUSTODIAN To Render

This project can run on Render as a Python Web Service using the Flask terminal server in `custodian-terminal/server.py`.

## 1) Push this repo to GitHub

Render deploys from a Git repo, so make sure your latest changes are pushed.

## 2) Create the Web Service in Render

1. In Render, click **New +** -> **Blueprint**.
2. Connect the GitHub repo.
3. Render will detect `render.yaml` and propose one service named `custodian-terminal`.
4. Click **Apply**.

## 3) Wait for first deploy

Render will:

- run `pip install -r requirements.txt`
- start with:

```bash
gunicorn --bind 0.0.0.0:$PORT --workers 2 --threads 4 --timeout 120 --chdir custodian-terminal server:app
```

When deploy finishes, open the Render URL for the service.

## 4) Verify the game UI

1. Open the service URL in a browser.
2. Confirm boot stream appears.
3. After boot completes, run a command like:
   - `STATUS`
4. Confirm terminal output returns and the map/snapshot panel updates.

## Notes

- `BOOT_DELAY` is set in `render.yaml` (default `"0.35"`). Lower it if you want faster boot text.
- Free Render instances spin down when idle, so first load may be slow.
- If you later want persistent game state across restarts, add external storage; current state is in-memory.
