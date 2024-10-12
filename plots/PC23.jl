################################################################################
# This file contains all the code needed (appart from simulation setup) to 
# produce the plots in 
# 
#       Peterson & Callies (2022) Coupling between abyssal boundary layers and 
#       the interior ocean in the absence of along-slope variations, submitted.
#
################################################################################

using PGModels1Dand2D, PyPlot, PyCall

plt.style.use("../plots.mplstyle")
plt.close("all")
pygui(false)

# matplotlib
pl = pyimport("matplotlib.pylab")
pe = pyimport("matplotlib.patheffects")
inset_locator = pyimport("mpl_toolkits.axes_grid1.inset_locator")
lines = pyimport("matplotlib.lines")
gridspec = pyimport("matplotlib.gridspec")
pc = 1/6 # a pica is 1/6th of an inch

### utility functions

"""
    U = BL_transport_2D(m, s)

Compute BL tranport from 2D BL theory.
"""
function BL_transport_2D(m::ModelSetup2DPG, s::ModelState2DPG)
    dbdξ = ∂ξ(m, s.b[:, 1])
    μ = m.ν[1, 1] / m.κ[1, 1]
    return @. m.κ[:, 1]/m.Hx * μ*m.Hx/m.f^2 * dbdξ / (1 - μ*m.Hx/m.f^2 * dbdξ)
end

"""
    H*uσ = exchange_vel_2D(m, χ)

Compute exchange velocity in 2D given BL transport (i.e. interior streamfunction at σ = -1).
""" 
function exchange_vel_2D(m::ModelSetup2DPG, χ::Vector{Float64})
    if m.coords == "cartesian"
        # uσ = -dξ(χ)/H
        uσ = -∂ξ(m, χ)./m.H
    elseif m.coords == "cylindrical"
        # uσ = -dρ(ρ*χ)/(H*ρ)
        uσ = -∂ξ(m, m.ξ.*χ)./m.H./m.ξ
        # assume χ = 0 at ρ = 0
        fd_ξ = mkfdstencil([0, m.ξ[1], m.ξ[2]], m.ξ[1], 1)
        uσ[1] = -(fd_ξ[2]*m.ξ[1]*χ[1] + fd_ξ[3]*m.ξ[2]*χ[2])/(m.H[1]*m.ξ[1])
    end
    return m.H.*uσ
end

### plotting functions

function BL_correction(folder)
    fig, ax = subplots(1, 2)
    
    ax[1].set_xlabel(L"Streamfunction $\chi$ ($\times 10^{-3}$ m$^2$ s$^{-1}$)")
    ax[1].xaxis.set_label_coords(1.0, -0.15)
    ax[1].set_ylabel(L"Vertical coordinate $z$ (km)")

    m = load_setup_1D(string(folder,     "S1e-3/bl/setup.h5"))
    mFull = load_setup_1D(string(folder, "S1e-3/full/setup.h5"))
    s = load_state_1D(string(folder,     "S1e-3/bl/state1.h5"))

    # compute full solution on finer grid
    z = mFull.z .- mFull.z[1]
    χ, b = get_full_soln(m, s, z)
    χI = s.χ

    # plot
    ax[1].plot(1e3*χ,  z/1e3, "-",  lw=2, label=L"$\chi_\mathrm{I} + \chi_\mathrm{B}$")
    ax[1].plot(1e3*χI, (m.z .- m.z[1])/1e3, "--", lw=1.5, label=L"\chi_\mathrm{I}")
    ax[2].plot(1e3*χ,  z/1e3, "-",  lw=2, label=L"$\chi_\mathrm{I} + \chi_\mathrm{B}$")
    ax[2].plot(1e3*χI, (m.z .- m.z[1])/1e3, "--", lw=1.5, label=L"\chi_\mathrm{I}")
    ax[1].fill_between([-10, 10], 0, 0.1, color="k", alpha=0.3, lw=0)

    # lims
    ax[1].set_xlim([-0.5, 1.3])
    ax[1].set_xticks(-0.5:0.5:1)
    ax[2].set_xlim([0, 1.3])
    ax[1].set_ylim([0, 2.0])
    ax[2].set_ylim([0, 0.1])
    ax[1].set_yticks(0:0.5:2)

    # labels
    ax[1].legend()
    # ax[1].annotate("(a)", (-0.04, 1.05), xycoords="axes fraction")
    # ax[2].annotate("(b)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2].annotate("Interior", (0.2, 0.8), xycoords="axes fraction")
    ax[2].annotate("BL",       (0.1, 0.1), xycoords="axes fraction")

    subplots_adjust(wspace=0.3)

    # savefig("BL_correction.pdf")
    # println("BL_correction.pdf")
    savefig("BL_correction.png")
    println("BL_correction.png")
    plt.close()
end

function slope_profiles(folder)
    # init plot
    fig, ax = subplots(2, 3, figsize=(27*pc, 23*pc), sharey=true)

    axins11 = inset_locator.inset_axes(ax[1, 1], width="50%", height="50%")
    axins21 = inset_locator.inset_axes(ax[2, 1], width="50%", height="50%")

    ax[1, 1].set_ylabel(L"Vertical coordinate $z$ (km)")
    ax[2, 1].set_ylabel(L"Vertical coordinate $z$ (km)")
    ax[2, 1].set_xlabel(string(L"Streamfunction $\chi$", "\n", L"($\times 10^{-3}$ m$^2$ s$^{-1}$)"))
    ax[2, 2].set_xlabel(string(L"Along-slope flow $u^y$", "\n", L"($\times 10^{-2}$ m s$^{-1}$)"))
    ax[2, 3].set_xlabel(string(L"Stratification $N^2 + \partial_z b'$", "\n", L"($\times 10^{-6}$ s$^{-2}$)"))

    ax[1, 1].annotate("(a)", (-0.04, 1.05), xycoords="axes fraction")
    ax[1, 2].annotate("(b)", (-0.04, 1.05), xycoords="axes fraction")
    ax[1, 3].annotate("(c)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 1].annotate("(d)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 2].annotate("(e)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 3].annotate("(f)", (-0.04, 1.05), xycoords="axes fraction")

    fig.text(0.05, 0.97, L"Slope Burger number $\varrho = 10^{-3}$:", ha="left", va="top", size=8)
    fig.text(0.05, 0.51, L"Slope Burger number $\varrho = 0.5$:",     ha="left", va="top", size=8)

    subplots_adjust(hspace=0.5)

    # limits
    ax[1, 1].set_xlim([-0.05, 1.2])
    axins11.set_xlim([0, 1.2])
    ax[2, 1].set_xlim([-0.7, 18])
    axins21.set_xlim([0, 18])
    ax[1, 2].set_xlim([-2, 0.5])
    ax[1, 2].set_xticks(-2:1:0)
    ax[2, 2].set_xlim([-30, 5])
    ax[2, 2].set_xticks(-30:10:0)
    ax[1, 3].set_xlim([0, 1.3])
    ax[2, 3].set_xlim([0, 1.3])
    ax[1, 1].set_ylim([0, 2])
    ax[1, 2].set_ylim([0, 2])
    ax[1, 3].set_ylim([0, 2])
    ax[2, 1].set_ylim([0, 2])
    ax[2, 2].set_ylim([0, 2])
    ax[2, 3].set_ylim([0, 2])
    axins11.set_ylim([0, 0.1])
    axins21.set_ylim([0, 0.1])

    # color map
    colors = pl.cm.viridis(range(1, 0, length=5))

    # plot data
    for i=1:5
        # line color
        color = colors[i, :]

        # BL 1D small S
        m = load_setup_1D(string(folder,     "S1e-3/bl/setup.h5"))
        mFull = load_setup_1D(string(folder, "S1e-3/full/setup.h5"))
        s = load_state_1D(string(folder,     "S1e-3/bl/state$i.h5"))
        z = mFull.z .- mFull.z[1]
        χ, b = get_full_soln(m, s, z)
        δ, μ, S, q = get_BL_params(m)
        v = @. -m.f*s.χ[1]/q/m.ν[1] - tan(m.θ)/m.f*(s.b - s.b[1])
        Bz = m.N2 .+ differentiate(b, z)
        label = string(Int64(m.Δt*s.i[1]/secs_in_year), " years")
        ax[1, 1].plot(1e3*χ,  z/1e3, c=color, label=label)
        axins11.plot(1e3*χ,   z/1e3, c=color, label=label)
        ax[1, 2].plot(1e2*v,  (m.z .- m.z[1])/1e3, c=color, label=label)
        ax[1, 3].plot(1e6*Bz, z/1e3, c=color, label=label)

        # full 1D small S
        m = load_setup_1D(string(folder, "S1e-3/full/setup.h5"))
        s = load_state_1D(string(folder, "S1e-3/full/state$i.h5"))
        z = m.z .- m.z[1]
        v = s.v
        Bz = m.N2 .+ differentiate(b, z)
        ax[1, 1].plot(1e3*χ,  z/1e3, "k--", lw=0.5)
        axins11.plot(1e3*χ,   z/1e3, "k--", lw=0.5)
        ax[1, 2].plot(1e2*v,  z/1e3, "k--", lw=0.5)
        ax[1, 3].plot(1e6*Bz, z/1e3, "k--", lw=0.5)

        # BL 1D big S
        m = load_setup_1D(string(folder,     "S5e-1/bl/setup.h5"))
        mFull = load_setup_1D(string(folder, "S5e-1/full/setup.h5"))
        s = load_state_1D(string(folder,     "S5e-1/bl/state$i.h5"))
        z = mFull.z .- mFull.z[1]
        χ, b = get_full_soln(m, s, z)
        δ, μ, S, q = get_BL_params(m)
        v = @. -m.f*s.χ[1]/q/m.ν[1] - tan(m.θ)/m.f*(s.b - s.b[1])
        Bz = m.N2 .+ differentiate(b, z)
        label = string(Int64(m.Δt*s.i[1]/secs_in_year), " years")
        ax[2, 1].plot(1e3*χ,   z/1e3, c=color, label=label)
        axins21.plot(1e3*χ,   z/1e3, c=color, label=label)
        ax[2, 2].plot(1e2*v,   (m.z .- m.z[1])/1e3, c=color, label=label)
        ax[2, 3].plot(1e6*Bz,  z/1e3, c=color, label=label)

        # full 1D big S
        m = load_setup_1D(string(folder, "S5e-1/full/setup.h5"))
        s = load_state_1D(string(folder, "S5e-1/full/state$i.h5"))
        z = m.z .- m.z[1]
        v = s.v
        Bz = m.N2 .+ differentiate(b, z)
        ax[2, 1].plot(1e3*χ,  z/1e3, "k--", lw=0.5)
        axins21.plot(1e3*χ,   z/1e3, "k--", lw=0.5)
        ax[2, 2].plot(1e2*v,  z/1e3, "k--", lw=0.5)
        ax[2, 3].plot(1e6*Bz, z/1e3, "k--", lw=0.5)
    end

    custom_handles = [lines.Line2D([0], [0], c="k", ls="-", lw=1),
                      lines.Line2D([0], [0], c="k", ls="--", lw=0.5)]
    custom_labels = ["BL 1D", "Full 1D"]
    ax[1, 2].legend(custom_handles, custom_labels, loc=(0.55, 0.72))
    ax[1, 3].legend(loc="upper left")
    
    savefig("slope_profiles.pdf")
    println("slope_profiles.pdf")
    plt.close()
end

function TF_coords()
    # params for ridge
    nξ = 2^8
    nσ = 2^8
    H0 = 2e3
    L = 2e6

    # TF grid
    ξ = collect(0:L/(nξ - 1):L)
    σ = @. -(cos(pi*(0:nσ-1)/(nσ-1)) + 1)/2  
    ξξ = repeat(ξ, 1, nσ)
    σσ = repeat(σ', nξ, 1)

    # depth
    H = @. H0*(1 + 0.4*cos(2*π*ξ/L))

    # physical grid
    x = repeat(ξ, 1, nσ)
    z = repeat(σ', nξ, 1).*repeat(H, 1, nσ)

    # level sets 
    σlevels = -1.0:0.1:0.0
    ξlevels = 0:L/9:L

    # plot ξ and σ surfaces
    fig, ax = subplots()
    ax.fill_between(ξ, -H, -H0*1.4, color="k", alpha=0.3, lw=0.0)
    ax.contour(x, z, σσ, σlevels, colors="k", linestyles="-")
    ax.contour(x, z, ξξ, ξlevels, colors="k", linestyles="-")
    ax.axhline(0, lw=1, ls="-", c="k")
    ax.axvline(L, lw=1, ls="-", c="k")
    ax.set_xticks([])
    ax.set_yticks([])
	ax.spines["left"].set_visible(false)
	ax.spines["bottom"].set_visible(false)
    ax.set_ylim([-H0*1.4, 0])
    tight_layout()
    savefig("TF_coords.svg")
    println("TF_coords.svg")
end

function seamount(folder)
    fig, ax = subplots(1, 2, figsize=(19*pc, 17*pc), sharey=true)

    m = load_setup_2D(string(folder, "full2D/setup.h5"))
    s = load_state_2D(string(folder, "full2D/state1.h5"))
    ix = argmin(abs.(m.x[:, 1] .- m.L/4))
    a, cb = ridge_plot(m, s, 1e2*s.χ, "", string(L"Streamfunction $\chi$", "\n", L"($\times 10^{-2}$ m$^2$ s$^{-1}$)"); 
        ax=ax[1], cb_orientation="horizontal", xlabel=L"Horizontal coordinate $r$ (km)", pad=0.2, vext=2.0)
    a, cb = ridge_plot(m, s, 1e1*s.uη, "", string(L"Along-slope flow $r u^\phi$", "\n", L"($\times 10^{-1}$ m s$^{-1}$)"); 
        ax=ax[2], style="pcolormesh", cb_orientation="horizontal", xlabel=L"Horizontal coordinate $r$ (km)", pad=0.2, vext=2.5)
    cb.set_ticks([-2.5, 0, 2.5])
    ax[1].plot([m.L/1e3/4, m.L/1e3/4], [m.z[ix, 1]/1e3, 0], "r-", alpha=0.7)
    ax[2].plot([m.L/1e3/4, m.L/1e3/4], [m.z[ix, 1]/1e3, 0], "r-", alpha=0.7)
    ax[1].annotate("(a)", (0.0, 1.05), xycoords="axes fraction")
    ax[2].annotate("(b)", (0.0, 1.05), xycoords="axes fraction")
    ax[2].set_ylabel("")

    savefig("seamount.pdf")
    println("seamount.pdf")
    plt.close()
end

function seamount_profiles(folder)
    # init plot
    fig, ax = subplots(2, 3, figsize=(27*pc, 23*pc), sharey=true)

    axins11 = inset_locator.inset_axes(ax[1, 1], width="100%", height="100%", 
                                        bbox_to_anchor=(0.3, 0.4, .5, .5), bbox_transform=ax[1, 1].transAxes, loc=3)
    axins21 = inset_locator.inset_axes(ax[2, 1], width="100%", height="100%", 
                                        bbox_to_anchor=(0.3, 0.4, .5, .5), bbox_transform=ax[2, 1].transAxes, loc=3)

    ax[1, 1].set_ylabel(L"Vertical coordinate $z$ (km)")
    ax[2, 1].set_ylabel(L"Vertical coordinate $z$ (km)")
    ax[2, 1].set_xlabel(string(L"Streamfunction $\chi$", "\n", L"($\times 10^{-2}$ m$^2$ s$^{-1}$)"))
    ax[2, 2].set_xlabel(string(L"Along-slope flow $r u^\phi$", "\n", L"($\times 10^{-1}$ m s$^{-1}$)"))
    ax[2, 3].set_xlabel(string(L"Stratification $\partial_z b$", "\n", L"($\times 10^{-6}$ s$^{-2}$)"))

    ax[1, 1].annotate("(a)", (-0.04, 1.05), xycoords="axes fraction")
    ax[1, 2].annotate("(b)", (-0.04, 1.05), xycoords="axes fraction")
    ax[1, 3].annotate("(c)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 1].annotate("(d)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 2].annotate("(e)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 3].annotate("(f)", (-0.04, 1.05), xycoords="axes fraction")

    fig.text(0.05, 0.97, "BL 1D:", ha="left", va="top", size=8)
    fig.text(0.05, 0.51, "BL 2D:", ha="left", va="top", size=8)

    subplots_adjust(hspace=0.5)

    # model setups
    m1DBL = load_setup_1D(string(folder, "bl1D/setup.h5"))
    m2D = load_setup_2DPG(string(folder, "full2D/setup.h5"))
    ix = argmin(abs.(m2D.x[:, 1] .- m2D.L/4))
    m2DBL = load_setup_2DPG(string(folder, "bl2D/setup.h5"))
    ixBL = argmin(abs.(m2DBL.x[:, 1] .- m2DBL.L/4))

    # limits
    ax[1, 1].set_xlim([-2, 0.05])
    ax[2, 1].set_xlim([-2, 0.05])
    axins11.set_xlim([-2, 0.05])
    axins21.set_xlim([-2, 0.05])
    ax[1, 2].set_xlim([-2, 4])
    ax[1, 2].set_xticks(-2:2:4)
    ax[2, 2].set_xlim([-2, 4])
    ax[2, 2].set_xticks(-2:2:4)
    ax[1, 3].set_xlim([0, 1.3])
    ax[2, 3].set_xlim([0, 1.3])
    ax[1, 1].set_ylim([m2D.z[ix, 1]/1e3, 0])
    ax[1, 2].set_ylim([m2D.z[ix, 1]/1e3, 0])
    ax[1, 3].set_ylim([m2D.z[ix, 1]/1e3, 0])
    ax[2, 1].set_ylim([m2D.z[ix, 1]/1e3, 0])
    ax[2, 2].set_ylim([m2D.z[ix, 1]/1e3, 0])
    ax[2, 3].set_ylim([m2D.z[ix, 1]/1e3, 0])
    axins11.set_ylim([m2D.z[ix, 1]/1e3, (m2D.z[ix, 1] + 55)/1e3])
    axins21.set_ylim([m2D.z[ix, 1]/1e3, (m2D.z[ix, 1] + 55)/1e3])

    # color map
    colors = pl.cm.viridis(range(1, 0, length=5))

    # plot data
    for i=1:5
        # line color
        color = colors[i, :]

        # BL 1D
        m = m1DBL
        s = load_state_1D(string(folder, "bl1D/state$i.h5"))
        z = m2D.z[ix, :] .- m2D.z[ix, 1]
        χ, b = get_full_soln(m, s, z)
        v = cumtrapz(m.f*(χ .- χ[end])./m2D.ν[ix, :], z)
        Bz = m.N2 .+ differentiate(b, z)
        label = string(Int64(m.Δt*s.i[1]/secs_in_year), " years")
        ax[1, 1].plot(1e2*χ,  z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        axins11.plot(1e2*χ,   z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        ax[1, 2].plot(1e1*v,  z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        ax[1, 3].plot(1e6*Bz, z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)

        # full 2D
        m = m2D
        s = load_state_2D(string(folder, "full2D/state$i.h5"))
        bz = differentiate(s.b[ix, :], m.z[ix, :])
        ax[1, 1].plot(1e2*s.χ[ix, :],  m.z[ix, :]/1e3, "k--", lw=0.5)
        axins11.plot(1e2*s.χ[ix, :],   m.z[ix, :]/1e3, "k--", lw=0.5)
        ax[1, 2].plot(1e1*s.uη[ix, :], m.z[ix, :]/1e3, "k--", lw=0.5)
        ax[1, 3].plot(1e6*bz,          m.z[ix, :]/1e3, "k--", lw=0.5)

        # BL 2D
        m = m2DBL
        s = load_state_2D(string(folder, "bl2D/state$i.h5"))
        z = m2D.z[ix, :] .- m2D.z[ix, 1]
        χ, b = get_full_soln(m, s, z, ixBL)
        v = cumtrapz(m.f*(χ .- χ[end])./m2D.ν[ix, :], z)
        bz = differentiate(b, z)
        ax[2, 1].plot(1e2*χ,  z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        axins21.plot(1e2*χ,   z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        ax[2, 2].plot(1e1*v,  z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)
        ax[2, 3].plot(1e6*bz, z/1e3 .+ m2D.z[ix, 1]/1e3, c=color, label=label)

        # full 2D
        m = m2D
        s = load_state_2D(string(folder, "full2D/state$i.h5"))
        bz = differentiate(s.b[ix, :], m.z[ix, :])
        ax[2, 1].plot(1e2*s.χ[ix, :],  m.z[ix, :]/1e3, "k--", lw=0.5)
        axins21.plot(1e2*s.χ[ix, :],   m.z[ix, :]/1e3, "k--", lw=0.5)
        ax[2, 2].plot(1e1*s.uη[ix, :], m.z[ix, :]/1e3, "k--", lw=0.5)
        ax[2, 3].plot(1e6*bz,          m.z[ix, :]/1e3, "k--", lw=0.5)
    end

    custom_handles = [lines.Line2D([0], [0], c="k", ls="--", lw=0.5)]
    custom_labels = ["Full 2D"]
    ax[1, 2].legend(custom_handles, custom_labels, loc="upper left")
    ax[1, 3].legend(loc="upper left")
    
    savefig("seamount_profiles.pdf")
    println("seamount_profiles.pdf")
    plt.close()
end

function ridge_exp_strat(folder)
    fig = figure(figsize=(33*pc, 28*pc))
    gs = gridspec.GridSpec(2, 2, width_ratios=[1, 1], height_ratios=[1.5, 1])
    ax = [fig.add_subplot(gs[1]) fig.add_subplot(gs[2]);
          fig.add_subplot(gs[3]) fig.add_subplot(gs[4])]

    # top row: ridges
    ax[1, 1].annotate(L"(a) $N^2 =$ constant", (0.0, 1.05), xycoords="axes fraction")
    ax[1, 2].annotate(L"(b) $N^2 \sim \exp(z/d)$", (0.0, 1.05), xycoords="axes fraction")

    m = load_setup_2D(string(folder, "const/full2D/setup.h5"))
    s = load_state_2D(string(folder, "const/full2D/state1.h5"))
    ix = argmin(abs.(m.x[:, 1] .- m.L/4))
    ridge_plot(m, s, 1e3*s.χ,  "", L"Streamfunction $\chi$ ($\times 10^{-3}$ m$^2$ s$^{-1}$)"; 
        ax=ax[1, 1], cb_orientation="horizontal", pad=0.2, vext=2)

    m = load_setup_2D(string(folder, "exp/full2D/setup.h5"))
    s = load_state_2D(string(folder, "exp/full2D/state1.h5"))
    ix = argmin(abs.(m.x[:, 1] .- m.L/4))
    ridge_plot(m, s, 1e3*s.χ,  "", L"Streamfunction $\chi$ ($\times 10^{-3}$ m$^2$ s$^{-1}$)"; 
        ax=ax[1, 2], cb_orientation="horizontal", pad=0.2, vext=3)
    ax[1, 2].set_ylabel("")

    # bottom row: transport and exchange
    ax[2, 1].annotate("(c)", (-0.04, 1.05), xycoords="axes fraction")
    ax[2, 2].annotate("(d)", (-0.04, 1.05), xycoords="axes fraction")

    ax[2, 1].set_xlabel(L"Horizontal coordinate $x$ (km)")
    ax[2, 1].set_ylabel(L"BL transport ($\times 10^{-3}$ m$^2$ s$^{-1}$)")

    ax[2, 2].set_xlabel(L"Horizontal coordinate $x$ (km)")
    ax[2, 2].set_ylabel(string(L"Exchange velocity $H u^\sigma$", "\n", L"($\times 10^{-9}$ m s$^{-1}$)"))

    mConst = load_setup_2D(string(folder, "/const/bl2D/setup.h5"))
    mExp   = load_setup_2D(string(folder, "/exp/bl2D/setup.h5"))

    s = load_state_2D(string(folder, "/const/bl2D/state1.h5"))
    χtheory = BL_transport_2D(mConst, s)
    W = exchange_vel_2D(mConst, χtheory)
    ax[2, 1].plot(mConst.ξ/1e3, 1e3*χtheory, label=string(L"$N^2 = $", "constant"))
    ax[2, 2].plot(mConst.ξ/1e3, 1e9*W)

    s = load_state_2D(string(folder, "/exp/bl2D/state1.h5"))
    χtheory = BL_transport_2D(mExp, s)
    W = exchange_vel_2D(mExp, χtheory)
    ax[2, 1].plot(mExp.ξ/1e3, 1e3*χtheory,label=L"$N^2 \sim \exp(z/d)$")
    ax[2, 2].plot(mExp.ξ/1e3, 1e9*W)

    ax[2, 1].set_xlim([0, mConst.L/1e3])
    ax[2, 1].set_ylim([-3, 3])

    ax[2, 2].set_xlim([0, mConst.L/1e3])
    ax[2, 2].set_ylim([-10, 20])

    ax[2, 1].legend()

    subplots_adjust(hspace=0.3, wspace=0.4)

    savefig("ridge_exp_strat.pdf")
    println("ridge_exp_strat.pdf")
    plt.close()
end

path = "../../sims/"

BL_correction(string(path, "sim044/"))
# slope_profiles(string(path, "sim044/"))
# TF_coords()
# seamount(string(path, "sim042/"))
# seamount_profiles(string(path, "sim042/"))
# ridge_exp_strat(string(path, "sim037/"))