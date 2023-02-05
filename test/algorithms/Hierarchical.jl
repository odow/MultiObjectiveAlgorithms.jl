#  Copyright 2019, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public License,
#  v.2.0. If a copy of the MPL was not distributed with this file, You can
#  obtain one at http://mozilla.org/MPL/2.0/.

module TestHierarchical

using Test

import HiGHS
import MOO

const MOI = MOO.MOI

function run_tests()
    for name in names(@__MODULE__; all = true)
        if startswith("$name", "test_")
            @testset "$name" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_sorted_priorities()
    @test MOO._sorted_priorities([0, 0, 0]) == [[1, 2, 3]]
    @test MOO._sorted_priorities([1, 0, 0]) == [[1], [2, 3]]
    @test MOO._sorted_priorities([0, 1, 0]) == [[2], [1, 3]]
    @test MOO._sorted_priorities([0, 0, 1]) == [[3], [1, 2]]
    @test MOO._sorted_priorities([0, 1, 1]) == [[2, 3], [1]]
    @test MOO._sorted_priorities([0, 2, 1]) == [[2], [3], [1]]
    return
end

function test_knapsack()
    P = Float64[1 0 0 0; 0 1 1 0; 0 0 1 1; 0 1 0 0]
    model = MOO.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOO.Algorithm(), MOO.Hierarchical())
    MOI.set.(model, MOO.ObjectivePriority.(1:4), [2, 1, 1, 0])
    MOI.set.(model, MOO.ObjectiveWeight.(1:4), [1, 0.5, 0.5, 1])
    MOI.set(model, MOO.ObjectiveRelativeTolerance(1), 0.1)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variables(model, 4)
    MOI.add_constraint.(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint.(model, x, MOI.LessThan(1.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MAX_SENSE)
    f = MOI.Utilities.operate(vcat, Float64, P * x...)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(model, sum(1.0 * x[i] for i in 1:4), MOI.LessThan(2.0))
    MOI.optimize!(model)
    x_sol = MOI.get(model, MOI.VariablePrimal(), x)
    @test ≈(x_sol, [0.9, 0, 0.9, 0.2]; atol = 1e-3)
    return
end

function test_knapsack_min()
    P = Float64[1 0 0 0; 0 1 1 0; 0 0 1 1; 0 1 0 0]
    model = MOO.Optimizer(HiGHS.Optimizer)
    MOI.set(model, MOO.Algorithm(), MOO.Hierarchical())
    MOI.set.(model, MOO.ObjectivePriority.(1:4), [2, 1, 1, 0])
    MOI.set.(model, MOO.ObjectiveWeight.(1:4), [1, 0.5, 0.5, 1])
    MOI.set(model, MOO.ObjectiveRelativeTolerance(1), 0.1)
    MOI.set(model, MOI.Silent(), true)
    x = MOI.add_variables(model, 4)
    MOI.add_constraint.(model, x, MOI.GreaterThan(0.0))
    MOI.add_constraint.(model, x, MOI.LessThan(1.0))
    MOI.set(model, MOI.ObjectiveSense(), MOI.MIN_SENSE)
    f = MOI.Utilities.operate(vcat, Float64, -P * x...)
    MOI.set(model, MOI.ObjectiveFunction{typeof(f)}(), f)
    MOI.add_constraint(model, sum(1.0 * x[i] for i in 1:4), MOI.LessThan(2.0))
    MOI.optimize!(model)
    x_sol = MOI.get(model, MOI.VariablePrimal(), x)
    @test ≈(x_sol, [0.9, 0, 0.9, 0.2]; atol = 1e-3)
    return
end

end

TestHierarchical.run_tests()
