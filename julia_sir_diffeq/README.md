# julia_sir_diffeq (internal test)

Internal variant of the SIR workflow whose Julia step (`solveSIRModel.jl`) integrates the model with the **`OrdinaryDiffEq`** solver (`ODEProblem` + `solve(prob, Tsit5())`) instead of a hand-rolled Euler step. Only the Julia `solve` function changes; `getSIRData` (Python) and `processSIRData` (R) are reused unchanged from `IzzyLerman/SIRWorkflow`. Output format (`time,S,I,R` in `sir_output.csv`) is preserved so the R step still works.

This is for internal testing on a fork — not a public example.

## Two prerequisites to run it

1. **A Julia container with `OrdinaryDiffEq` baked in.** Build `base-julia` from the `feat/base-julia-ordinarydiffeq` branch of `Ashish-Ramrakhiani/FaaSr-Docker` (it adds `OrdinaryDiffEq` to the `Pkg.add` list), build the `github-actions-julia` platform image from it, and push it. Set the `solve` entry in `julia_diffeq_test.json` to that image's tag (placeholder currently `ghcr.io/ashish-ramrakhiani/github-actions-julia:diffeq`).

2. **The `.jl` function must be on a default branch.** FaaSr fetches Julia function code by downloading the repo tarball from its **default branch** (no ref) — a feature branch is not seen. So `FunctionGitRepo.solveSIRModel` → `Ashish-Ramrakhiani/FaaSr-Functions/julia_sir_diffeq` only resolves once this `julia_sir_diffeq/` folder is on the fork's **main** (or hosted on the default branch of another repo you control).

## Files

- `solveSIRModel.jl` — the diff-eq Julia function
- `julia_diffeq_test.json` — the workflow config (a copy of the SIR test JSON we have been using, with `solve` repointed to this function + the diff-eq container)
