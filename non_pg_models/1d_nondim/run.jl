using PGModels1Dand2D
using Printf
using PyPlot

# output directory for checkpoints, plots, and log files
out_dir = joinpath(@__DIR__, "out")
if !isdir(out_dir)
    mkdir(out_dir)
end

include("model.jl") 
include("evolution_damp.jl")
include("plotting_damp.jl")

# include("evolution_damp.jl")
# include("plotting_damp.jl")

################################################################################
# set up model
################################################################################

# canonical or transport-constrained case?
canonical = true

τ_A = 2e0 # nondim arrest time
τ_S = 5e2 # nondim spindown time
Ek = 1/τ_S^2 # Ekman number
S = 1/τ_A # slope Burger number
H = τ_S # depth (z ∈ [0, H] ⟹ z̃ ∈ [0, H/δ = 1/sqrt(Ek) = τ_S])
v₀ = 20 # initial farfield along-slope flow
N = 1 # background stratification

# timestep
Δt = minimum([τ_S/1e2, τ_A/1e2])

# number of grid points
nz = 2^11

# grid (chebyshev, z = 0 is bottom)
# z = @. H*(1 - cos(pi*(0:nz-1)/(nz-1)))/2
z = range(0, H, nz)

# bottom enhanced:
# ν0 = 1e-1
# ν1 = 1 - 1e-1
# κ0 = 1e-1
# κ1 = 1 - 1e-1
# h = 10

# not bottom enhanced:
ν0 = 1
ν1 = 0
κ0 = 1
κ1 = 0
h = 1
ν = @. ν0 + ν1*exp(-z/h)
κ = @. κ0 + κ1*exp(-z/h)

# for BT12 mixing scheme
BT12 = false
BT12_debug = false
κ_b = 10*κ0
r =  @. 1*exp(-z/h)
z_max = 200

# store in model
model = Model(S, v₀, N, Δt, z, ν, κ, r; canonical)

################################################################################
# run single integration
################################################################################

u, v, b, Px = evolve(model; t_final=1000, t_save=200)

################################################################################
# plots
################################################################################

path = ""
i_saves = 0:1:5
dfiles = [joinpath(out_dir, @sprintf("checkpoint%03d.jld2", i)) for i in i_saves]
profile_plot(dfiles)


# print dimensional parameters 

ν = 1e-4 
N = sqrt(1e-5)
f = 1e-4

δ = sqrt(ν/f)
θ = sqrt(f^2/(N^2* τ_A))
V = (f*δ)/θ
V∞ = v₀*V

# print non dim parameters
println("Parameters:")
println("θ = $θ ")
println("V = $V ")
println("V∞ = $V∞ ")