### Change in objective function

+ Suppose that the new positions of the fixed points as $\color{blue}{y}^{\prime}$.

+ Update the new positions of $\color{blue}{y}^{\prime}$ into the current embedding coordinates to calculate new $\textbf{Q}^{\prime}$

+ Add a new regularization term (L2-penalty) to the objective function
\begin{equation}
    \color{blue}{\sum_{i=1}^{m}}
    \color{red}{\sum_{j=1}^{k}}
    || \color{blue}{y_{i}^{\prime}} - \color{red}{y_{j}} ||^{2}
\end{equation}
in which `m` is the number of fixed points and `k` is the number of neighbors around each fixed point.
Testing with the value of `k` is `5%` total number of data points.

+ The new objective function
\begin{equation}
    C = KL (P || \textbf{Q}^{\prime}) +
        \frac{\lambda}{\color{blue}{m}\color{red}{k}} 
        \color{blue}{\sum_{i=1}^{m}}
        \color{red}{\sum_{j=1}^{k}}
        || \color{blue}{y_{i}^{\prime}} - \color{red}{y_{j}} ||^{2}
\end{equation}
Test with `MNIST-small` dataset, $\lambda = 1e-3$ gives us a clear result.

+ Calculate gradient for each points, that is the derivative of the new objective function with respect to each data points.
    * For the fixed points $\color{blue}{y_{i}^{\prime}}$, we do not expect theirs positions will be changed anymore, so we fix their gradients to zero
    $$\frac{\partial C}{ \partial \color{blue}{y_{i}^{\prime}} } = 0$$

    * Repeat `m` times: for each neighbor $\color{red}{y_{j}}$ of the fixed points $\color{blue}{y_{i}^{\prime}}$
    \begin{equation}
        \frac{\partial C}{\partial \color{red}{y_{j}}} = 
            \frac{\partial KL}{\partial \color{red}{y_{j}}} +
            \frac{-2 \lambda}{\color{red}{k}} 
            ( \color{blue}{y_{i}^{\prime}} - \color{red}{y_{j}} )
    \end{equation}


+ Some minor changes with params of `tsne`:
    * `perplexity=30.0`
    * `early_exaggeration=12.0` (in `sklearn`: 12.0; in the original paper: 4.0)
    * `learning_rate=100.0` (default in `sklearn`: 200.0, in the original paper: 100.0)