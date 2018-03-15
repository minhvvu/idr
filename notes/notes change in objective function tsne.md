### Change in objective function


#### Summary
Testing the idea of a new penalty term for the objective function of tsne:
+ The simplest approach is using L2 penalty, but we have to find the regularization constant manually.
+ Another approach is to try to convert the distance between the fixed points and its old neighbors by introducing a gaussian or a student t distribution at the location of the fixed point. The intuition behind this idea is that, if a point $y_j$ is neighbor of a point $y_i$, it should have large likelihood to be still neighbor of this point at the new position $y_i^{\prime}$.
+ This way we can minimize the KL divergence and maximize the above likelihoods at the same time, that forces the neighbors of the fixed points move closer to the new position of the fixed points to preserve the neighborhood relation.
+ The params are found manually when experimenting on the small MNIST dataset.

#### 1. Using Student t-distribution around the fixed points
> Updated 15/03/2018

+ For each fixed point ${y_{i}^{\prime}}$, find its `k` nearest neighbors ${y_{j}}$ based on its old position ${y_{i}}$.

+ Convert the distance between $y_i^{\prime}$ and $y_j$ into the probability by using a student t distribution with a degree of freedom $\nu=1$, a centre $\mu$ at the new position $y_i^{\prime}$ and a scale $\sigma$ as a param:

<!-- $$
    p({y_j} | {y_i^{\prime}}) =
    \frac{1}{\pi} \left[
        1 + \frac{1}{\nu} \left(
            \frac{|{red}{y_j} - {y_i^{\prime}}||}{\sigma}
        \right)^{2}
    \right]^{-\frac{\nu+1}{2}}
$$ -->

$$
    p({y_j} | {y_i^{\prime}}) \propto
    \left(
        1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
            {\sigma^2}
    \right)^{-1}
$$

Let $p({y_j} | {y_i^{\prime}})$ be the probability that a single neighbor $y_j$ of the old point $y_i$ being still attracted by the new position $y_i^{\prime}$.

> We omit the normalized constant in the formula of t distribution beacause when we take the log, it becomes an additional (unnecessary) term.


+ The likelihood that all the `k` neighbors of $y_i$ are still attracted by the new position $y_i^{\prime}$, is a joint distribution
$p(y_1, \dots, y_k | y_i^{\prime}) = \prod_{j=1}^{k}p(y_j|y_i^{\prime})$.

+ We wish to maximize this likelihood for each fixed point $y_i^{\prime}$, that can be achieved by <mark> minimizing the negative log likelihood of the above joint distribution </mark>.

+ We introduce a new term in the objective function of `tsne`:
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \left( - \log \prod_{j}^{k} p(y_j|y_i^{\prime}) \right) $$
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \left( - \sum_{j}^{k} \log p(y_j|y_i^{\prime}) \right) $$
$$ C = KL(P || Q^{\prime}) + \sum_{i}^{m} \sum_{j}^{k} \log \left(
        1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
            {\sigma^2}
    \right)
$$

> $Q^{\prime}$ is calculated based on the new position of `m` fixed points.
> Note that, we do not have a regularization constant, to avoid the domination of the log likelihood, we have to set the scale $\sigma^2$ very large.

+ When calculate gradient for the neighbor points $y_j$, we add the following term:
$$ \frac{\partial}{\partial{y_j}}
    \left(- \log p(y_j | y_i^{\prime}) \right)
$$
$$ = \frac{\partial}{\partial{y_j}}
    \log \left(
        1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
            {\sigma^2}
    \right)
$$
$$ = \frac{\partial}{\partial{y_j}}
        \left(
            1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
                {\sigma^2}
        \right)
    \left(
            1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
                {\sigma^2}
    \right)^{-1}

$$
$$ = \frac{2}{\sigma^2} ({y_j} - {y_i^{\prime}})
    \left(
        1 + \frac{|| {y_j} - {y_i^{\prime}}||^2}
            {\sigma^2}
    \right)^{-1}
$$

> The current value of $\sigma^2$ that gives us a clear result on the small MNIST dataset is around `1e5`

Before moving              |  After moving
:-------------------------:|:-------------------------:
![mnist01](/home/vmvu/Pictures/exp1503/mnist_move1.png)| ![mnist01](/home/vmvu/Pictures/exp1503/mnist_move1_result.png)

> The value the likelihood term is ploted (and named `penalty`). We do not see the large change after moving 5 points.
![mnist01](/home/vmvu/Pictures/exp1503/mnist_cost1_errors.png) ![mnist01](/home/vmvu/Pictures/exp1503/mnist_cost1_gradient_norms.png)


#### 2. Using Gaussian distribution around the fixed points
> Updated 14/03/2018

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
        || {y_j} - {y_i^{\prime}}||^2
$$

+ This way, we can replace the `regularization term` in the approach [using L2 penalty](#3-using-l2-regularization-term) by $\frac{1}{2 \sigma^2}$.

> Some values of $\sigma^{2}$ in range `[1e3, 1e5]` give a clear result.

+ The additional gradient for each neighbor point $y_j$ is the partial derivative of the negative log likelihood w.r.t. $y_j$, that is exactly the same as using L2-penalty.
$$ \frac{\partial}{\partial{y_j}}
    \left(- \log p(y_j | y_i^{\prime}) \right)
$$
$$ = \frac{\partial}{\partial{y_j}}
    \left( \frac{1}{ 2 \sigma^2} || y_j - y_i^{\prime} ||^2 \right)
$$
$$ = \frac{1}{ \sigma^2}(y_j - y_i^{\prime})
$$

#### 3. Using L2-regularization term
> Updated 09/03/2018

+ Suppose that the new positions of the fixed points as ${y}^{\prime}$.

+ Update the new positions of ${y}^{\prime}$ into the current embedding coordinates to calculate new $\textbf{Q}^{\prime}$

+ Add a new regularization term (L2-penalty) to the objective function
\begin{equation}
    {\sum_{i=1}^{m}}
    {\sum_{j=1}^{k}}
    || {y_{i}^{\prime}} - {y_{j}} ||^{2}
\end{equation}
in which `m` is the number of fixed points and `k` is the number of neighbors around each fixed point.
Testing with the value of `k` is `5%` total number of data points.

+ The new objective function
\begin{equation}
    C = KL (P || \textbf{Q}^{\prime}) +
        \frac{\lambda}{{m}{k}} 
        {\sum_{i=1}^{m}}
        {\sum_{j=1}^{k}}
        || {y_{i}^{\prime}} - {y_{j}} ||^{2}
\end{equation}
Test with `MNIST-small` dataset, $\lambda = 1e-3$ gives us a clear result.

+ Calculate gradient for each points, that is the derivative of the new objective function with respect to each data points.
    * For the fixed points ${y_{i}^{\prime}}$, we do not expect theirs positions will be changed anymore, so we fix their gradients to zero
    $$\frac{\partial C}{ \partial {y_{i}^{\prime}} } = 0$$

    * Repeat `m` times: for each neighbor ${y_{j}}$ of the fixed points ${y_{i}^{\prime}}$
    \begin{equation}
        \frac{\partial C}{\partial {y_{j}}} = 
            \frac{\partial KL}{\partial {y_{j}}} +
            \frac{-2 \lambda}{{k}} 
            ( {y_{i}^{\prime}} - {y_{j}} )
    \end{equation}


+ Some minor changes with params of `tsne`:
    * `perplexity=30.0`
    * `early_exaggeration=12.0` (in `sklearn`: 12.0; in the original paper: 4.0)
    * `learning_rate=100.0` (default in `sklearn`: 200.0, in the original paper: 100.0)