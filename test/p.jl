n = 30000

@everywhere function get_vector(n)
    ones(n)
end



tic()
x = zeros(n)
for i=1:n
    x = x + get_vector(n) * i
end
println(x[1])
toc()



tic()
x = zeros(n)
x = @parallel (+) for i=1:n
        get_vector(n) * i
    end
println(x[1])
toc()
