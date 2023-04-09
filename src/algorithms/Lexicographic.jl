#  Copyright 2019, Oscar Dowson and contributors
#  This Source Code Form is subject to the terms of the Mozilla Public License,
#  v.2.0. If a copy of the MPL was not distributed with this file, You can
#  obtain one at http://mozilla.org/MPL/2.0/.

"""
    Lexicographic()

`Lexicographic()` implements a lexigographic algorithm that returns a single
point on the frontier, corresponding to solving each objective in order.

## Supported optimizer attributes

 * `MOA.LexicographicAllPermutations()`: Controls whether to return the
   lexicographic solution for all permutations of the scalar objectives (when
   `true`), or only the solution corresponding to the lexicographic solution of
   the original objective function (when `false`).

 * `MOA.ObjectiveRelativeTolerance(index)`: after solving objective `index`, a
   constraint is added such that the relative degradation in the objective value
   of objective `index` is less than this tolerance.
"""
mutable struct Lexicographic <: AbstractAlgorithm
    rtol::Vector{Float64}
    all_permutations::Bool

    function Lexicographic()
        return new(Float64[], default(LexicographicAllPermutations()))
    end
end

MOI.supports(::Lexicographic, ::ObjectiveRelativeTolerance) = true

function MOI.get(alg::Lexicographic, attr::ObjectiveRelativeTolerance)
    return get(alg.rtol, attr.index, default(alg, attr))
end

function MOI.set(alg::Lexicographic, attr::ObjectiveRelativeTolerance, value)
    for _ in (1+length(alg.rtol)):attr.index
        push!(alg.rtol, default(alg, attr))
    end
    alg.rtol[attr.index] = value
    return
end

MOI.supports(::Lexicographic, ::LexicographicAllPermutations) = true

function MOI.get(alg::Lexicographic, ::LexicographicAllPermutations)
    return alg.all_permutations
end

function MOI.set(alg::Lexicographic, ::LexicographicAllPermutations, val::Bool)
    alg.all_permutations = val
    return
end

function optimize_multiobjective!(algorithm::Lexicographic, model::Optimizer)
    sequence = 1:MOI.output_dimension(model.f)
    if !MOI.get(algorithm, LexicographicAllPermutations())
        return _solve_in_sequence(algorithm, model, sequence)
    end
    solutions = SolutionPoint[]
    for sequence in Combinatorics.permutations(sequence)
        status, solution = _solve_in_sequence(algorithm, model, sequence)
        if !_is_scalar_status_optimal(status)
            return status, nothing
        end
        push!(solutions, solution[1])
    end
    sense = MOI.get(model.inner, MOI.ObjectiveSense())
    return MOI.OPTIMAL, filter_nondominated(sense, solutions)
end

function _solve_in_sequence(
    algorithm::Lexicographic,
    model::Optimizer,
    sequence::AbstractVector{Int},
)
    variables = MOI.get(model.inner, MOI.ListOfVariableIndices())
    constraints = Any[]
    scalars = MOI.Utilities.eachscalar(model.f)
    for i in sequence
        f = scalars[i]
        MOI.set(model.inner, MOI.ObjectiveFunction{typeof(f)}(), f)
        MOI.optimize!(model.inner)
        status = MOI.get(model.inner, MOI.TerminationStatus())
        if !_is_scalar_status_optimal(status)
            return status, nothing
        end
        X, Y = _compute_point(model, variables, f)
        rtol = MOI.get(algorithm, ObjectiveRelativeTolerance(i))
        set = if MOI.get(model.inner, MOI.ObjectiveSense()) == MOI.MIN_SENSE
            MOI.LessThan(Y + rtol * abs(Y))
        else
            MOI.GreaterThan(Y - rtol * abs(Y))
        end
        push!(constraints, MOI.add_constraint(model, f, set))
    end
    X, Y = _compute_point(model, variables, model.f)
    for c in constraints
        MOI.delete(model, c)
    end
    return MOI.OPTIMAL, [SolutionPoint(X, Y)]
end
