# perf_exercise.jl
#
# ECON 5010 — Performance Optimization Exercise
# ------------------------------------------------
# Every function below computes something simple and correct, but each
# one is written in a way that makes Julia run much slower than it
# needs to.
#
# YOUR TASK:
#   1. Run `main()` once and note the @time output (baseline).
#   2. Profile the code — use @time / @btime (BenchmarkTools.jl),
#      @code_warntype, and/or @allocated / --track-allocation — to find
#      the bottlenecks in each function.
#   3. Rewrite each function so it runs faster and allocates less
#      memory, WITHOUT changing what it computes. (Your output values
#      should match the originals.)
#   4. Be ready to explain, for each fix: what was slow, why, and how
#      you fixed it.
#
# Hints on what to look for (this is most of what you'll need to know
# about Julia performance):
#   - Non-constant global variables
#   - Containers that don't have a concrete element type
#   - Allocating memory inside a loop when you don't need to
#   - Copying data (e.g. via slicing) when a view would do
#   - Growing a plain array one element at a time
#   - Type instability (a variable that can hold more than one type)
#
# You will not need every hint for every function.

using Random
using Statistics

# --- Global state used directly inside the functions below ---
N = 2_000_000
data = rand(N)

# 1. Summary statistics
function compute_stats()
    results = []
    push!(results, sum(data))
    push!(results, mean(data))
    push!(results, maximum(data))
    push!(results, minimum(data))
    push!(results, std(data))
    return results
end

# 2. Monte Carlo estimate of pi
function monte_carlo_pi(n)
    count = 0
    for i in 1:n
        point = [rand(), rand()]
        if point[1]^2 + point[2]^2 <= 1.0
            count += 1
        end
    end
    return 4 * count / n
end

# 3. Row sums of a matrix
function row_sums(A)
    n = size(A, 1)
    sums = []
    for i in 1:n
        row = A[i, :]
        push!(sums, sum(row))
    end
    return sums
end

# 4. Build a text report
function build_report(labels, values)
    report = ""
    for i in 1:length(labels)
        report = report * labels[i] * ": " * string(values[i]) * "\n"
    end
    return report
end

# 5. Conditional accumulator
function unstable_sum(xs)
    total = 0
    for x in xs
        if x > 0.5
            total += x
        else
            total += 0
        end
    end
    return total
end

function main()
    println("Computing stats...")
    stats = compute_stats()
    println(stats)

    println("Estimating pi...")
    pi_est = monte_carlo_pi(1_000_000)
    println(pi_est)

    println("Computing row sums...")
    A = rand(2000, 2000)
    sums = row_sums(A)
    println(sums[1:5])

    println("Building report...")
    labels = ["sum", "mean", "max", "min", "std"]
    report = build_report(labels, stats)
    println(report)

    println("Summing with condition...")
    println(unstable_sum(data))
end

@time main()
