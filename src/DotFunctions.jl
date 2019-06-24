module DotFunctions

export DotFunction
struct DotFunction{T,U}
    func::T
    data::U
    isfirst::Bool
end
DotFunction(data) = DotFunction(identity, data, true)
DotFunction(data, isfirst) = DotFunction(identity, data, isfirst)

"""Whether all the intermediate steps should be printed.
   Not exported to avoid type piracy"""
EXCESSIVE_PRINTING = true
activate_printing() = (global EXCESSIVE_PRINTING; EXCESSIVE_PRINTING = true)
deactivate_printing() = (global EXCESSIVE_PRINTING; EXCESSIVE_PRINTING = false)

"""A simple cache to avoid having to run `eval` every time"""
const FUNC_CACHE = Dict{Symbol,Union{Function,Type}}()

function Base.getproperty(f::DotFunction, field::Symbol)
    if field in fieldnames(DotFunction)
        return getfield(f, field)
    elseif field == :done
        global EXCESSIVE_PRINTING
        EXCESSIVE_PRINTING && println(f)
        return f.data
    else
        global FUNC_CACHE
        func = get!(FUNC_CACHE, field) do
            Base.eval(Base.Main, field)
        end
        return DotFunction(func, f.data, f.isfirst)
    end
end
function (f::DotFunction)(args...)
    # # TODO: test this! DotFunction(1).(x -> x + 1)
    # if !(isempty(args)) && args[1] isa Function && f.func == identity
    #     if length(args) == 1
    #         args[1](f.data)
    #     else
    #         args[1](f.data, args[2:end]...)
    #     end
    # end

    # avert your eyes!
    if occursin("_broadcast", string(stacktrace()[2].func))
        out = f.func.(f.data, args...)
    else
        out = f.func(f.data, args...)
    end
    
    # not important - just makes things print nicely
    global EXCESSIVE_PRINTING
    if EXCESSIVE_PRINTING
        f.isfirst && println("┌<─ ", f.data)
        println("├─> ", rpad(limit_length(out, 28), 30), "(", f.func, ")")
    end
    
    return DotFunction(out, false)
end
function Base.show(io::IO, f::DotFunction)
    global EXCESSIVE_PRINTING
    EXCESSIVE_PRINTING && print(io, "└─> ")
    print(io, "DotFunction(", f.func, ", ", limit_length(f.data, 15), ")")  # ? show .isfirst field?
end

function limit_length(data, len)
    s = string(data)
    if length(s) > len
        return string(s[1:len-4], "...", s[end])
    else
        return s
    end
end

end # module
