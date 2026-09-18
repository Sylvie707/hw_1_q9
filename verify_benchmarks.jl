using Random
using Statistics
using InteractiveUtils

module Baseline
    # Load the exact upstream revision rather than a reconstructed baseline.
    source = read(`git show upstream/main:perf_exercise.jl`, String)
    include_string(@__MODULE__, source, "upstream_perf_exercise.jl")
end

module Optimized
    include("perf_exercise.jl")
end

const BENCHMARK_RESULT = Ref{Any}()

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
