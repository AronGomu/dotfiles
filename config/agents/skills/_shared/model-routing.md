# Shared coding-task model routing

Canonical routing policy for implementation-skill child launches.

## Models

- **Luna** = `openai-codex/gpt-5.6-luna`
- **Astra** = `openai-codex/gpt-6-astra`

## Routing rules

1. Classify each ticket before spawn. Match its dominant task plus every explicit risk signal below.
2. Multiple matches → choose strongest model, then highest thinking level.
3. Previous failed attempt always matches `Extremely hard / previously failed task`.
4. Caller must pass exact `model` and `thinking` spawn overrides. Agent frontmatter is fallback only; prompt text cannot switch an already-started model.
5. Worker prompt must include: `Routing: {matched row} → {provider/model}, thinking {level}`.
6. Child verifies routing line against ticket before edits. Mismatch → report `failed: routing mismatch`; do not implement.

## Task table

| Coding task                             | Default model | Thinking |
| --------------------------------------- | ------------- | -------: |
| Rename / tiny edit                      | **Luna**      |      Low |
| Formatting / lint fixes                 | **Luna**      |      Low |
| Boilerplate generation                  | **Luna**      |   Medium |
| Simple unit tests                       | **Luna**      |   Medium |
| Documentation / comments                | **Luna**      |      Low |
| Simple CRUD                             | **Luna**      |   Medium |
| Add form / validation                   | **Luna**      |   Medium |
| Simple API endpoint                     | **Luna**      |   Medium |
| Small frontend component                | **Luna**      |   Medium |
| Local bug with clear error              | **Luna**      |     High |
| Fix failing tests                       | **Luna**      |     High |
| Add integration tests                   | **Luna**      |     High |
| Small multi-file feature                | **Luna**      |     High |
| Dependency/library integration          | **Luna**      |     High |
| Code review / find obvious bugs         | **Luna**      |     High |
| Medium feature                          | **Astra**     |   Medium |
| Significant refactor                    | **Astra**     |   Medium |
| Complex multi-file feature              | **Astra**     |     High |
| Architecture change                     | **Astra**     |     High |
| Difficult debugging                     | **Astra**     |     High |
| Unknown root-cause bug                  | **Astra**     |     High |
| Performance optimization                | **Astra**     |     High |
| Concurrency / race condition            | **Astra**     |    XHigh |
| Security-sensitive code                 | **Astra**     |    XHigh |
| Database migration                      | **Astra**     |     High |
| Large repo refactor                     | **Astra**     |     High |
| Framework migration                     | **Astra**     |     High |
| Repo-wide API rename/change             | **Astra**     |   Medium |
| Greenfield small app                    | **Astra**     |   Medium |
| Greenfield complex subsystem            | **Astra**     |     High |
| Autonomous “fix until tests pass”       | **Luna**      |     High |
| Autonomous well-specified feature       | **Luna**      |     High |
| Autonomous ambiguous feature            | **Astra**     |     High |
| Long agentic session, repetitive work   | **Luna**      |     High |
| Long agentic session, hard reasoning    | **Astra**     |     High |
| Extremely hard / previously failed task | **Astra**     |    XHigh |
| Last-resort unsolved coding problem     | **Astra**     |    XHigh |
