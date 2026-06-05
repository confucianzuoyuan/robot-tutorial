#import "@preview/orange-book:0.6.1": (
  appendices, book, chapter, corollary, definition, example, exercise, index, make-index, my-bibliography, notation,
  part, problem, proposition, remark, scr, theorem, update-heading-image, vocabulary,
)
#import "@preview/gentle-clues:1.2.0": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/mannot:0.3.1": *
#import "@preview/cetz:0.5.2"
#import "@preview/cetz-plot:0.1.4": chart, plot
#import "@preview/algo:0.3.6": algo, code, comment, d, i
#import "@preview/fletcher:0.5.8" as fletcher
#import "@preview/suiji:0.5.0" as suiji
#import "@preview/neural-netz:0.2.0": draw-network
#show: codly-init.with()

#codly(languages: codly-languages)

#show: book.with(
  title: "机器人学教程",
  subtitle: "理论与实践",
  date: "Anno scolastico 2023-2024",
  author: "左元",
  main-color: rgb("#F36619"),
  lang: "zh",
  cover: image("./background.svg"),
  image-index: image("./orange1.jpg"),
  list-of-figure-title: "List of Figures",
  list-of-table-title: "List of Tables",
  supplement-chapter: "Chapter",
  supplement-part: "Part",
  part-style: 0,
  lowercase-references: false,
)

// #set par(leading: 1pt)

#show raw.where(lang: "python"): it => {
  show regex("\$(.*?)\$"): re => {
    eval(re.text, mode: "markup")
  }
  it
}

#set text(font: (
  (name: "JetBrains Mono", covers: "latin-in-cjk"),
  "FZShusong-Z01",
))

#show strong: set text(font: "FZHei-B01")
#show emph: set text(font: "FZKai-Z03")

#show raw: set text(font: (
  (name: "JetBrains Mono", covers: "latin-in-cjk"),
  "FZShusong-Z01",
))

#let colred(x) = text(fill: red, $#x$)
#let colblue(x) = text(fill: blue, $#x$)

#set list(marker: ([•], [‣]))

#part("卡尔曼滤波")

卡尔曼滤波算法是一种在存在不确定性的情况下估计和预测系统状态的强大工具，作为目标跟踪、导航与控制等应用中的基础组件被广泛使用。

尽管卡尔曼滤波是一个直观易懂的概念，但许多相关资料需要深厚的数学基础，且缺乏实用示例和图解，这使其变得比实际更为复杂。

许多现代系统利用多个传感器通过一系列测量来估计隐藏（未知）状态。例如，GPS接收器可以估计位置和速度，其中位置和速度代表隐藏状态，而来自卫星信号的到达时间差则作为测量值。

跟踪与控制系统最大的挑战之一，是在存在不确定性的情况下，对隐藏状态提供准确且精确的估计。例如，GPS接收器会受到测量不确定性的影响，这些不确定性由外部因素引起，如热噪声、大气效应、卫星位置的微小变化、接收器时钟精度等。

卡尔曼滤波器是一种广泛使用的估计算法，在许多领域都发挥着关键作用。它旨在估计系统的隐藏状态，即使测量值不精确且充满不确定性。此外，卡尔曼滤波器还能基于过去的估计值预测系统的未来状态。

该滤波器以鲁道夫·E·卡尔曼（1930 年 5 月 19 日—2016 年 7 月 2 日）的名字命名。1960 年，卡尔曼发表了他著名的论文，描述了一种针对离散数据线性滤波问题的递归解决方案。

#chapter("卡尔曼滤波器简介", image: image("./orange2.jpg"), l: "kf-introduction")

== 预测的必要性

在深入讲解卡尔曼滤波器之前，我们先来理解一下跟踪与预测算法的必要性。

为了说明这一点，我们以跟踪雷达为例。

#figure(
  image("tracking-radar.pdf"),
  caption: [跟踪雷达],
)

假设跟踪周期为 5 秒。每隔 5 秒，雷达会通过定向的笔形波束对目标进行采样。

一旦雷达"访问"目标后，它便开始估算目标当前的位置和速度。雷达还会估算（或预测）目标在下一次跟踪波束时刻的位置。

未来目标位置可通过牛顿运动方程轻松计算：

$
  x = x_0 + v_0 Delta t + 1/2 a Delta t^2
$

其中：

- $x$是目标位置
- $x_0$是目标初始位置
- $v_0$是目标初始速度
- $a$是目标加速度
- $Delta t$是时间间隔（在我们的例子中为5秒钟）

在处理三维问题时，牛顿运动方程可以表示为一个方程组：

$
  cases(
    x = x_0 + v_(x 0)Delta t + 1/2 a_x Delta t^2,
    y = y_0 + v_(y 0)Delta t + 1/2 a_y Delta t^2,
    z = z_0 + v_(z 0)Delta t + 1/2 a_z Delta t^2,
  )
$

目标参数集合$x,y,z,v_x,v_y,v_z,a_x,a_y,a_z$被称为系统状态（System State）。

当前状态作为预测算法的输入，而算法的输出则是未来状态，其中包含后续时间间隔的目标参数。

上述方程组被称为动态模型或状态空间模型。动态模型描述了系统输入与输出之间的关系。

显然，若已知目标的当前状态和动态模型，预测目标的后续状态便可轻松实现。

实际上，雷达测量并非完全精确。它包含随机误差或不确定性，这些因素可能影响预测目标状态的准确性。误差的大小取决于多种因素，例如雷达校准、波束宽度以及回波信号的信噪比。雷达测量中的随机误差或不确定性被称为测量噪声。

此外，由于风、空气湍流和飞行员机动等外部因素，目标运动并不总是与运动方程保持一致。运动方程与实际目标运动之间的这种偏差会导致动态模型中出现误差或不确定性，这被称为过程噪声。

由于测量噪声和过程噪声的存在，估计的目标位置可能与实际目标位置相差甚远。在这种情况下，雷达可能会将跟踪波束指向错误的方向，从而错过目标。

为了提高雷达的跟踪精度，必须采用一种能够同时考虑过程不确定性和测量不确定性的预测算法。

最常用的跟踪与预测算法是卡尔曼滤波器。

== 必备基础知识I

在开始之前，我想先解释几个基本术语，例如方差、标准差、正态分布、估计值、准确度、精密度、均值、隐藏状态和随机变量。

=== 隐藏状态（Hidden State）

术语隐藏状态指的是系统中无法直接观测或测量的实际状态。相反，隐藏状态必须通过可观测数据来推断，通常借助数学模型和估计技术。例如，考虑一个包含五枚硬币的场景：两枚5分硬币和三枚10分硬币。系统状态是这些硬币的平均价值。通过对硬币价值求平均，我们可以直接计算出这个平均值。

#figure(
  image("coins.pdf"),
  caption: [硬币],
)

$
  mu = 1/N sum_(n=1)^N V_n = 1/5(5+5+10+10+10)=8"分"
$


在这个例子中，结果不能被视为隐藏状态，因为系统状态（硬币价值）是已知的，且计算涉及整个总体（全部5枚硬币）。

现在假设对同一个人进行五次不同的体重测量：79.8公斤、80公斤、80.1公斤、79.8公斤和80.2公斤。这个人是一个系统，而人的体重则是系统状态。

由于秤的随机测量误差，每次测量的结果都不同。我们无法得知体重的真实值，因为它是一个隐藏状态。不过，我们可以通过平均秤的测量值来估算重量。

$
  W = 1/N sum_(n=1)^N W_n = 1/5(79.8+80+80.1+79.8+80.2)=79.98"公斤"
$

结果即为估算的系统状态。

#figure(
  image("man.pdf"),
  caption: [站在秤上的人],
)

=== 方差和标准差

方差是衡量数据集相对于其均值离散程度的指标。

标准差是方差的平方根。

标准差使用希腊字母$sigma$（sigma）表示。所以方差就是$sigma^2$。

假设我们要比较两支高中篮球队的身高。

下表列出了球员的身高以及每支球队的平均身高。

#figure(
  table(
    stroke: none,
    columns: 7,
    table.hline(),
    [], [球员1], [球员2], [球员3], [球员4], [球员5], [平均值],
    table.hline(),
    [A组], [1.89米], [2.10米], [1.75米], [1.98米], [1.85米], [1.914米],
    [B组], [1.94米], [1.90米], [1.97米], [1.89米], [1.87米], [1.914米],
    table.hline(),
  ),
  caption: [球员身高],
)

如我们所见，两支球队的平均身高相同。让我们来审视一下身高的方差。

我们还希望了解数据集相对于其均值的偏差。我们可以通过从每个变量中减去均值，来计算每个变量与均值的距离。

身高用$x$表示，身高的均值用希腊字母$mu$表示。每个变量与均值的距离为：

$
  x_n - mu = x_n - 1.914"米"
$

下表列出了每个变量与平均值的距离。

#figure(
  table(
    stroke: none,
    columns: 6,
    table.hline(),
    [], [球员1], [球员2], [球员3], [球员4], [球员5],
    table.hline(),
    [A组], [-0.024米], [0.186米], [-0.164米], [0.066米], [-0.064米],
    [B组], [0.026米], [-0.014米], [0.056米], [-0.024米], [-0.044米],
    table.hline(),
  ),
  caption: [和均值的距离],
)

其中一些值为负数。为消除负值，我们对与均值的距离进行平方运算：

$
  (x_n - mu)^2 = (x_n - 1.914"米")^2
$

下表展示了每个变量与均值的平方距离。

#figure(
  table(
    stroke: none,
    columns: 6,
    table.hline(),
    [], [球员1], [球员2], [球员3], [球员4], [球员5],
    table.hline(),
    [A组], [0.000576米], [0.034596米], [0.026896米], [0.004356米], [0.004096米],
    [B组], [0.000676米], [0.000196米], [0.003136米], [0.000576米], [0.001936米],
    table.hline(),
  ),
  caption: [和均值的平方距离],
)

要计算数据集的方差，我们需要求出所有与均值平方距离的平均值。

$
  sigma^2 = 1/N sum_(n=1)^N (x_n - mu)^2
$

对于A组，其方差为：

$
  sigma_A^2 & = 1/N sum_(n=1)^N (x_(A n) - mu)^2 \
            & = 1/5(0.000576 + 0.034596 + 0.026896 + 0.004356 + 0.004096) = 0.014"米"^2
$

对于B组，其方差为：

$
  sigma_B^2 & = 1/N sum_(n=1)^N (x_(B n) - mu)^2 \
            & = 1/5(0.000676 + 0.000196 + 0.003136 + 0.000576 + 0.001936) = 0.0013"米"^2
$

我们可以看到，虽然两支队伍的平均身高相同，但A队身高的离散程度高于B队。因此，A队球员比B队球员更具多样性。A队拥有控球手、中锋和后卫等不同位置的球员，而B队球员则缺乏多面性。方差的单位是平方米；更便捷的方式是查看标准差，即方差的平方根。

$
  sigma = sqrt(1/N sum_(n=1)^N (x_n - mu)^2)
$

- A队球员身高的标准差为0.12米。
- B队球员身高的标准差为0.036米。

现在，假设我们想要计算所有高中篮球运动员的平均值和方差。这将是一项艰巨的任务——我们需要收集每所高中每位球员的数据。

另一方面，我们可以通过选取一个大数据集并对其进行计算，来估算球员的平均值和方差。

然而，在估算方差时，方差计算的公式略有不同。我们不再使用因子$N$进行归一化，而是使用因子$N − 1$进行归一化：

$
  sigma_"sampled"^2 = 1/(N-1) sum_(n=1)^N (x_n - mu)^2
$

因子$N − 1$被称为贝塞尔校正。

可以通过询问AI来学习上面的方程的数学证明。

=== 正态分布（Normal Distribution）

事实证明，许多自然现象都遵循正态分布。正态分布，也称为高斯分布（以数学家卡尔·弗里德里希·高斯命名），由以下方程描述：

$
  f(x;mu,sigma^2) = 1/sqrt(2 pi sigma^2)exp((-(x-mu)^2)/(2 sigma^2))
$

高斯曲线也被称为正态分布的概率密度函数（Probability Density Function，PDF）。



== $alpha-beta-gamma$滤波器

== 一维卡尔曼滤波器

== 添加过程噪声

#part("现代机器人状态估计")

#chapter("概论", image: image("./orange2.jpg"), l: "robot-introduction")

#tip(title: [机器人的状态估计要解决的问题])[
  我的机器人现在在哪里？
]

- 只用GPS？$arrow.r.long$在室内、隧道、城市峡谷中无法工作
- 只用轮式编码器？$arrow.r.long$轮子打滑瞬间误差累积
- 只用IMU？$arrow.r.long$积分后每分钟发散数百米

答案：对多种传感器的数据进行概率性的融合的算法——状态估计！

#figure(
  image("2.png"),
  caption: [取各传感器之长，以其它传感器补其之短——这便是融合的本质],
)

#figure(
  image("3.png"),
  caption: [取各传感器之长，以其它传感器补其之短——这便是融合的本质],
)

#figure(
  image("4.png"),
  caption: [滤波器和平滑器],
)

#tip(title: [滤波器 vs. 平滑器])[
  #table(
    columns: 2,
    [滤波器（ESKF等）], [平滑器（因子图等）],
    [仅适用截至当前时刻的测量数据], [重复利用过去的测量值进行全局优化],
    [固定内存占用，固定计算量], [内存和计算量随着时间线性增长],
    [适用于实时控制输出], [适用于回环检测、高精度地图生成],
    [实际案例：无人机姿态控制、自动驾驶里程计], [实际案例：SLAM、SfM、离线后处理],
  )
]

在当前的实际系统中，

滤波器（ESKF）$stretch(->)^"里程计（odometry）"$平滑器（因子图）

快速里程计为SLAM提供初始值的双层结构已成为标准。

#tip(title: [为何选择ESKF])[
  误差状态卡尔曼滤波（ESKF）是实时IMU融合的事实标准。

  开源参考实现（ESKF/iEKF）：

  - OpenVINS（特拉华大学，2020）
    - 视觉-惯性里程计（Visual-Inertial Odometry）
    - MSCKF+ESKF误差状态（error-state）
  - ROVIO（苏黎世联邦理工学院，2017）
    - VIO
    - 流形上的IEKF（IEKF on manifold）
  - FAST-LIO2（香港大学MARS实验室，2022）
    - LiDAR-IMU里程计
    - $"SO"(3)$上的IEKF
  - FAST-LIVO2（香港大学MARS实验室，2024）
    - 激光雷达+视觉+惯性（LiDAR+Visual+Inertial）
    - IEKF

  ESKF相较于UKF的优势：

  - 无需Sigma点，计算量相同或者更少
  - 四元数符号问题结构性消除
  - 针对IMU积分优化的设计
  - 大量参考代码

  相关领域（因子图+预积分）：

  - VINS-Mono
  - ORB-SLAM3 VI
  - LIO-SAM
  - Kalibr（批处理）
]

#figure(
  image("5.png"),
  caption: [由于误差状态$delta x$始终被保证很小，因此可以安全地应用线性卡尔曼滤波],
)

#chapter("贝叶斯滤波器，高斯分布", image: image("./orange2.jpg"), l: "bayes-filter-gaussian")

任何单一传感器都不够充分。需要一种能够以概率方式融合的算法。

#tip(title: [我们所讨论的一切都具有不确定性])[
  - 状态$x$：想要知道的量（位置、速度、偏置等）
  - 测量值$z$：传感器提供的量
  - 两者均非确定值，而是以概率分布的形式处理
]

#tip(title: [数学符号])[
  - 对$x$的信念：$p(x)$
  - 观测到$z$之后对$x$的信念：$p(x|z)$
]

#tip(title: [概率的两种解释])[
  - 频率学派："无限次抛掷硬币，正面比例趋近于0.5"
  - 贝叶斯学派："我认为这枚硬币出现正面的概率是0.5"

  在机器人的状态估计中呢？自然是贝叶斯学派。"当前我的机器人位置"是没有办法无限重复的。我们处理的是仅有一次的实现（这台机器人、这个时刻）的信念。
]

#tip(title: [条件概率])[
  $
    p(A|B) = p(A,B)/p(B)
  $

  - "已知$B$发生时，$A$的概率"
  - 将联合概率$p(A, B)$按$B$的截面进行归一化
  - 从这个定义出发，贝叶斯定理和全概率公式均可推导得出
]

#tip(title: [贝叶斯定理])[
  $
    because p(A,B) = p(A|B)p(B) = p(B|A)p(A)
    \
    \
    therefore p(A|B) = (p(B|A)p(A))/p(B)
  $

  如果改用状态估计的符号表示

  $
    p(x|z) = (p(z|x)p(x))/p(z)
  $

  - $p(x)$：先验——测量前的信念
  - $p(z|x)$：似然——传感器模型
  - $p(x|z)$：后验概率——测量后的信念
  - $p(z)$：归一化常数，实际上可以视为乘法因子
]

#tip(title: [为什么比例关系就足够了？])[
  $
    p(x|z) prop p(z|x)p(x)
  $

  - $p(z)$不依赖于$x$——其形状不会随着$x$的变化而改变。
  - 最后将整个分布积分归一化为1，即可自动恢复。
  - 因此仅从形状来看，先验$times$似然就是后验。

  一句话总结："用测量值对先验信念的合理程度进行加权"
]

#tip(title: [贝叶斯定理——从工程视角的两个核心要点])[
  对于从事机器人状态估计的人来说，贝叶斯定理可以概括为两行。

  1. 后验概率是先验概率与观测的加权结合

  $
    underbrace(p(x|z), "后验概率") prop underbrace(p(z|x), "观测") dot.c underbrace(p(x), "先验概率")
  $

  当变为高斯分布时，这实际上就是均值的加权和，权重为精度（方差的倒数）。卡尔曼滤波的更新公式：$hat(x)^+ = hat(x)^- + bold(K)(z - bold(H)hat(x)^-)$正是这种形式。

  2. 后验分布将成为下一轮的先验分布（这一点更为重要）

  $
    p(x_t|z_(1:t)) stretch(->, size: #200%)^"预测" p(x_(t+1)|z_(1:t)) stretch(->, size: #200%)^"更新" p(x_(t+1)|z_(1:t+1))
  $

  注意：并不是只结合一次，而是以无限递归的方式不断结合。这种递归正是"滤波器"概念的本质——信念随着时间流动！
]

#tip(title: [为什么偏偏是高斯分布——这是闭式解的选择])[
  - 中心极限定理：独立噪声之和$arrow.r.long$高斯分布（对实际传感器噪声的良好近似）
  - 闭合形式：高斯分布相乘仍然是高斯分布
  - 对线性变换封闭：如果$x tilde cal(N)(mu, Sigma)$，则$A x tilde cal(N)(A mu, A Sigma A^T)$
  - 只用均值和协方差两个矩就可以描述一个高斯分布——节省内存

  #danger(title: [注意])[
    高斯分布是能够实现闭式解的一种选择，而不是唯一选择。非高斯问题（多峰分布，严重非线性）$arrow.r.long$粒子滤波是通用解法。本课程限定在高斯框架内，但会明确认识其局限性并加以突破。
  ]
]

#tip(title: [1维高斯分布——公式和图示])[
  $
    cal(N)(x; mu, sigma^2) = 1/(sqrt(2 pi)sigma)exp(-(x-mu)^2/(2 sigma^2))
  $

  #figure(
    image("normal_curve.pdf"),
    caption: [1维高斯分布],
  )

  $sigma$是不确定性宽度，越小则分布越尖锐。
]

#tip(title: [多变量高斯分布——协方差决定形状])[
  $
    cal(N)(bold(x); bold(mu), bold(Sigma))
    =
    1/(sqrt((2 pi)^n |bold(Sigma)|))exp(-1/2(bold(x)-bold(mu))^T bold(Sigma)^(-1) (bold(x)-bold(mu)))
  $

  #figure(
    image("multinormal.pdf"),
    caption: [多变量高斯分布],
  )

  非对角项（off-diagonal）决定了卡尔曼滤波器的真正力量源自何处。
]

#tip(title: [高斯分布$times$高斯分布])[
  两个一维高斯分布$cal(N)(x; mu_1, sigma_1^2), cal(N)(x; mu_2, sigma_2^2)$的乘积仍然是高斯分布：

  $
           mu & = ( mu_1"/"sigma_1^2 + mu_2"/"sigma_2^2 ) / ( 1"/"sigma_1^2 + 1"/"sigma_2^2 ) \
    1/sigma^2 & = 1/sigma_1^2 + 1/sigma_2^2
  $

  - 均值是精度（$=1/sigma$）的加权平均
  - 方差通过倒数之和进行合并 $arrow.r.long$ 结果总是小于两者中较小的那个值
  - 即合并两个信息后，不确定性会降低
]

推导过程如下：

$
  cal(N)(mu_1, sigma_1^2)cal(N)(mu_2, sigma_2^2) prop exp(-(x-mu_1)^2/(2 sigma_1^2)-(x-mu_2)^2/(2 sigma_2^2))
$

整理指数项中关于$x$的项：

$
  -1/2 [ (1/sigma_1^2 + 1/sigma_2^2)x^2 - 2(mu_1/sigma_1^2 + mu_2/sigma_2^2)x + "常数" ]
$

那么可以看到

- 新的均值：$1/sigma^2 = 1/sigma_1^2 + 1/sigma_2^2$
- 新的方差：$mu = sigma^2 dot.c (mu_1/sigma_1^2 + mu_2/sigma_2^2)$

可以将$mu$简化为精度加权平均的形式：

$
  mu = ( mu_1"/"sigma_1^2 + mu_2"/"sigma_2^2 ) / ( 1"/"sigma_1^2 + 1"/"sigma_2^2 )
$

再看一下公式的含义：

- $sigma_1 arrow.r.long 0$：首次测量完美 -> $mu arrow.r.long mu_1$（直接接受这个值）
- $sigma_1 arrow.r.long infinity$：首次测量无意义 -> $mu arrow.r.long mu_1$（只适用第二个值）
- 中间部分则平滑插值

相同的公式如果用卡尔曼滤波器的增益形式重写，则有如下公式

也就是如果我们设

$
       mu & = mu_1 + K(mu_2 - mu_1) \
  sigma^2 & = (1-K)sigma_1^2
$

则有

$
  K = sigma_1^2 / (sigma_1^2 + sigma_2^2)
$

这就是一维卡尔曼更新：

- $mu_1, sigma_1^2$：先验
- $mu_2, sigma_2^2$：测量
- $K$：*卡尔曼增益*（Kalman gain）——"对测量的信任程度"
- $mu_2-mu_1$：创新项——测量与预测的差异


机器人是时间序列。想要估计时间$k$的状态$x_k$。

有两类信息：

- 运动模型$p(x_k|x_(k-1))$——"从先前的状态如何运动"
- 测量模型$p(z_k|x_k)$——"在这种状态下，传感器会显示什么"

将贝叶斯定理按照时间顺序展开应用时，会自然分离出来两个阶段。

#tip(title: [贝叶斯滤波器——预测步骤推导])[
  $
    p(x_k|z_(1:k-1)) = integral p(x_k|x_(k-1))p(x_(k-1)|z_(1:k-1))upright(d)x_(k-1)
  $

  - 运动模型$p(x_k|x_(k-1))$将"先前的信念转移到未来"
  - 测量值尚未到来——因此进行预测（predict）
  - 结果导致信念扩散（不确定性增加）——和直觉一致
]

#tip(title: [贝叶斯滤波器——更新步骤推导])[
  当新的测量值$z_k$到来时，利用贝叶斯定理进行更新：
  $
    p(x_k|z_(1:k)) prop p(z_k|x_k)p(x_k|z_(1:k-1))
  $
  - 似然 $times$ 先验 -> 后验
  - 测量带来的收缩效应 -> 不确定性降低

  #tip(title: [核心信息])[
    预测（predict）通过运动模型推进时间，更新（update）则利用测量缩小分布范围。这两个阶段的分离并非选择，而是贝叶斯定理的必然结果。
  ]
]

#figure(
  image("bayesfilter.pdf"),
  caption: [贝叶斯滤波器],
)

#danger(title: [贝叶斯滤波器虽然完美，但无法求解])[
  - 预测的积分$integral dots.c upright(d)x_(k-1)$——通常没有闭式解
  - 更新的归一化$p(z)$——通常没有闭式解
  - 若状态连续且分布形状任意，理论上可行，但计算机无法求解

  突破口：

  - 如果将分布假设为高斯分布，则两个阶段均可得到闭式解
  - 这就是卡尔曼滤波器
]

#tip(title: [卡尔曼滤波器是贝叶斯滤波器+高斯分布假设])[
  - 先验和后验均以高斯分布表示
  - 运动模型和测量模型也假设为线性加高斯噪声
  - 那么两个步骤就简化为均值和协方差的更新
  - 仅需五行公式即可完成推导
]

#figure(
  image("bayestokf.pdf"),
  caption: [从贝叶斯滤波器到卡尔曼滤波器],
)

#tip(title: [思想实验——直线走廊+盲道砖])[
  - 状态：$x$（直线上的位置）
  - 运动模型：每迈一步，$x arrow x + 0.7 + w$, 其中：$w tilde cal(N)(0, 0.05^2)$
  - 测量模型：在有盲道砖的精确1米位置处，$z = x + v$，其中：$v tilde cal(N)(0, 0.02^2)$
  #linebreak()
  - 预测：每走一步，$sigma$会*变大*
  - 更新：一旦获得盲道砖测量，高斯分布相乘 -> $sigma$会*变小*
  - 两种效果的平衡会形成*可持续的估计*
]

#tip(title: [更新——写成两个高斯分布的乘积])[
  - 先验（预测结果）：在第100步为$cal(N)(x; 70, 0.25)$
  - 测量（第100步的点）：$cal(N)(x; 100, 0.0004)$
  #linebreak()
  $
    1/sigma^2 & = 1/0.25 + 1/0.0004 approx 2504 arrow.double sigma approx 0.02 \
           mu & = (70/0.25 + 100/0.0004)/2504 approx 99.99
  $
  - 结果：方差几乎和测量的方差相等。
  - 直觉：一次准确的测量几乎会覆盖先验信息。
]

#tip(title: [为什么我们非要用协方差矩阵])[
  - 如果状态是单一变量，只需要方差即可
  - 但如果状态是多维且相互关联的呢？
  #linebreak()
  例如：位置$x$和速度$v$的协方差矩阵如下：
  $
    bold(Sigma) = mat(sigma_x^2, rho sigma_x sigma_y; rho sigma_x sigma_v, sigma_v^2)
  $
  - $rho > 0$：当"位置信息更明确"时，速度估计也会随之收敛。
  - 这种相互作用正是卡尔曼滤波的真正力量——对一个变量的测量能够缩小其它变量的不确定性
  - IMU偏置估计能够自动完成的原因也是如此
]

#tip(title: [预测/更新重复——方差如何变化（锯齿形）])[
  #figure(
    image("predict-update.pdf"),
    caption: [预测/更新],
  )

  - 蓝线：预测会增大方差：（$bold(P) mapsto bold(F P F^T) + bold(Q)$）
  - 红色箭头：更新会减小方差（$bold(P) mapsto (bold(I) - bold(K H))bold(P)$）
  - 锯齿波（sawtooth）：每个周期$"predict"arrow.t arrow "update"arrow.b$重复。
  - 稳态（Steady-State）:在可观测系统中$bold(P) arrow bold(P)_infinity$收敛（DARE解）
  - ESKF实际比例：预测为100-400Hz，GPS为1-10Hz，相机为10-30Hz。
  - 更新频率越低，锯齿的振幅越大。
]

#tip(title: [似然与测量噪声])[
  - 似然函数$p(bold(z)|bold(x))$——在某个状态时，出现某个测量的概率
  - 测量噪声$bold(v) tilde cal(N)(0, bold(R))$——产生该概率的噪声
  - 在高斯假设下，两者实际上是同一个对象的两种表达方式

  #tip(title: [实用提醒])[
    - 如果把$bold(R)$设置的太小（"我的传感器非常准确！"）->会把噪声*当成真相*，导致估计震荡
    - 如果把$bold(R)$设置的太大->几乎忽略测量->实际上变成了航位推算（dead reckoning）
  ]
]

#figure(
  ```python
  import numpy as np

  def predict(mu, var, u, q):
      # $x_k = x_(k-1) + u + w, w tilde cal(N)(0, q)$
      return mu + u, var + q

  def update(mu, var, z, r):
      # $z = x + v, v tilde cal(N)(0, r)$
      K = var / (var + r) # 卡尔曼增益（1D）
      return mu + K * (z - mu), (1 - K) * var

  mu, var = 0.0, 1.0
  u, q, r = 0.7, 0.05 ** 2, 0.02 ** 2
  for k in range(1, 101):
      mu, var = predict(mu, var, u, q)
      if k % 10 == 0: # 每隔10步测量一次
          mu, var = update(mu, var, k * 1.0, r)
  ```,
  caption: [1D贝叶斯滤波器的实现],
)

- 预测：方差增大
- 更新：方差减小
- 改变测量周期（$k%20,k%50$）时，方差会如何变化呢？

#danger(title: [本章核心内容])[
  - 贝叶斯定理的一行公式中，预测/更新步骤必然随之而来
  - 高斯乘积 = 精度加权平均 + 精度求和
  - 将同一公式重新整理，即得到一维卡尔曼更新的标准形式
  - 高斯分布是能够实现闭合形式的选择——非高斯分布则需使用粒子滤波
  - 协方差中的非对角元素使得一个变量的测量能够缩小其他变量的范围
]

#chapter("SO(3)入门", image: image("orange2.jpg"), l: "so3")

#figure(
  image("rpy.pdf"),
  caption: [旋转表达的三种选择],
)

- 任何表达方式都不会"没有代价的"达到完美——每种表达方式都有其优缺点
- ESKF结合了四元数（实现）和$"SO"(3)$几何学（理论）

#danger(title: [欧拉角的致命缺陷——万向锁])[
  当横滚角-俯仰角-偏航角（roll-pitch-yaw）表示中，当俯仰角=90°时：

  - $x$轴旋转和$z$轴旋转指向同一个方向->自由度丧失
  - 求导后行列式=0->雅可比矩阵奇异
  - 卡尔曼滤波的$F$矩阵和$H$矩阵数值上会发散
  - 实际案例：阿波罗11号陀螺仪锁定、飞机姿态估计错误

  所以在需要以可微分形式处理旋转的估计问题中，欧拉角从根本上无法使用。
]

#tip(title: [四元数——虽然更优，但存在约束条件])[
  $
      bold(upright(q)) & = (q_w, q_x, q_y, q_z) \
    |bold(upright(q))| & = 1 space space "（单位四元数）"
  $

  #danger(title: [符号注意])[
    - 这里使用汉密尔顿管理$(q_w, q_x, q_y, q_z)$——和Eigen、GTSAM、ROS tf2一致。
    - OpenVINS使用JPL管理$(q_x,q_y,q_z,q_w)$——使用代码时需要转换
  ]

  #danger(title: [卡尔曼滤波中的四元数问题])[
    - 卡尔曼滤波将状态视为向量处理
    - 以$hat(bold(upright(q))) + K v$进行更新->$|q|!=1$的可能性存在
    - 若仅做简单的重新归一化，协方差会指向错误的方向。
  ]
]

#tip(title: [$"SO"(3)$——三维旋转的集合本身])[
  $
    "SO"(3) = {bold(R) in RR^(3 times 3) | bold(R)^T bold(R) = bold(I), "det"(bold(R)) = +1}
  $

  - 由6个约束条件构成$R$内的三维流形（manifold）
  - 该曲面上的每个点 = 一个三维旋转
  - 两个旋转的复合：矩阵乘法$bold(R)_1 bold(R)_2$（封闭性）
  - 单位元：$bold(I)$
  - 逆元：$bold(R)^T$
  - 群（group）+可微分的曲面->李群（Lie Group）
]

#tip(title: [流形直觉——从球面角度考虑])[
  考虑地球表面：
  - 整体空间：$RR^3$（三维）
  - 地球表面：嵌入$RR^3$中的二维面$=S^2$
  - 在某一点上的极小移动，感觉就像是在平面上进行
  - 那个"局部平面" = 切空间

  $"SO"(3)$也是如此：
  - $RR^9$中的3D曲面
  - 一个旋转$bold(R)$附近的小变化->切空间$tilde.equiv RR^3$

  #figure(
    image("manifold.pdf"),
    caption: [流形],
  )
]

#tip(title: [李代数$frak("so")(3)$——单位元处的其空间])[
  $bold(R)=bold(I)$附近的$"SO"(3)$切空间称为李代数：
  $
    frak("so")(3) = {bold(Phi) in RR^(3 times 3) | bold(Phi) + bold(Phi)^T = bold(0)} space space "（反对称矩阵）"
  $

  反对称矩阵仅包含三个自由参数：
  $
    [bold(phi.alt)]_times = mat(0, -phi.alt_z, phi.alt_y; phi.alt_z, 0, -phi.alt_x; -phi.alt_y, phi.alt_x, 0), space space bold(phi.alt) = (phi.alt_x, phi.alt_y, phi.alt_z)^T in RR^3
  $

  #danger(title: [核心])[
    - $frak("so")(3) tilde.equiv RR^3$
    - 微小旋转$delta bold(R) approx bold(I)$由三维向量$phi.alt$描述
    - ESKF中旋转误差状态$delta phi.alt in RR^3$出现的原因正是这个
  ]
]

#tip(title: [指数映射——将向量转换为旋转])[
  $
    "Exp"(bold(phi.alt)) := e^([phi.alt]_times) = bold(I) + (sin norm(bold(phi.alt)))/norm(bold(phi.alt))[bold(phi.alt)]_times + (1-cos norm(phi.alt))/norm(phi.alt)^2 [phi.alt]_times^2
  $

  （罗德里格斯公式）：

  - 输入：$phi.alt in RR^3$（方向=旋转轴，大小=角度）
  - 输出：$bold(R) in "SO"(3)$
  - 当$norm(phi.alt) arrow 0$时，$"Exp"(bold(phi.alt)) approx bold(I) + [bold(phi.alt)]_times$（一阶近似）

  例子：$phi.alt = (0,0,pi/2)^T$->绕$z$轴旋转90°：
  $
    "Exp"mat(0; 0; pi/2) = mat(0, -1, 0; 1, 0, 0; 0, 0, 1)
  $
]




#part("Point-LIO算法")

#chapter("源码解读", image: image("./orange2.jpg"), l: "rl-introduction")

```cpp
#ifndef SO3_MATH_H
#define SO3_MATH_H

#include <math.h>
#include <Eigen/Core>

// #include <common_lib.h>

#define SKEW_SYM_MATRX(v) 0.0,-v[2],v[1],v[2],0.0,-v[0],-v[1],v[0],0.0

template<typename T>
Eigen::Matrix<T, 3, 3> skew_sym_mat(const Eigen::Matrix<T, 3, 1> &v)
{
    Eigen::Matrix<T, 3, 3> skew_sym_mat;
    skew_sym_mat<<0.0,-v[2],v[1],v[2],0.0,-v[0],-v[1],v[0],0.0;
    return skew_sym_mat;
}

template<typename T>
Eigen::Matrix<T, 3, 3> Exp(const Eigen::Matrix<T, 3, 1> &ang)
{
    T ang_norm = ang.norm();
    Eigen::Matrix<T, 3, 3> Eye3 = Eigen::Matrix<T, 3, 3>::Identity();
    if (ang_norm > 0.0000001)
    {
        Eigen::Matrix<T, 3, 1> r_axis = ang / ang_norm;
        Eigen::Matrix<T, 3, 3> K;
        K << SKEW_SYM_MATRX(r_axis);
        /// Roderigous Tranformation
        return Eye3 + std::sin(ang_norm) * K + (1.0 - std::cos(ang_norm)) * K * K;
    }
    else
    {
        return Eye3;
    }
}

template<typename T, typename Ts>
Eigen::Matrix<T, 3, 3> Exp(const Eigen::Matrix<T, 3, 1> &ang_vel, const Ts &dt)
{
    T ang_vel_norm = ang_vel.norm();
    Eigen::Matrix<T, 3, 3> Eye3 = Eigen::Matrix<T, 3, 3>::Identity();

    if (ang_vel_norm > 0.0000001)
    {
        Eigen::Matrix<T, 3, 1> r_axis = ang_vel / ang_vel_norm;
        Eigen::Matrix<T, 3, 3> K;

        K << SKEW_SYM_MATRX(r_axis);

        T r_ang = ang_vel_norm * dt;

        /// Roderigous Tranformation
        return Eye3 + std::sin(r_ang) * K + (1.0 - std::cos(r_ang)) * K * K;
    }
    else
    {
        return Eye3;
    }
}

template<typename T>
Eigen::Matrix<T, 3, 3> Exp(const T &v1, const T &v2, const T &v3)
{
    T &&norm = sqrt(v1 * v1 + v2 * v2 + v3 * v3);
    Eigen::Matrix<T, 3, 3> Eye3 = Eigen::Matrix<T, 3, 3>::Identity();
    if (norm > 0.00001)
    {
        T r_ang[3] = {v1 / norm, v2 / norm, v3 / norm};
        Eigen::Matrix<T, 3, 3> K;
        K << SKEW_SYM_MATRX(r_ang);

        /// Roderigous Tranformation
        return Eye3 + std::sin(norm) * K + (1.0 - std::cos(norm)) * K * K;
    }
    else
    {
        return Eye3;
    }
}

/* Logrithm of a Rotation Matrix */
template<typename T>
Eigen::Matrix<T,3,1> Log(const Eigen::Matrix<T, 3, 3> R)
{
    T theta = (R.trace() > 3.0 - 1e-6) ? 0.0 : std::acos(0.5 * (R.trace() - 1));
    Eigen::Matrix<T,3,1> K(R(2,1) - R(1,2), R(0,2) - R(2,0), R(1,0) - R(0,1));
    return (std::abs(theta) < 0.001) ? (0.5 * K) : (0.5 * theta / std::sin(theta) * K);
}

template<typename T>
Eigen::Matrix<T, 3, 1> RotMtoEuler(const Eigen::Matrix<T, 3, 3> &rot)
{
    T sy = sqrt(rot(0,0)*rot(0,0) + rot(1,0)*rot(1,0));
    bool singular = sy < 1e-6;
    T x, y, z;
    if(!singular)
    {
        x = atan2(rot(2, 1), rot(2, 2));
        y = atan2(-rot(2, 0), sy);
        z = atan2(rot(1, 0), rot(0, 0));
    }
    else
    {
        x = atan2(-rot(1, 2), rot(1, 1));
        y = atan2(-rot(2, 0), sy);
        z = 0;
    }
    Eigen::Matrix<T, 3, 1> ang(x, y, z);
    return ang;
}

template<typename T>
Eigen::Matrix3d Jacob_right_inv(Eigen::Vector3d &vec){
    Eigen::Matrix3d hat_v, res;
    hat_v << SKEW_SYM_MATRX(vec);
    if(vec.norm() > 1e-6)
    {
        res = Eigen::Matrix<double, 3, 3>::Identity() + 0.5 * hat_v + (1 - vec.norm() * std::cos(vec.norm() / 2) / 2 / std::sin(vec.norm() / 2)) * hat_v * hat_v / vec.squaredNorm();
    }
    else
    {
        res = Eigen::Matrix<double, 3, 3>::Identity();
    }
    return res;
}

#endif
```

`SO3_MATH`代码详解

整体定位

```
SO(3) = Special Orthogonal Group（特殊正交群）
      = 所有 3×3 旋转矩阵的集合

这个头文件提供了 SO(3) 上的核心数学工具：
  旋转向量 ↔ 旋转矩阵 的相互转换
  用于 Point-LIO 的状态估计
```

一、基础概念

旋转的三种表示

```
旋转向量（轴角）：ω = θ · n̂
  θ = 旋转角度（弧度）
  n̂ = 旋转轴（单位向量）
  向量的模 = 旋转角度
  向量的方向 = 旋转轴

旋转矩阵 R：3×3 矩阵，R^T·R = I，det(R) = 1

欧拉角：roll, pitch, yaw（有万向锁问题）
```

李群与李代数

```
SO(3)  = 李群（旋转矩阵的集合）
so(3)  = 李代数（反对称矩阵的集合）

Exp()  : so(3) → SO(3)  （李代数 → 李群）
Log()  : SO(3) → so(3)  （李群 → 李代数）

直觉：
  旋转矩阵不能直接相加（不在线性空间）
  但旋转向量可以相加
  Exp/Log 就是在这两个空间之间转换的桥梁
```

二、skew_sym_mat — 反对称矩阵（叉积矩阵）

```cpp
template<typename T>
Eigen::Matrix<T, 3, 3> skew_sym_mat(const Eigen::Matrix<T, 3, 1> &v)
{
    skew_sym_mat << 0.0, -v[2],  v[1],
                    v[2],  0.0, -v[0],
                   -v[1],  v[0],  0.0;
}
```

数学定义

$
  hat(v) = mat(0, -v_z, v_y; v_z, 0, -v_x; -v_y, v_x, 0)
$

核心性质

$
  hat(v) dot.c u = v times u space "（叉积）"
$

```
把向量叉积转换成矩阵乘法
这是 Rodrigues 公式的基础
```

验证

$
  v = (1, 2, 3), space u = (4, 5, 6)
$

#set math.mat(delim: "|")
$
  v times u = mat(i, j, k; 1, 2, 3; 4, 5, 6) = (-3, 6, -3)
$

#set math.mat(delim: "(")
$
  hat(v) dot.c u = mat(0, -3, 2; 3, 0, -1; -2, 1, 0) mat(4; 5; 6) = mat(-3; 6; -3)
$

三、Exp — 旋转向量转旋转矩阵

Rodrigues 旋转公式

$
  R = exp(hat(omega)) = I + sin theta dot.c K + (1 - cos theta) dot.c K^2
$

其中$K=hat(n)$（旋转轴的反对称矩阵），$theta=norm(omega)$

代码实现（版本1：输入旋转向量）

```cpp
template<typename T>
Eigen::Matrix<T, 3, 3> Exp(const Eigen::Matrix<T, 3, 1> &ang)
{
    T ang_norm = ang.norm();          // θ = |ω|（旋转角度）

    if (ang_norm > 0.0000001)
    {
        Eigen::Matrix<T, 3, 1> r_axis = ang / ang_norm;  // n̂ = ω/θ（单位旋转轴）
        Eigen::Matrix<T, 3, 3> K;
        K << SKEW_SYM_MATRX(r_axis);  // K = n̂ 的反对称矩阵

        // Rodrigues 公式
        return Eye3 + std::sin(ang_norm) * K + (1.0 - std::cos(ang_norm)) * K * K;
    }
    else
    {
        return Eye3;  // 旋转角度≈0，返回单位矩阵
    }
}
```

代码实现（版本2：输入角速度 + 时间步长）

```cpp
template<typename T, typename Ts>
Eigen::Matrix<T, 3, 3> Exp(const Eigen::Matrix<T, 3, 1> &ang_vel, const Ts &dt)
{
    // 旋转角度 = 角速度 × 时间
    T r_ang = ang_vel_norm * dt;   // θ = |ω| × dt

    // 同样用 Rodrigues 公式
    return Eye3 + std::sin(r_ang) * K + (1.0 - std::cos(r_ang)) * K * K;
}
```

```
用途：IMU 积分
  已知角速度 ω（rad/s）和时间间隔 dt
  计算这段时间内的旋转矩阵
  R_new = R_old × Exp(ω, dt)
```

Rodrigues 公式几何直觉

```
绕轴 n̂ 旋转 θ 角：

R = I                    → 不旋转的部分（投影到旋转轴）
  + sin(θ)·K             → 旋转90°的分量
  + (1-cos(θ))·K²        → 旋转180°的分量

三项叠加 = 完整的旋转
```

为什么小角度返回单位矩阵

```
当 θ → 0 时：
  sin(θ) → θ → 0
  1-cos(θ) → θ²/2 → 0

整个旋转趋近于 I
直接返回 I，避免除以接近0的数导致数值不稳定
```

四、Log — 旋转矩阵转旋转向量

```cpp
template<typename T>
Eigen::Matrix<T,3,1> Log(const Eigen::Matrix<T, 3, 3> R)
{
    // 从迹（trace）提取旋转角度
    // trace(R) = 1 + 2cos(θ)
    T theta = (R.trace() > 3.0 - 1e-6) ? 0.0
                                        : std::acos(0.5 * (R.trace() - 1));

    // 从反对称部分提取旋转轴方向
    // R - R^T = 2sin(θ)·K  →  K 的元素在这里
    Eigen::Matrix<T,3,1> K(R(2,1) - R(1,2),   // 2sin(θ)·n_x
                           R(0,2) - R(2,0),   // 2sin(θ)·n_y
                           R(1,0) - R(0,1));  // 2sin(θ)·n_z

    // 小角度：直接用 0.5·K（因为 sin(θ)≈θ，所以 K≈2θ·n̂，0.5K≈θ·n̂）
    // 正常角度：θ/(2sin(θ)) × K = θ·n̂（旋转向量）
    return (std::abs(theta) < 0.001) ? (0.5 * K)
                                     : (0.5 * theta / std::sin(theta) * K);
}
```

数学推导

$
  "trace"(R) = 1 + 2 cos theta arrow.double theta = "arccos"(("trace"(R)-1)/(2))
$

$
  R - R^T = 2 sin theta dot.c K arrow.double "旋转向量" = theta/(2 sin theta) (R - R^T)^or
$

其中 $(dot.c)^or$ 表示从反对称矩阵提取向量

五、RotMtoEuler — 旋转矩阵转欧拉角

```cpp
template<typename T>
Eigen::Matrix<T, 3, 1> RotMtoEuler(const Eigen::Matrix<T, 3, 3> &rot)
{
    // sy = cos(pitch)，用于判断是否奇异
    T sy = sqrt(rot(0,0)*rot(0,0) + rot(1,0)*rot(1,0));
    bool singular = sy < 1e-6;  // pitch = ±90° 时奇异（万向锁）

    if(!singular)
    {
        x = atan2(rot(2,1), rot(2,2));   // roll
        y = atan2(-rot(2,0), sy);         // pitch
        z = atan2(rot(1,0), rot(0,0));   // yaw
    }
    else  // 万向锁情况
    {
        x = atan2(-rot(1,2), rot(1,1));  // roll（特殊处理）
        y = atan2(-rot(2,0), sy);         // pitch = ±90°
        z = 0;                            // yaw 无法确定，置0
    }
}
```

ZYX 旋转矩阵结构

$
  R_(Z Y X) = mat(c_y c_p, c_y s_p s_r - s_y c_r, c_y s_p c_r + s_y s_r; s_y c_p, s_y s_p s_r + c_y c_r, s_y s_p c_- c_y s_r; -s_p, c_p s_r, c_p c_r)
$

$
  c_y & = cos("yaw") \
  s_y & = sin("yaw") \
  c_p & = cos("pitch") \
  s_p & = sin("pitch") \
  c_r & = cos("roll") \
  s_r & = sin("roll")
$

从矩阵元素反推：

$
                        "rot"(2, 0) = -sin("pitch") & arrow.r "pitch" = "atan2"(-"rot"(2, 0), s_y) \
  "rot"(2, 1)/"rot"(2, 2) = sin("roll")/cos("roll") & arrow.r "roll" \
    "rot"(1, 0)/"rot"(0, 0) = sin("yaw")/cos("yaw") & arrow.r "yaw"
$

六、Jacob_right_inv — 右雅可比逆矩阵

```cpp
template<typename T>
Eigen::Matrix3d Jacob_right_inv(Eigen::Vector3d &vec)
{
    Eigen::Matrix3d hat_v;
    hat_v << SKEW_SYM_MATRX(vec);

    if(vec.norm() > 1e-6)
    {
        res = I + 0.5·hat_v
            + (1 - θ·cos(θ/2) / (2·sin(θ/2))) · hat_v² / θ²
    }
    else
    {
        res = I;  // 小角度近似
    }
}
```

用途

在$S O (3)$上做优化时，需要把李代数的扰动映射回切空间（Tangent Space）

$J_r^(-1)$ 用于：

- 残差对旋转的雅可比矩阵计算
- Point-LIO 中的迭代卡尔曼滤波更新步骤

直觉：

- 旋转空间是弯曲的（非线性）
- $J_r^(-1)$ 是这个弯曲空间的"局部线性化修正"

七、完整关系图

#figure(
  image("1.svg"),
  caption: [],
)

八、在 Point-LIO 中的使用

IMU预积分：

$
  R_(t+upright(d)t) = R_t times exp(markhl(omega_"imu" times upright(d)t, tag: #<vel>))
  #annot(<vel>, "角速度积分得到旋转增量")
$

状态更新：

$partial R = exp(partial phi)$将误差状态（李代数）转为旋转矩阵

残差计算：

$r = log(R_"pred"^T times R_"meas")$两个旋转矩阵的"差"

雅可比计算：

$(partial r)/(partial phi) = J_r^(-1)$用于迭代卡尔曼滤波的线性化
