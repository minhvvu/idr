### Change in objective function

#### 1. Using L2-regularization term

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


#### 2. Using Student t-distribution arround the fixed points
+ For each fixed point $\color{blue}{y_{i}^{\prime}}$, find its `k` nearest neighbors $\color{red}{y_{j}}$ based on its old position $\color{blue}{y_{i}}$.

+ Convert the distance between $y_i^{\prime}$ and $y_j$ into the probability by using a student t-distribution with a degree of freedom $\nu=1$, a centre $\mu$ at the new position $y_i^{\prime}$ and a scale $\sigma$ as a param:

##TODO: check the constant param $(1/(pi*sigma))$ of the t-distribution

<!-- $$
    p(\color{red}{y_j} | \color{blue}{y_i^{\prime}}) =
    \frac{1}{\pi} \left[
        1 + \frac{1}{\nu} \left(
            \frac{||\color{red}{y_j} - \color{blue}{y_i^{\prime}}||}{\sigma}
        \right)^{2}
    \right]^{-\frac{\nu+1}{2}}
$$ -->

$$
    p(\color{red}{y_j} | \color{blue}{y_i^{\prime}}) \propto
    \left(
        1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
            {\sigma^2}
    \right)^{-1}
$$

We say $p(\color{red}{y_j} | \color{blue}{y_i^{\prime}})$ is the probability that a single neighbor $y_j$ of the old point $y_i$ being still attracted by the new position $y_i^{\prime}$.

+ The likelihood that all the `k` neighbors of $y_i$'s are still attracted by the new position $y_i^{\prime}$ is a joint distribution
$p(y_1, \dots, y_k | y_i^{\prime}) = \prod_{j=1}^{k}p(y_j|y_i^{\prime})$.

+ We wish to maximize this likelihood for each fixed point $y_i^{\prime}$, that can be achieved by minimizing the negative log likelihood of the above joint distributions.

+ We introduce a new term in the objective function of `tsne`:
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \left( - \log \prod_{j}^{k} p(y_j|y_i^{\prime}) \right) $$
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \left( - \sum_{j}^{k} \log p(y_j|y_i^{\prime}) \right) $$
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \sum_{j}^{k} \log \left(
        1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
            {\sigma^2}
    \right)
$$

+ When calculate gradient for the neighbor points $y_j$, we add the following term:
$$ \frac{\partial}{\partial{y_j}}
    \left(- \log p(y_j | y_i^{\prime}) \right)
$$
$$ = \frac{\partial}{\partial{y_j}}
    \log \left(
        1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
            {\sigma^2}
    \right)
$$
$$ = \frac{\partial}{\partial{y_j}}
        \left(
            1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
                {\sigma^2}
        \right)
    \left(
            1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
                {\sigma^2}
    \right)^{-1}

$$
$$ = \frac{2}{\sigma^2} (\color{red}{y_j} - \color{blue}{y_i^{\prime}})
    \left(
        1 + \frac{|| \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2}
            {\sigma^2}
    \right)^{-1}
$$


#### 3. Using Gaussian distribution arround the fixed points
+ Using the same setting as used with the t-distribution, we define the probability that a point $y_j$ being still a neighbor of new fixed point $y_i^{\prime}$ as
$$
    p(y_j | y_i^{\prime}) = \frac{1}{\sqrt{2 \pi \sigma^2}}
        \exp \left( \frac{- || y_j - y_i^{\prime} ||^2 }{ 2 \sigma^2} \right)
$$

$$
    \log p(y_j | y_i^{\prime}) = \frac{-1}{2 \sigma^2} || y_j - y_i^{\prime} ||^2 - constant
$$

+ The additional goal is to minimize the negative log likelihood of the joint distribution of the neighbors given the fixed points.
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \left( - \log \prod_{j}^{k} p(y_j|y_i^{\prime}) \right) $$
$$
    C = KL(P || Q^{\prime}) + \frac{1}{2 \sigma^2} \sum_{i}^{m} \sum_{j}^{k}
        || \color{red}{y_j} - \color{blue}{y_i^{\prime}}||^2
$$