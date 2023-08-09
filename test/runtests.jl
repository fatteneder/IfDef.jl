using Test
using IfDef


@testset "ifdef" begin

    ex = quote
        @ifdef if case1
            y = 1
        else
            y = 3
        end
        y += 1
    end
    @test eval(IfDef.filter_ifdef(ex, :case1))  == 2
    @test eval(IfDef.filter_ifdef(ex, nothing)) == 4

    ex = quote
        @ifdef if case1
            y = 1
        elseif case2
            y = 2
        else
            y = 3
        end
        y += 1
    end
    @test eval(IfDef.filter_ifdef(ex, :case1))  == 2
    @test eval(IfDef.filter_ifdef(ex, :case2))  == 3
    @test eval(IfDef.filter_ifdef(ex, nothing)) == 4

    @test include(ifdef"case1", "mwe.jl") == 2
    @test include(ifdef"case2", "mwe.jl") == 3
    # case3 not defined -- fall back to either else branch or first branch
    @test include(ifdef"case3", "mwe.jl") == 4
    # fall back to either else branch or first branch
    @test include("mwe.jl") == 4

    @test include(ifdef"case1", "mwe.jl") == 2
    # case3 not defined -- fall back to either else branch or first branch
    @test include(ifdef"case3", "mwe.jl") == 4
    # fall back to either else branch or first branch
    @test include("mwe.jl") == 4

    # TODO Error handling

end
