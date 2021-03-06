
@everywhere using ComputeFramework

@everywhere logistic(x) = 1 / (1 + exp(-x))

"""
Distributed logistic regression on tall and skinny matrices
"""
function dist_glm(ctx, X, y, tol = 1e-12, maxIter = 10)

    XtX, Xtr = gather(ctx, (X'X, X'y))

    β = cholfact!(XtX) \ Xtr
    μ = X*β
    k = 0
    for k = 1:maxIter
        η = map(logistic, μ)
        w = η.*(1-η)
        r = y - η
        Xw = scale(w, X)

        XtX, Xtr = gather(ctx, (Xw'X, X'r)) # this is where actual computation occurs
        Δβ = cholfact!(XtX) \ Xtr
        
        β += Δβ

        if (@show norm(Δβ)) < tol
            break
        end
        μ = X*β
    end
    if k == maxIter
        error("no convergence")
    end
    return β, k
end

X = load(Context(), "X")
y = load(Context(), "y")
#@time @show dist_glm(Context(), X, y)
@time @show dist_glm(Context(), X, y)

