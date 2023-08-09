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

    # 1st if block
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

        N_elif = length(elif_branches)
        has_else = isodd(N_elif)
        if has_else && length(branches) == 0 # only add else if no other branch matched
            push!(branches, elif_branches[end])
        end

    else # it was just a if-else
        if length(branches) == 0 # only add else if no other branch matched
            push!(branches, ifex.args[3])
        end
    end

    # if there was not else branch and none of the elseifs matched, then we haven't found anything
    # in that case return the first if branch
    if length(branches) == 0
        push!(branches, ifex.args[2])
    end

    return branches
end


end # module IfDef
