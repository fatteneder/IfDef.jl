module IfDef


using MacroTools


export @ifdef_str, @ifdef


macro ifdef_str(sym)
    return esc(ex -> filter_ifdef(ex, Symbol(sym)))
end


macro ifdef(ifblock)
    @assert ifblock isa Expr
    @assert ifblock.head === :if
    !(ifblock.head === :if) && return error("@ifdef must be followed by an if block")

    branches = find_in_if(ifblock, nothing)
    N = length(branches)
    if N == 0
        return nothing
    elseif N >= 1
        N > 1 && @warn "More than one '$sym' found in '@ifdef' block at ???"
        return esc(first(branches))
    end
end


filter_ifdef(ex) = filter_ifdef(ex, nothing)
function filter_ifdef(ex, sym)
    !(ex isa Expr) && return ex

    found_any = false
    ex = MacroTools.prewalk(ex) do e
        !(e isa Expr) && return e
        !(e.head === :macrocall && e.args[1] === Symbol("@ifdef")) && return e
        ifblock = e.args[3]
        !(ifblock.head === :if) && return error("@ifdef must be followed by an if block")

        branches = find_in_if(ifblock, sym)
        N = length(branches)
        if N == 0
            return nothing
        elseif N >= 1
            N > 1 && @warn "More than one '$sym' found in '@ifdef' block at ???"
            return first(branches)
        end

    end

    # TODO Warn when found_any == false

    ex = MacroTools.flatten(ex)

    ex
end


function find_in_if(ifex::Expr, sym)

    branches = []

    # if block
    @assert ifex.head === :if
    if ifex.args[1] === sym
        push!(branches, ifex.args[2])
    end
    if length(ifex.args) == 2 # done
        return branches
    end


    elif_branches = ifex.args[3].args
    # elseif blocks
    if ifex.args[3].head === :elseif
        for (i,b) in enumerate(elif_branches[1:2:end-1])
            cond = b.args[2] # 1. is LineNumberNode
            if !(cond isa Symbol)
                error("non-symbol branch condition '$cond' found at ???")
            end
            if cond === sym
                push!(branches, elif_branches[2*i])
            end
        end
    end

    # else
    N_elif_branches = length(elif_branches)
    has_else = isodd(div(N_elif_branches,2)) #|| length(elif_branches) == 0
    if length(branches) == 0
        if has_else
            push!(branches, elif_branches[end])
        else
            push!(branches, ifex.args[2])
        end
    end

    return branches
end


end # module IfDef
