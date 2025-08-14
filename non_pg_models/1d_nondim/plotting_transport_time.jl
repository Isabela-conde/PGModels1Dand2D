using PyPlot
using PyCall
using JLD2
using NCDatasets


plt.style.use(joinpath(@__DIR__, "../../plots.mplstyle"))
close("all")
pygui(false)

pl = pyimport("matplotlib.pylab")
inset_locator = pyimport("mpl_toolkits.axes_grid1.inset_locator")
pc = 1/6 # pica

"""
    profile_plot(datafiles)

Plot profiles from JLD2 snapshot files in the `datafiles` list.
"""
function profile_plot(datafiles; fname=joinpath(out_dir, "profiles.png"))

    # load steady state solutions


    # init plot
    fig, ax = subplots(2, 2, figsize=(30pc, 35pc))


    ax[1].set_xlabel(L"Cross-slope flow $\tilde{u}$")
    ax[1].set_ylabel(L"Vertical coordinate $\tilde{z}$")
    ax[2].set_xlabel(L"Along-slope flow $\tilde{v}$")

    ax[3].set_xlabel(L"Cross-slope transport $\mathcal{M}$")
    ax[2].set_ylabel(L"Vertical coordinate $\tilde{z}$")

    ax[4].set_xlabel(L"Stratification $N^2 + \partial_{\tilde z} \tilde b$")

    subplots_adjust(bottom=0.15, top=0.92, left=0.1, right=0.9, wspace=0.25, hspace=0.25)

    for a in ax
        a.ticklabel_format(style="sci", axis="x", scilimits=(-3, 3))
        a.grid(true)  # <-- add this line
    end

    # color map
    colors = pl.cm.viridis(range(1, 0, length=size(datafiles, 1)-1))
    # transport_timeseries = joinpath(@__DIR__, "/out/transport_timeseries.jld2")
    Q_ts = jldopen("/Users/isabelaconde/Documents/GitHub/PGModels1Dand2D/non_pg_models/1d_nondim/out/transport_timeseries.jld2", "r")

    Q = Q_ts["Q"]
    ts = Q_ts["t"]


    # zoomed z
    ax[1].set_ylim([0, z_max])
    ax[2].set_ylim([0, z_max])
    ax[4].set_ylim([0, z_max])

    # ax[3].set_xlim([-0.05, 0.05])

    # plot data from `datafiles`
    for i ∈ eachindex(datafiles)
        # load
        d = jldopen(datafiles[i], "r")
        u = d["u"]
        v = d["v"]
        b = d["b"]
        t = d["t"]        
        
        model = d["model"]
        close(d)
        z = model.z
        N = model.N

        # stratification
        bz = differentiate(b, z)
        # bt = -u .+ differentiate(κ.*(N^2 .+ bz),z)
        # bt = differentiate(b, t)

        # colors and labels
        if t == Inf
            label = "Steady state"
        else
            label = string(L"$\tilde{t}$ = ", Int64(round(t)))
        end

        if i == 1
            color = "mediumblue"
        else
            color = colors[i-1, :]
        end

        # plot
        ax[1].plot(u, z, c=color)
        # ax[3].plot(bt, z, c=color)
        ax[2].plot(v,z, color = color)
        ax[4].plot(N^2 .+ bz,  z, c=color, label=label)

    end

    ax[3].plot(Q,ts, c ="k")
    ax[3].set_ylim([0, 1.1*maximum(ts)])
    # ax[2].legend()
    ax[3].set_ylabel(L"Time $\tilde{t}$")
    ax[3].tick_params(
        bottom=true, left=true,   # show tick marks
        labelbottom=true, labelleft=true                # show labels
    )
    ax[3].invert_yaxis()


    ax[4].legend()

    savefig(fname)
    println(fname)
    plt.close()
end


