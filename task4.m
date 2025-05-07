%% 参数设置
rho = 1.225;   % 空气密度 (kg/m³)
Cd = 0.3;      % 阻力系数
A = 2;         % 横截面积 (m²)
v_b = 20;      % 车辆速度 (m/s)
dt = 1;        % 时间步长 (秒)
T = 600;       % 总时长 (秒)
num_steps = T/dt;

%% 1. Ornstein-Uhlenbeck过程风速模拟
gamma = 0.5;   % 回归速率
mu = 10;       % 长期均值 (m/s)
sigma = 1.2;   % 波动率

% 初始化风速数组
w = zeros(num_steps+1, 1);
w(1) = mu;

% 数值求解SDE
for t = 1:num_steps
    dW = randn*sqrt(dt);
    dw = gamma*(mu - w(t))*dt + sigma*dW;
    w(t+1) = max(w(t) + dw, 0); % 保证非负
end

%% 2. 风向突变模拟（0° → 90°）
theta = zeros(size(w));
theta(1:300) = 0;      % 前5分钟0°
theta(301:end) = 90;   % 后5分钟90°

%% 3. 动态风阻功率计算
P_air = zeros(size(w));
for t = 1:length(w)
    term1 = v_b - w(t)*cosd(theta(t));
    term2 = sqrt(v_b^2 + w(t)^2 - 2*v_b*w(t)*cosd(theta(t)));
    P_air(t) = 0.5*rho*Cd*A*v_b*term1*term2;
end

%% 4. 静态模型对比
% 静态模型参数
w_static = mu;          % 平均风速
theta_static = 0;       % 平均风向

% 静态功率计算
term1_static = v_b - w_static*cosd(theta_static);
term2_static = sqrt(v_b^2 + w_static^2 - 2*v_b*w_static*cosd(theta_static));
P_static = 0.5*rho*Cd*A*v_b*term1_static*term2_static;

%% 5. 可视化结果
time = (0:dt:T)';
figure('Position', [100 100 800 400])

subplot(2,1,1)
plot(time, w, 'LineWidth', 1.5)
title('OU过程风速模拟')
ylabel('风速 (m/s)')
grid on

subplot(2,1,2)
plot(time, P_air, 'b', 'LineWidth', 1.5)
hold on
plot([0 T], [P_static P_static], 'r--', 'LineWidth', 1.5)
title('风阻功率对比')
xlabel('时间 (秒)')
ylabel('功率 (W)')
legend('动态模型', '静态模型')
grid on

%% 6. 场景测试：阵风突增 (5 → 9m/s)
w_test = [5*ones(200,1); linspace(5,9,100)'; 9*ones(301,1)]; % 生成测试风速
theta_test = zeros(size(w_test));                            % 固定风向

% 动态模型计算
P_test = zeros(size(w_test));
for t = 1:length(w_test)
    term1 = v_b - w_test(t)*cosd(theta_test(t));
    term2 = sqrt(v_b^2 + w_test(t)^2 - 2*v_b*w_test(t)*cosd(theta_test(t)));
    P_test(t) = 0.5*rho*Cd*A*v_b*term1*term2;
end

% 静态模型（基于5m/s）
term1_st = v_b - 5*cosd(0);
term2_st = sqrt(v_b^2 + 5^2 - 2*v_b*5*cosd(0));
P_static_test = 0.5*rho*Cd*A*v_b*term1_st*term2_st;

% 误差分析
error = abs(P_test - P_static_test)/P_static_test*100;

% 可视化场景测试
figure('Position', [100 100 800 400])
subplot(2,1,1)
plot(time, w_test, 'LineWidth', 1.5)
title('阵风突增场景')
ylabel('风速 (m/s)')
grid on

subplot(2,1,2)
plot(time, error, 'LineWidth', 1.5)
title('相对误差分析')
xlabel('时间 (秒)')
ylabel('误差 (%)')
grid on