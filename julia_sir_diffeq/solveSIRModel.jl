using CSV
using DataFrames
using OrdinaryDiffEq

function sirModel!(du, u, p, t)
    S, I, R = u
    Beta, Gamma, N = p
    du[1] = -Beta * S * I / N
    du[2] = Beta * S * I / N - Gamma * I
    du[3] = Gamma * I
end

function solveSIRModel()
    inputFile = "SIR_init_conditions.csv"
    faasr_get_file(inputFile, inputFile)

    # Expecting columns: beta, gamma, N, S0, I0, R0, tmax
    data = CSV.read(inputFile, DataFrame)
    Beta = data.beta[1]
    Gamma = data.gamma[1]
    N = data.N[1]
    S0 = data.S0[1]
    I0 = data.I0[1]
    R0 = data.R0[1]
    tmax = data.tmax[1]

    u0 = [S0, I0, R0]
    tspan = (0.0, Float64(tmax))
    p = (Beta, Gamma, N)

    # Integrate the SIR model with the OrdinaryDiffEq solver (Tsit5),
    # sampling once per day so the output matches the downstream format.
    prob = ODEProblem(sirModel!, u0, tspan, p)
    sol = solve(prob, Tsit5(), saveat=1.0)

    S = [u[1] for u in sol.u]
    I = [u[2] for u in sol.u]
    R = [u[3] for u in sol.u]
    out_df = DataFrame(time=sol.t, S=S, I=I, R=R)

    outName = "sir_output.csv"
    CSV.write(outName, out_df)
    faasr_put_file(outName, outName)
end

#solveSIRModel()
