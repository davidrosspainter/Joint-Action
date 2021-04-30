addpath 'D:\JOINT.ACTION\JointActionRevision\analysis\final_revision'


% x2 = sin(linspace(0,2*pi));
% y2 = cos(linspace(0,3*pi));
% X = [x2',y2'];
[L2,R2,K2] = curvature(X);

%

close 'all'
figure;
plot(L2,R2)
title('Curvature radius vs. cumulative curve length')
xlabel L
ylabel R
figure;
h = plot(X(:,1), X(:,2)); grid on; axis equal
set(h,'marker','.');
xlabel x
ylabel y
title('2D curve with curvature vectors')
hold on
quiver(X(:,1), X(:,2),K2(:,1),K2(:,2));
hold off