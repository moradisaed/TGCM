function [L, S] = RPCA(X, lambda, mu, tol, max_iter)
%%-- input -- %%
    % - X is a data matrix (of the size N x M) to be decomposed
    % - lambda - regularization parameter, default = 1/sqrt(max(N,M))
    % - mu - the augmented lagrangian parameter, default = 10*lambda
    % - tol - reconstruction error tolerance, default = 1e-6
    % - max_iter - maximum number of iterations, default = 1000
%%-- input -- %%
    % - L is the low-rank part of the input matrix
    % - S is the sparse part of the input matrix
    % - which M = L + S
    [M, N] = size(X);
    unobserved = isnan(X);
    X(unobserved) = 0;
    normX = norm(X, 'fro');
    
    % initial solution
    L = zeros(M, N);
    S = zeros(M, N);
    Y = zeros(M, N);
    
    for iter = (1:max_iter)
        % ADMM step: update L and S
        L = Do(1/mu, X - S + (1/mu)*Y);
        S = So(lambda/mu, X - L + (1/mu)*Y);
        %%
%         L=max(0,L);%%%%%%%%%%%%%%%%%%%%
%         S=max(0,S);%%%%%%%%%%%%%%%%%%%%%%
        % and augmented lagrangian multiplier
        Z = X - L - S;
        Z(unobserved) = 0; % skip missing values
        Y = Y + mu*Z;
        err = norm(Z, 'fro') / normX;
%         fprintf(1, 'iter: %04d\terr: %f\trank(L): %d\n', iter, err, rank(L));
        if (err < tol) break; end
    end
end

function r = So(tau, X)
    % shrinkage operator
    r = sign(X) .* max(abs(X) - tau, 0);
end

function r = Do(tau, X)
    % shrinkage operator for singular values
    [U, S, V] = svd(X, 'econ');
    r = U*So(tau, S)*V';
end
