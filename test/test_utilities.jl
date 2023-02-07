#  Copyright 2019, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public License,
#  v.2.0. If a copy of the MPL was not distributed with this file, You can
#  obtain one at http://mozilla.org/MPL/2.0/.

module TestUtilities

using Test

import MultiObjectiveAlgorithms

const MOA = MultiObjectiveAlgorithms
const MOI = MOA.MOI

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

function test_filter_nondominated()
    x = Dict{MOI.VariableIndex,Float64}()
    solutions = [MOA.SolutionPoint(x, [0, 1]), MOA.SolutionPoint(x, [1, 0])]
    @test MOA.filter_nondominated(solutions) == solutions
    return
end

function test_filter_nondominated_sort_in_order()
    x = Dict{MOI.VariableIndex,Float64}()
    solutions = [MOA.SolutionPoint(x, [0, 1]), MOA.SolutionPoint(x, [1, 0])]
    @test MOA.filter_nondominated(reverse(solutions)) == solutions
    return
end

function test_filter_nondominated_remove_duplicates()
    x = Dict{MOI.VariableIndex,Float64}()
    solutions = [MOA.SolutionPoint(x, [0, 1]), MOA.SolutionPoint(x, [1, 0])]
    @test MOA.filter_nondominated(solutions[[1, 1]]) == [solutions[1]]
    return
end

function test_filter_nondominated_weakly_dominated()
    x = Dict{MOI.VariableIndex,Float64}()
    solutions = [
        MOA.SolutionPoint(x, [0, 1]),
        MOA.SolutionPoint(x, [0.5, 1]),
        MOA.SolutionPoint(x, [1, 0]),
    ]
    @test MOA.filter_nondominated(solutions) == solutions[[1, 3]]
    solutions = [
        MOA.SolutionPoint(x, [0, 1]),
        MOA.SolutionPoint(x, [0.5, 1]),
        MOA.SolutionPoint(x, [0.75, 1]),
        MOA.SolutionPoint(x, [0.8, 0.5]),
        MOA.SolutionPoint(x, [0.9, 0.5]),
        MOA.SolutionPoint(x, [1, 0]),
    ]
    @test MOA.filter_nondominated(solutions) == solutions[[1, 4, 6]]
    return
end

end

TestUtilities.run_tests()
