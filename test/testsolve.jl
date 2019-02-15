
using JuLIP
using Test
using LinearAlgebra: I

println("===================================================")
println("          TEST SOLVE ")
println("===================================================")

println("-----------------------------------------------------------------")
println("Testing `minimise!` with equilibration with LJ calculator to lattice")
println("-----------------------------------------------------------------")
calc = lennardjones(r0=rnn(:Al))
at = bulk(:Al, cubic=true) * 10
X0 = positions(at) |> mat
at = rattle!(at, 0.02)
set_calculator!(at, calc)
set_constraint!(at, FixedCell(at))
minimise!(at, precond=:id, verbose=2)
X1 = positions(at) |> mat
X0 .-= X0[:, 1]
X1 .-= X1[:, 1]
F = X1 / X0
println("check that the optimiser really converged to a lattice")
@show vecnorm(F'*F - I, Inf)
@show vecnorm(F*X0 - X1, Inf)
@test vecnorm(F*X0 - X1, Inf) < 1e-4

println("-------------------------------------------------")
println("same test but large and with Exp preconditioner")
println("-------------------------------------------------")

at = bulk(:Al, cubic=true) * (20,20,2)
at = rattle!(at, 0.02)
set_calculator!(at, calc)
set_constraint!(at, FixedCell(at))
minimise!(at, precond = :exp, method = :lbfgs,
          robust_energy_difference = true, verbose=2)


println("-------------------------------------------------")
println("   Variable Cell Test")
println("-------------------------------------------------")
calc = lennardjones(r0=rnn(:Al))
at = set_pbc!(bulk(:Al, cubic=true), true)
set_calculator!(at, calc)
set_constraint!(at, VariableCell(at))
minimise!(at, verbose = 2)


println("-------------------------------------------------")
println(" FF preconditioner for StillingerWeber ")
println("-------------------------------------------------")

at = bulk(:Si, cubic=true) * (10,10,2)
at = set_pbc!(at, true)
at = rattle!(at, 0.02)
set_calculator!(at, StillingerWeber())
set_constraint!(at, FixedCell(at))
P = FF(at, StillingerWeber())
minimise!(at, precond = P, method = :lbfgs, robust_energy_difference = true, verbose=2)


println("-------------------------------------------------")
println(" FF preconditioner for EAM ")
println("-------------------------------------------------")

at = bulk(:W, cubic=true) * (10,10,2)
at = set_pbc!(at, true)
at = rattle!(at, 0.02)
X0 = positions(at)

##
set_positions!(at, X0)
set_calculator!(at, eam_W)
set_constraint!(at, FixedCell(at))
P = FF(at, eam_W)
minimise!(at, precond = P, method = :lbfgs, robust_energy_difference = true, verbose=2)

## steepest descent
set_positions!(at, X0)
set_calculator!(at, eam_W)
set_constraint!(at, FixedCell(at))
P = FF(at, eam_W)
minimise!(at, precond = P, method = :sd, robust_energy_difference = true, verbose=2)


##
println("Optimise again with some different stabilisation options")
set_positions!(at, X0)
set_calculator!(at, eam_W)
set_constraint!(at, FixedCell(at))
P = FF(at, eam_W, stab=0.1, innerstab=0.2)
minimise!(at, precond = P, method = :lbfgs, robust_energy_difference = true, verbose=2)

##
println("for comparison now with Exp")
set_positions!(at, X0)
minimise!(at, precond = :exp, method = :lbfgs, robust_energy_difference = true, verbose=2)


println("-------------------------------------------------")
println("Test optimisation with VariableCell")
# start with a clean `at`
at = bulk(:Al) * 2   # cubic=true,
set_calculator!(at, calc)
set_constraint!(at, VariableCell(at))

println("For the initial state, stress/virial is far from 0:")
@show vecnorm(virial(at), Inf)
JuLIP.Solve.minimise!(at, verbose=2)
println("After optimisation, stress/virial should be 0:")
@show vecnorm(virial(at), Inf)
@test vecnorm(virial(at), Inf) < 1e-4


println("-------------------------------------------------")
println("And now with pressure . . .")
set_constraint!(at, VariableCell(at, pressure=10.0123))
JuLIP.Testing.fdtest(calc, at, verbose=true, rattle=0.1)
at = bulk(:Al) * 2
set_calculator!(at, calc)
set_constraint!(at, VariableCell(at, pressure=0.01))
JuLIP.Solve.minimise!(at, verbose = 2)
@show vecnorm(virial(at), Inf)
@show vecnorm(gradient(at), Inf)
@test vecnorm(gradient(at), Inf) < 1e-4
println("note it is correct that virial is O(1) since we applied pressure")
