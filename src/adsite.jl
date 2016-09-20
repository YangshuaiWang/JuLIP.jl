import ForwardDiff

import ReverseDiffPrototype
const _RD_ = ReverseDiffPrototype

using JuLIP: vecs

export SitePotential,
   FDPotential, FDPotential_r,
   RDPotential_r


# Implementation of a generic site potential
# ================================================

abstract SitePotential <: Potential

energies(pot::SitePotential, at::AbstractAtoms) =
   Float64[ pot(r, R) for (_1,_2, r, R,_4) in sites(at, cutoff(pot)) ]

energy(pot::SitePotential, at::AbstractAtoms) = sum_kbn(energies(pot, at))

function forces(pot::SitePotential, at::AbstractAtoms)
   frc = zerovecs(length(at))
   for (i, j, r, R, _) in sites(at, cutoff(pot))
      dpot = @D pot(r, R)
      frc[j] -= dpot
      frc[i] += sum(dpot)
   end
   return frc
end


# Implementation of a ForwardDiff site potential
# ================================================

function ad_evaluate end

"""
`abstract FDPotential <: SitePotential`

To implement a site potential that uses ForwardDiff.jl for AD, create
a concrete type and overload `JuLIP.Potentials.ad_evaluate`.

Example
```julia
@pot type P1 <: FDPotential
end
JuLIP.Potentials.ad_evaluate{T<:Real}(pot::P1, R::Matrix{T}) =
               sum( exp(-norm(R[:,i])) for i = 1:size(R,2) )
```

Notes:

* For an `FDPotential`, the argument to `ad_evaluate` will be
`R::Matrix` rather than `R::JVecsF`; this is an unfortunate current limitation of
`ForwardDiff`. Hopefully it can be fixed.
* TODO: allow arguments `(r, R)` then use chain-rule to combine them.
"""
abstract FDPotential <: SitePotential

evaluate(pot::FDPotential, r, R) = ad_evaluate(pot, mat(collect(R)))

evaluate_d(pot::FDPotential, r, R) =
   ForwardDiff.gradient( R_ -> ad_evaluate(pot, R_), mat(collect(R)) ) |> vecs


abstract FDPotential_r <: SitePotential

evaluate(pot::FDPotential_r, r, R) = ad_evaluate(pot, collect(r))

function evaluate_d(pot::FDPotential_r, r, R)
   d = ForwardDiff.gradient( r_ -> ad_evaluate(pot, r_), collect(r) )
   return [ (d[i]/r[i]) * R[i] for i = 1:length(r) ]
end


# Implementation of a ReverseDiffPrototype site potential
# ========================================================

abstract RDPotential_r <: SitePotential

evaluate(pot::RDPotential_r, r, R) = ad_evaluate(pot, collect(r))

function evaluate_d(pot::RDPotential_r, r, R)
   d = _RD_.gradient( r_ -> ad_evaluate(pot, r_), collect(r) )
   return [ (d[i]/r[i]) * R[i] for i = 1:length(r) ]
end
