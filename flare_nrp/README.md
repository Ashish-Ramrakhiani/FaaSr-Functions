# FLARE on Kubernetes (NRP) — a worked FaaSr example

This example runs a real **FLARE** GLM-AED lake-water-quality forecast for Falling Creek Reservoir (FCRE) as a FaaSr **Kubernetes** action on the [National Research Platform (NRP)](https://nrp.ai) / Nautilus cluster. Unlike the tiny `tutorial` and `julia_sir` examples, FLARE is a heavy, real-world scientific workload — a large container, substantial CPU/memory, and a lot of S3 I/O — which makes it a good end-to-end test of FaaSr's Kubernetes backend.

## Workflow shape

```
start (GitHub Actions)  ──▶  run-fcre-aed-forecast (Kubernetes)
```

- **`start`** runs on GitHub Actions. It seeds a trivial input and satisfies FaaSr's rule that the entry action must be a GitHub Actions action with `UseSecretStore: true`.
- **`run-fcre-aed-forecast`** runs on the Kubernetes cluster and does the forecasting: it assimilates the latest observations, runs a GLM-AED ensemble forecast for each reference date, and writes forecasts + skill scores to an S3-compatible object store.

## Pieces involved

| Piece | What it is |
| --- | --- |
| **Container** | `github-actions-glm-aed-flare-rs-k8s` — bakes in GLM+AED (built from source), the **FLAREr** R package (from the public [`FLARE-forecast/FLAREr`](https://github.com/FLARE-forecast/FLAREr)), and a Kubernetes-capable FaaSr engine. |
| **Forecast function** | `run_fcre_aed_forecast` from [`FLARE-forecast/FCRE-forecast-code`](https://github.com/FLARE-forecast/FCRE-forecast-code) (referenced via `FunctionGitRepo`). |
| **Data stores** | The FCRE object stores (met/inflow drivers, targets, forecast/score outputs, restart) on OSN, plus a scratch bucket — all with `UseSecretStore: false` so their credentials reach the pod. |

## Running it

Prerequisites: NRP access with a namespace, and the FaaSr Kubernetes secrets set up in your FaaSr-workflow repo. The **[Running FaaSr on NRP](https://faasr.io)** walkthrough has the full step-by-step (tokens, CA cert, endpoint, secrets); this example is the "section 11" worked case from that guide. Then:

1. Put `fcre_glm_aed_flare_rs_k8s.json` (this directory) in your FaaSr-workflow repo and fill in the placeholders: your namespace, API-server endpoint, base64 CA cert, GitHub username, and the FLARE image.
2. **Register** the workflow (allow custom containers — the FLARE image is not a native FaaSr image).
3. **Invoke.** The GitHub Actions entry action submits one Kubernetes Job into your namespace.
4. **Watch:** `kubectl get jobs,pods -n <namespace> -w`, and `kubectl logs <pod> -n <namespace>`.

## What a run looks like

In a bounded demo run, the Kubernetes Job reached **`Complete 1/1` in ~12 minutes**, producing **6 daily GLM-AED forecasts** (`reference_date=2026-05-24 … 2026-05-29`) written to the object store, and exited gracefully at its internal time budget (`Approaching action time budget; exiting loop cleanly with restart written`).

## Sizing and time budget

FLARE is far heavier than the other examples — size the Kubernetes action accordingly:

```json
"MaxCPU": 2000, "MaxMemory": 8000, "TimeLimit": 1800, "AdditionalTimeToLive": 3600
```

Each forecast cycle advances one reference date and writes a restart to S3. A full multi-month backfill runs for hours; Kubernetes kills a Job at `TimeLimit` with `DeadlineExceeded`. For a **bounded demo run**, cap the forecast's internal loop comfortably below `TimeLimit` so the action exits gracefully (Job → `Complete`); for the **full** range, raise `TimeLimit`. Because each cycle persists a restart, an early stop can be resumed simply by invoking again.

## Notes

- **`UseSecretStore: false` on the Kubernetes server** is required — it's how the pod receives the S3 credentials.
- The forecast entry function currently lives on a branch of FCRE-forecast-code (see [PR #92](https://github.com/FLARE-forecast/FCRE-forecast-code/pull/92)). FaaSr `git clone`s the **default branch** of a `FunctionGitRepo` — point the repo's default branch (or your fork's) at the branch you're using.
- The GLM binary uses the current namelist schema (`subm_height` for submerged inflows). Older FCRE configs using `subm_elev` need that variable renamed, or GLM aborts with `Base nml missing the following variable name: subm_height`.
