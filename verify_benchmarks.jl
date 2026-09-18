using Random
using Statistics
using InteractiveUtils

# Comparison: all five function checks passed on Julia 1.12.7.
# Recorded warm medians for compute_stats: 1.2284 ms -> 0.8898 ms (~28% less).
# Both measurements allocated 96 bytes; allocation reduction is not claimed.
# Recorded first baseline main run: 0.291382 s, 76.127 MiB (includes compilation).
# The partner already optimized the other functions; their timing varies between runs.

module Baseline
    # Use the pinned snapshot so verification also works without a local Git repository.
    include("perf_exercise_baseline.jl")
end

module Optimized
    include("perf_exercise.jl")
end

const BENCHMARK_RESULT = Ref{Any}()
# Consuming results prevents unused work from being removed. Measurement totals
# include this helper's overhead, such as boxing scalar return values.

@noinline function consume(f)
    BENCHMARK_RESULT[] = f()
    return nothing
end

function measure(f; repeats=7)
    f()
    times = Float64[]
    bytes = Int[]
    for _ in 1:repeats
        GC.gc()
        result = @timed consume(f)
        push!(times, result.time)
        push!(bytes, result.bytes)
    end
    return median(times), median(bytes)
end

function verify_and_benchmark()
    rng = MersenneTwister(5010)
    xs = rand(rng, 2_000_000)
    A = rand(rng, 2000, 2000)
    labels = ["sum", "mean", "max", "min", "std"]
    old_stats = Baseline.compute_stats(xs)
    new_stats = Optimized.compute_stats(xs)
    @assert isapprox(old_stats, new_stats; rtol=1e-12)
    @assert Baseline.row_sums(A) == Optimized.row_sums(A)
    @assert Baseline.build_report(labels, old_stats) == Optimized.build_report(labels, old_stats)
    @assert Baseline.unstable_sum(xs) == Optimized.unstable_sum(xs)
    Random.seed!(5010)
    old_pi = Baseline.monte_carlo_pi(100_000)
    Random.seed!(5010)
    @assert old_pi == Optimized.monte_carlo_pi(100_000)
    println("All five function equivalence checks passed.")
    println("Julia version: ", VERSION)
    println("Warm-run medians from seven repetitions; compilation excluded.")
    cases = [
        ("compute_stats", () -> Baseline.compute_stats(xs), () -> Optimized.compute_stats(xs)),
        ("monte_carlo_pi", () -> Baseline.monte_carlo_pi(1_000_000), () -> Optimized.monte_carlo_pi(1_000_000)),
        ("row_sums", () -> Baseline.row_sums(A), () -> Optimized.row_sums(A)),
        ("build_report", () -> Baseline.build_report(labels, old_stats), () -> Optimized.build_report(labels, old_stats)),
        ("unstable_sum", () -> Baseline.unstable_sum(xs), () -> Optimized.unstable_sum(xs)),
    ]
    for (name, old, new) in cases
        old_time, old_bytes = measure(old)
        new_time, new_bytes = measure(new)
        println(name, ": baseline_ms=", round(1000old_time; digits=4),
            ", optimized_ms=", round(1000new_time; digits=4),
            ", baseline_bytes=", old_bytes, ", optimized_bytes=", new_bytes)
    end
    println("Type inference for optimized compute_stats:")
    @code_warntype Optimized.compute_stats(xs)
end

verify_and_benchmark()
