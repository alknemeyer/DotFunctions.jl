# `DotFunctions.jl`
_Because sometimes I miss the function chaining syntax available in other languages_

This module defines a wrapper type `DotFunction` which stores a function (`func`), `data` and a flag to help with printing (`isfirst`). It overloads `Base.getproperty` so that, if dotted for a field that it doesn't itself have (eg. `mystruct.myfield`), it evals that field in `Base.Main` and puts the result in its `func` slot. When called, it applies `func` to its arguments. The whole thing is a hack, but the way it handles broadcasting is _especially_ hacky.

Example usage:

```julia
julia> add(args...) = +(args...);
julia> DotFunction([0.25, 0.5, 1]).inv.().sum().add(2, 3).Int()
┌<─ [0.25, 0.5, 1.0]
├─> [4.0, 2.0, 1.0]               (inv)
├─> 7.0                           (sum)
├─> 12.0                          (add)
├─> 12                            (Int64)
└─> DotFunction(identity, 12)

# same result as:
Int(add(sum(inv.([0.25, 0.5, 1])), 2, 3))
# or
[0.25, 0.5, 1] |> x -> inv.(x) |> sum |> x -> add(x, 2, 3) |> Int
# but the DotFunction looks slightly better 😎

# another example
julia> findalex(s) = findfirst("alex", s);
julia> DotFunction("My name is Alex").lowercase().findalex().collect()
┌<─ My name is Alex
├─> my name is alex               (lowercase)
├─> 12:15                         (findalex)
├─> [12, 13, 14, 15]              (collect)
└─> DotFunction(identity, [12, 13, 14...])

# put `done` at the end to get the wrapped type back
julia> DotFunction(1).add(1)
┌<─ 1
├─> 2                   (add)
└─> DotFunction(identity, 2)

julia> DotFunction(1).add(1).done
┌<─ 1
├─> 2                   (add)
└─> DotFunction(identity, 2)
2

# the printing can be activated or deactivated by using `DotFunctions.activate_printing()` and `DotFunctions.deactivate_printing()`
julia> DotFunctions.deactivate_printing();
julia> DotFunctions.DotFunction([1,2,3]).sum().done
6
```

## Benchmarking
Unfortunately, this is super slow and shouldn't be used for anything aside from a bit of fun. I'm not super sure why it's so slow, but I imagine it has something to do with the `eval`

```julia
function cool_version😎(input)
    DotFunction(input).inv.().sum().add(2, 3).floor().Int().done
end
function cool_but_too_many_xs(input)
    input |> x -> inv.(x) |> sum |> x -> add(x, 2, 3) |> floor |> Int
end
function lame!_barely_comprehensible!(input)
    Int(floor(add(sum(inv.(input)), 2, 3)))
end

function benchmark(nloops, N)
    DotFunctions.deactivate_printing()
    s = 0
    x = randn(N)
    @time for i = 1:nloops
        s += cool_version😎(x)
    end
    @time for i = 1:nloops
        s += cool_but_too_many_xs(x)
    end
    @time for i = 1:nloops
        s += lame!_barely_comprehensible!(x)
    end
end

# after a warmup round...
julia> benchmark(3, 100)
  0.134172 seconds (3.81 k allocations: 301.031 KiB)  # :/
  0.000002 seconds (9 allocations: 2.719 KiB)
  0.000014 seconds (9 allocations: 2.719 KiB)

julia> benchmark(3, 1000_000)
  0.151548 seconds (3.81 k allocations: 23.180 MiB, 7.42% gc time) # "scales well"
  0.048111 seconds (12 allocations: 22.889 MiB, 77.85% gc time)
  0.013416 seconds (12 allocations: 22.889 MiB, 16.31% gc time)

julia> benchmark(10, 10_000_000)
  0.892709 seconds (12.71 k allocations: 763.912 MiB, 12.63% gc time)
  0.422378 seconds (40 allocations: 762.941 MiB, 16.71% gc time)
  0.436450 seconds (40 allocations: 762.941 MiB, 18.80% gc time)
```
