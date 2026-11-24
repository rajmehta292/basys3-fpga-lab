# Basys3 Documentation Guide

This folder is the teaching and evidence layer for the repository. Read it in
this order if you are learning the project from scratch.

1. [`learning-path.md`](learning-path.md) — staged curriculum from Boolean
   logic through timing, FIFOs, CDC, and host integration.
2. [`architecture.md`](architecture.md) — system boundaries, assumptions, and
   the distinction between the new project and the historical GPMC work.
3. [`project-catalog.md`](project-catalog.md) — every project, controls,
   verification, and interview angle.
4. [`installation-vivado.md`](installation-vivado.md) — tool installation,
   license requirements, openXC7 fallback, and exact commands.
5. [`verification-plan.md`](verification-plan.md) — gates that must pass before
   a claim is made.
6. [`performance-results.md`](performance-results.md) — measured evidence only.
7. [`bringup-log.md`](bringup-log.md) — machine-specific hardware evidence.
8. [`interview-prep.md`](interview-prep.md) and
   [`interview-project-stories.md`](interview-project-stories.md) — how to
   explain the work without inventing historical details.

## Repository rules

- A simulation pass is not a timing-closure pass.
- An openXC7 estimate is not a Vivado report.
- JTAG programming is not visual hardware verification.
- A theoretical 128-bit × 100 MHz rate is not measured throughput.
- The original AM3358/GPMC project remains historically unverified where the
  resume does not specify implementation details.
- Licenses, passwords, AMD tokens, and private credentials never belong in Git.

## Evidence vocabulary

Use `PASS` only for a check that actually ran. Use `INFORMATIONAL` for an
estimate. Use `NOT RUN` when the required tool, hardware observation, or
capture has not happened. Use `BLOCKED` only when an external prerequisite
prevents the next verification step.
