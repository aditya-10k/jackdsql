# JackDSQL Backend API Reference

Base URL (default): `http://localhost:8080`

All JSON request/response bodies use **snake_case** field names where entities are annotated with `@JsonNaming(SnakeCaseStrategy)` (for example `question_title`, `is_correct`).

---

## Authentication

Most endpoints require a valid JWT. After login or registration, send the token on every protected request:

```http
Authorization: Bearer <token>
```

| Access | Endpoints |
|--------|-----------|
| **Public** (no token) | `/api/auth/**`, `/api/health` |
| **Protected** (JWT required) | All other routes listed below |

Token lifetime is configured in `application.properties` (`application.security.jwt.expiration`, default 24 hours).

---

## Health

### `GET /api/health`

| | |
|---|---|
| **Auth** | None |
| **Response** | HTML status page (`text/html`) |

**Usage:** Quick check that the server is up. Open in a browser or call with any HTTP client. No request body.

---

## Authentication (`/api/auth`)

### `POST /api/auth/register`

| | |
|---|---|
| **Auth** | None |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string | Yes | User email (also used as login username) |
| `password` | string | Yes | Account password |
| `name` | string | Yes | Display name |

**Response:** `200 OK`

```json
{ "token": "<jwt>" }
```

**Usage:** Create a new account. Store `token` and use it as the Bearer token for subsequent calls.

---

### `POST /api/auth/login`

| | |
|---|---|
| **Auth** | None |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `email` | string | Yes |
| `password` | string | Yes |

**Response:** `200 OK` — same shape as register (`token`).

**Usage:** Authenticate an existing user and obtain a JWT.

---

### `POST /api/auth/googleauth`

| | |
|---|---|
| **Auth** | None |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id_token` | string | Yes | Google Sign-In ID token from the client |

**Response:** `200 OK` — `{ "token": "<jwt>" }`

**Usage:** Sign in or register via Google OAuth. Requires Google OAuth client configuration on the server.

---

## Questions — listing & bookmarks (`/api/questions`)

### `GET /api/questions/all-questions`

| | |
|---|---|
| **Auth** | JWT required |
| **Response** | `200 OK` — array of `Question` entities |

**Usage:** Fetch the full question catalog (titles, difficulty, schema SQL, etc.). Used for admin-style listing or clients that load everything at once.

---

### `GET /api/questions/{id}`

| | |
|---|---|
| **Auth** | JWT required |
| **Path param** | `id` — question UUID |

**Response:** `200 OK`

```json
{
  "question": { /* Question object */ },
  "is_completed": false,
  "is_bookmarked": true
}
```

**Usage:** Load one question for the practice UI, including whether the current user has completed or bookmarked it.

---

### `GET /api/questions/grouped`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK` — map keyed by difficulty (e.g. `"Easy"`, `"Medium"`), each value a list of listing items:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Question id |
| `title` | string | Question title |
| `difficulty` | string | Difficulty label |
| `domain` | string | Topic domain |
| `completed` | boolean | User has submitted a correct answer |
| `bookmarked` | boolean | User bookmarked this question |

**Usage:** Power the question browser grouped by difficulty with per-user progress flags.

---

### `POST /api/questions/{id}/bookmark`

| | |
|---|---|
| **Auth** | JWT required |
| **Path param** | `id` — question UUID |

**Response:** `200 OK`

```json
{ "is_bookmarked": true }
```

`is_bookmarked` reflects the state **after** the toggle (added if it was absent, removed if it was present).

**Usage:** Heart/bookmark toggle on a question detail page. No request body.

---

### `GET /api/questions/bookmarks`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK` — array of:

| Field | Type |
|-------|------|
| `id` | string (bookmark id) |
| `question_id` | string |
| `question_title` | string |
| `bookmarked_at` | ISO datetime |

**Usage:** Show the user’s saved questions list.

---

## Questions — SQL preview & submit (`api/questions`)

> Note: These controllers use the path prefix `api/questions` (no leading slash). Spring resolves them the same as `/api/questions/...`.

### `POST /api/questions/preview`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `question_id` | string | Yes | Question UUID |
| `user_sql` | string | Yes | SQL to run in the sandbox |

**Response:** `200 OK` — `PreviewResponse`:

```json
{
  "columns": ["col1", "col2"],
  "rows": [{ "col1": "value", "col2": 1 }],
  "error": null
}
```

On failure, `columns` and `rows` may be `null` and `error` contains the message.

**Errors:** `400` if question not found — `{ "error": "Question not found with id: ..." }`

**Usage:** Run the user’s query against the question’s seed schema in an isolated DB schema (read-only preview, max 10 rows). Use before submit to debug SQL.

---

### `POST /api/questions/submit`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:** Same as preview (`question_id`, `user_sql`).

**Response:** `200 OK`

```json
{ "is_correct": true }
```

**Behavior:** Compares normalized query results to the stored solution. If correct and not already completed, records progress for the authenticated user.

**Errors:** `400` with plain text if question not found.

**Usage:** Final answer submission for a practice question.

---

## Foundations — content (`/api/foundations`)

### `GET /api/foundations/all`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK` — array of full `Foundation` entities.

**Usage:** Load all foundation topics (lessons + practice tasks).

---

### `GET /api/foundations/catalogue`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK` — list of catalogue rows:

| Field | Type |
|-------|------|
| `id` | string |
| `chapter` | string |
| `title` | string |
| `completed` | boolean |

**Usage:** Foundation home page with completion status for the current user.

---

### `GET /api/foundations/{id}`

| | |
|---|---|
| **Auth** | JWT required |
| **Path param** | `id` — foundation topic UUID |

**Response:** `200 OK` — single `Foundation` (content + `practice_tasks`).

**Usage:** Open one foundation lesson and its practice SQL task.

---

## Foundations — SQL preview & submit (`api/foundations/`)

### `POST /api/foundations/preview`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `topic_id` | string | Yes — foundation UUID |
| `user_sql` | string | Yes |

**Response:** `200 OK` — same `PreviewResponse` as question preview.

**Behavior:** Runs SQL against the **first** practice task on that foundation topic.

**Usage:** Preview SQL while learning a foundation chapter.

---

### `POST /api/foundations/submit`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:** Same as foundation preview (`topic_id`, `user_sql`).

**Response:** `200 OK` — `{ "is_correct": true|false }`

**Behavior:** Evaluates against the first practice task; saves foundation progress on first correct completion.

**Usage:** Submit foundation practice SQL.

---

## Playground (`/api/playground`)

### `POST /api/playground`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `userSql` | string | Yes | **camelCase** key (not snake_case) |

**Response:** `200 OK` — `PreviewResponse` (up to 50 rows on final `SELECT`).

**Errors:** `400` with `PreviewResponse` where `error` is set, e.g.:

- `"Query is empty"`
- `"Malicious query detected , code rejected"` — blocks `DROP DATABASE` and `ALTER SYSTEM` (case-insensitive substring check)

**Behavior:** Creates a temporary schema, runs multiple semicolon-separated statements, returns the last `SELECT` result. Supports DDL/DML before a final `SELECT`.

**Usage:** Free-form SQL sandbox without tying to a specific question.

---

## User dashboard (`api/user`)

### `GET /api/user/overview`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK`

```json
{
  "message": "success",
  "stats": {
    "foundations": { "completed": 2, "total": 10 },
    "questions": { "completed": 5, "total": 50 }
  },
  "activity_history": {
    "2026-05-20": ["<question-or-topic-id>", "..."]
  }
}
```

`activity_history` keys are dates (`LocalDate`); values are lists of completed item ids.

**Usage:** Dashboard home — progress counts and completion calendar/history.

---

### `GET /api/user/profile`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK`

```json
{
  "id": "<uuid>",
  "email": "user@example.com",
  "name": "Display Name"
}
```

**Usage:** Profile/settings screen for the logged-in user.

---

## User API keys — AI providers (`api/user/keys`)

Supported providers: `GEMINI`, `GROQ` (enum `AiProvider`).

> Implementation note: these endpoints store keys under `UserDetails.getUsername()`, which is the user’s **email**, not the internal user UUID.

### `POST /api/user/keys/add`

| | |
|---|---|
| **Auth** | JWT required |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required |
|-------|------|----------|
| `provider` | `GEMINI` \| `GROQ` | Yes |
| `api_key` | string | Yes |

**Response:** `201 Created` (empty body)

**Usage:** Save or update an encrypted provider API key for AI hints.

---

### `GET /api/user/keys`

| | |
|---|---|
| **Auth** | JWT required |

**Response:** `200 OK` — array of:

| Field | Type | Description |
|-------|------|-------------|
| `provider` | string | `GEMINI` or `GROQ` |
| `key_mask` | string | Masked key, e.g. `abcd...wxyz` |
| `updated_at` | string | ISO local datetime |

**Usage:** List which providers are configured (never returns the full key).

---

### `DELETE /api/user/keys/delete/{provider}`

| | |
|---|---|
| **Auth** | JWT required |
| **Path param** | `provider` — `GEMINI` or `GROQ` |

**Response:** `204 No Content`

**Usage:** Remove a stored API key for a provider.

---

## AI hints (`/api/ai`)

Requires a configured API key for the chosen provider (see above).

### `POST /api/ai/hint/{questionId}?provider={GEMINI|GROQ}`

| | |
|---|---|
| **Auth** | JWT required |
| **Path param** | `questionId` — question UUID |
| **Query param** | `provider` — **required** — `GEMINI` or `GROQ` |
| **Content-Type** | `application/json` |

**Request body:**

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `sqlCode` | string | No | **camelCase**; defaults to `""` — user’s current SQL |

**Response:** `202 Accepted`

```json
{
  "request_id": "<uuid>",
  "status": "PENDING"
}
```

**Errors:** `IllegalArgumentException` if no API key exists for that provider (typically `500` unless handled globally).

**Usage:** Enqueue an async AI hint job. Poll results on the SSE stream (below) using `request_id` correlation on the client.

---

### `GET /api/ai/stream`

| | |
|---|---|
| **Auth** | JWT required |
| **Accept** | `text/event-stream` (SSE) |

**Response:** Server-Sent Events stream (timeout 300 seconds).

Initial event:

```
event: INIT
data: Connection Established
```

Further events are pushed when hint responses are ready (producer/consumer via internal messaging).

**Usage:** Open once after login (or when entering practice UI) to receive real-time AI hint completions. Reconnect on disconnect.

**Example (browser):**

```javascript
const es = new EventSource('/api/ai/stream', {
  headers: { Authorization: 'Bearer ' + token } // Note: native EventSource cannot set headers; use fetch-based SSE or a polyfill
});
```

For authenticated SSE in browsers, use `fetch` with `ReadableStream` or a library that supports custom headers.

---

## Typical client flows

### 1. Sign up and practice a question

1. `POST /api/auth/register` → save `token`
2. `GET /api/questions/grouped` with Bearer token
3. `GET /api/questions/{id}` for detail
4. `POST /api/questions/preview` with `{ "question_id", "user_sql" }` while editing
5. `POST /api/questions/submit` when ready
6. Optional: `POST /api/questions/{id}/bookmark`

### 2. AI hint on a question

1. `POST /api/user/keys/add` with provider + API key
2. `GET /api/ai/stream` (authenticated SSE)
3. `POST /api/ai/hint/{questionId}?provider=GEMINI` with `{ "sqlCode": "SELECT ..." }`
4. Listen on SSE for the hint payload tied to `request_id`

### 3. Foundation lesson

1. `GET /api/foundations/catalogue`
2. `GET /api/foundations/{id}`
3. `POST /api/foundations/preview` / `POST /api/foundations/submit`

### 4. Open SQL playground

1. `POST /api/playground` with `{ "userSql": "SELECT 1" }`

---

## HTTP status summary

| Code | When |
|------|------|
| `200` | Success (most GET/POST) |
| `201` | API key saved |
| `202` | AI hint accepted |
| `204` | API key deleted |
| `400` | Validation / not found / bad playground query |
| `401` | Missing or invalid JWT on protected routes |
| `403` | Authenticated but not authorized (if applicable) |

---

## CORS

`QuestionController`, `QuestionsSubmissionController`, `FoundationSubmissionController`, and `UserDashboard` declare `@CrossOrigin(origins = "*")`. Other controllers rely on default CORS behavior unless configured globally.

---

*Generated from Spring controllers in `src/main/java/com/jackdsql/app/controllers/` and `SecurityConfig`.*
