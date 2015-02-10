
function foo(value)

    x = value
    include("bar.jl")

    println(bar(10))

end
