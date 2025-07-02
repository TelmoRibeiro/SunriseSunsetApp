----------
# Overview

This document describes how to run the artifact:

- Running the `backend`  (must be started before the frontend)
- Running the `frontend` (depends on the backend being available)

----------
# How to run the backend:

1. Open the `./src/backend/` folder in a terminal.
This module contains all backend-related files, including the `Gemfile`, `Rakefile`, database, and server code.

2. Run:

```bash
ruby server.rb
```
This starts the Sinatra server on `http://localhost:4567`.

3. Requests can be made using the following URL format:
`http://localhost:4567/sun-data?location=$1&start_date=$2&end_date=$3`
Replace `$1`, `$2`, and `$3` with the corresponding parameter values.

----------
# How to run the frontend:

1. Open the `./src/frontend/` folder in a terminal.
This module contains all frontend-related files, including **HTML**, **CSS**, **JavaScript**, and **React**-specific components.

2. To run in *development mode* (auto-reloading):

```bash
npm run dev
```
Then open the provided local URL (typically `http://localhost:5173`).

3. Fill in the form and click **Get Data** to query the backend.