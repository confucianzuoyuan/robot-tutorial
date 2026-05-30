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
