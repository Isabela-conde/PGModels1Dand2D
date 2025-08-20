using PGModels1Dand2D
using Printf
using PyPlot

# output directory for checkpoints, plots, and log files
out_dir = joinpath(@__DIR__, "out")
if !isdir(out_dir)
    mkdir(out_dir)
end

include("model.jl") 
# include("evolution_dampB.jl")
include("evolution.jl")

# include("plotting_damp.jl")

# include("evolution_bt.jl")
# include("plotting_transport_time.jl")
include("plotting_transport.jl")


################################################################################
# set up model
################################################################################

# canonical or transport-constrained case?
canonical = true

τ_A = 4e0 # nondim arrest time
τ_S = 1e2 # nondim spindown time
Ek = 1/τ_S^2 # Ekman number
S = 1/τ_A # slope Burger number
H = τ_S # depth (z ∈ [0, H] ⟹ z̃ ∈ [0, H/δ = 1/sqrt(Ek) = τ_S])
v₀ = 10 # initial farfield along-slope flow
N = 1 # background stratification

# timestep
Δt = minimum([τ_S/5e4, τ_A/5e4])

# number of grid points
nz = 2^12

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
BT12 = true
BT12_debug = false

BT12kappa = false

κ_b = 100*κ0
r =  0#1e-3 #
rr =@. 0*exp(-z/h)
z_max = 100

# store in model
model = Model(S, v₀, N, Δt, z, ν, κ, rr; canonical)

################################################################################
# run single integration
################################################################################

u, v, b, Px = evolve(model; t_final=10, t_save=1)

################################################################################
# plots
###############################################################################

path = ""
i_saves = 0:1:5
dfiles = [joinpath(out_dir, @sprintf("checkpoint%03d.jld2", i)) for i in i_saves]

# print dimensional parameters 

ν = 1e-4 
N = sqrt(1e-5)
f = 1e-4

δ = sqrt(ν/f)
θ = sqrt(f^2/(N^2* τ_A))
V = (f*δ)/θ
V∞ = v₀*V
T = 1/f
B = (V*N^2*θ)/f


# dir = "/Users/isabelaconde/Documents/GitHub/PGModels1Dand2D/non_pg_models/1d_nondim/kappa_damped_v010/"
# dfiles = [joinpath(dir, @sprintf("checkpoint%03d.jld2", i)) for i in i_saves]

profile_plot(dfiles)





# print non dim parameters
println("Parameters:")
println("θ = $θ ")
println("V = $V ")
println("V∞ = $V∞ ")