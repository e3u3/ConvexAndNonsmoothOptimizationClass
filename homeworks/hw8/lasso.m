
function h = lasso(A,b, lambda, rho)

% Global constants and defaults

MAX_ITER = 100;
ABSTOL   = 1e-4;
RELTOL   = 1e-2;

% cached computations
AtA = A'*A;
Atb = A'*b;

%rho = 1;

[m n] = size(A);


gamma_max = norm(A'*b,'inf');
gamma = 0.1*gamma_max;

tic

% CVX

cvx_begin quiet
    cvx_precision low
    variable x(n)
    minimize(0.5*sum_square(A*x - b) + gamma*norm(x,1))
cvx_end


h.x_cvx = x;
h.p_cvx = cvx_optval;
h.cvx_toc = toc;


% ADMM method

tic

x = zeros(n,1);
z = zeros(n,1);
u = zeros(n,1);

[L U] = factor(A, rho);


h.x_cvx = x;
h.p_cvx = cvx_optval;
h.cvx_toc = toc;
for k = 1:MAX_ITER
    
    % x-update
    q = Atb + rho*(z - u);
    if m >= n
        x = U \ (L \ q);
    else
        x = lambda*(q - lambda*(A'*(U \ ( L \ (A*q) ))));
    end
    
    % z-update
    zold = z;
    z = prox_l1(x + u, lambda*gamma);
    
    % u-update
    u = u + x - z;
    
    % diagnostics, reporting, termination checks
    h.admm_optval(k)   = objective(A, b, gamma, x, z);
    h.r_norm(k)   = norm(x - z);
    h.s_norm(k)   = norm(-rho*(z - zold));
    h.eps_pri(k)  = sqrt(n)*ABSTOL + RELTOL*max(norm(x), norm(-z));
    h.eps_dual(k) = sqrt(n)*ABSTOL + RELTOL*norm(rho*u);
    
    if h.r_norm(k) < h.eps_pri(k) && h.s_norm(k) < h.eps_dual(k)
        break;
    end
    
end

h.x_admm = z;
h.p_admm = h.admm_optval(end);
h.admm_toc = toc;

end
