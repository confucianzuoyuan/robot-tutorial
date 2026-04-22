#import "@preview/orange-book:0.6.1": (
  appendices, book, chapter, corollary, definition, example, exercise, index, make-index, my-bibliography, notation,
  part, problem, proposition, remark, scr, theorem, update-heading-image, vocabulary,
)
#import "@preview/gentle-clues:1.2.0": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/mannot:0.3.1": *
#import "@preview/cetz:0.4.2"
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
