// 水果渲染模块 - 在Canvas上绘制各种水果
import { FRUIT_COLORS, FRUIT_RADII, GAME_HEIGHT } from './Constants';
import { FruitBody } from './Physics';

// 绘制单个水果
export function drawFruit(context: CanvasRenderingContext2D, body: FruitBody): void {
  const x = body.x;
  const y = body.y;
  const r = body.radius;
  const level = body.level;

  // 合成动画效果 - 缩放
  let scale = 1.0;
  if (body.isMerging) {
    scale = 1.0 + (body.mergeTimer / 10) * 0.3;
  }

  const drawR = r * scale;

  context.save();

  // 绘制水果主体
  drawFruitBody(context, x, y, drawR, level);

  // 绘制水果表情/装饰
  drawFruitFace(context, x, y, drawR, level);

  context.restore();
}

// 绘制水果主体
function drawFruitBody(context: CanvasRenderingContext2D, x: number, y: number, r: number, level: number): void {
  const color = FRUIT_COLORS[level];

  // 阴影
  context.shadowBlur = 4;
  context.shadowColor = 'rgba(0,0,0,0.3)';
  context.shadowOffsetX = 2;
  context.shadowOffsetY = 2;

  // 主体圆形
  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.fillStyle = color;
  context.fill();

  // 清除阴影
  context.shadowBlur = 0;
  context.shadowOffsetX = 0;
  context.shadowOffsetY = 0;

  // 高光效果
  const gradient = context.createRadialGradient(x - r * 0.3, y - r * 0.3, r * 0.1, x, y, r);
  gradient.addColorStop(0, 'rgba(255,255,255,0.4)');
  gradient.addColorStop(1, 'rgba(255,255,255,0)');
  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.fillStyle = gradient;
  context.fill();

  // 边框
  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.strokeStyle = 'rgba(0,0,0,0.15)';
  context.lineWidth = 1.5;
  context.stroke();

  // 西瓜特殊条纹
  if (level === 9 || level === 10) {
    drawWatermelonStripes(context, x, y, r);
  }
}

// 西瓜条纹
function drawWatermelonStripes(context: CanvasRenderingContext2D, x: number, y: number, r: number): void {
  context.save();
  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.clip();

  context.strokeStyle = 'rgba(0,80,0,0.3)';
  context.lineWidth = 2;

  for (let i = -3; i <= 3; i++) {
    const offset = i * r * 0.35;
    context.beginPath();
    context.moveTo(x + offset - r * 0.3, y - r);
    context.quadraticCurveTo(x + offset, y, x + offset + r * 0.3, y + r);
    context.stroke();
  }

  context.restore();
}

// 绘制水果表情
function drawFruitFace(context: CanvasRenderingContext2D, x: number, y: number, r: number, level: number): void {
  const faceScale = r / 40; // 基于半径缩放表情

  // 眼睛
  const eyeOffsetX = 6 * faceScale;
  const eyeOffsetY = -3 * faceScale;
  const eyeRadius = 2.5 * faceScale;

  // 左眼
  context.beginPath();
  context.arc(x - eyeOffsetX, y + eyeOffsetY, eyeRadius, 0, Math.PI * 2);
  context.fillStyle = '#333333';
  context.fill();

  // 右眼
  context.beginPath();
  context.arc(x + eyeOffsetX, y + eyeOffsetY, eyeRadius, 0, Math.PI * 2);
  context.fillStyle = '#333333';
  context.fill();

  // 眼睛高光
  const highlightRadius = 1 * faceScale;
  context.beginPath();
  context.arc(x - eyeOffsetX + highlightRadius, y + eyeOffsetY - highlightRadius, highlightRadius, 0, Math.PI * 2);
  context.fillStyle = '#FFFFFF';
  context.fill();

  context.beginPath();
  context.arc(x + eyeOffsetX + highlightRadius, y + eyeOffsetY - highlightRadius, highlightRadius, 0, Math.PI * 2);
  context.fillStyle = '#FFFFFF';
  context.fill();

  // 嘴巴 - 微笑
  const mouthY = y + 5 * faceScale;
  const mouthWidth = 5 * faceScale;
  context.beginPath();
  context.arc(x, mouthY - 2 * faceScale, mouthWidth, 0.1 * Math.PI, 0.9 * Math.PI);
  context.strokeStyle = '#333333';
  context.lineWidth = 1.5 * faceScale;
  context.lineCap = 'round';
  context.stroke();
}

// 绘制待释放水果（顶部预览）
export function drawPreviewFruit(context: CanvasRenderingContext2D, x: number, y: number, level: number): void {
  const r = FRUIT_RADII[level];
  const color = FRUIT_COLORS[level];

  // 半透明预览
  context.globalAlpha = 0.7;

  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.fillStyle = color;
  context.fill();

  context.beginPath();
  context.arc(x, y, r, 0, Math.PI * 2);
  context.strokeStyle = 'rgba(255,255,255,0.8)';
  context.lineWidth = 2;
  context.stroke();

  // 下落指示线
  context.beginPath();
  context.setLineDash([5, 5]);
  context.moveTo(x, y + r);
  context.lineTo(x, GAME_HEIGHT);
  context.strokeStyle = 'rgba(255,255,255,0.3)';
  context.lineWidth = 1;
  context.stroke();
  context.setLineDash([]);

  context.globalAlpha = 1.0;
}

// 绘制合成特效
export function drawMergeEffect(context: CanvasRenderingContext2D, x: number, y: number, r: number, timer: number): void {
  const progress = timer / 10;
  const effectR = r * (1 + progress * 0.5);
  const alpha1 = 0.5 * (1 - progress);

  context.beginPath();
  context.arc(x, y, effectR, 0, Math.PI * 2);
  context.strokeStyle = 'rgba(255,255,255,' + alpha1.toFixed(2) + ')';
  context.lineWidth = 3;
  context.stroke();

  // 粒子效果
  const particleCount = 6;
  for (let i = 0; i < particleCount; i++) {
    const angle = (i / particleCount) * Math.PI * 2;
    const dist = r * progress * 1.5;
    const px = x + Math.cos(angle) * dist;
    const py = y + Math.sin(angle) * dist;
    const particleR = 3 * (1 - progress);
    const alpha2 = 0.8 * (1 - progress);

    context.beginPath();
    context.arc(px, py, particleR, 0, Math.PI * 2);
    context.fillStyle = 'rgba(255,255,200,' + alpha2.toFixed(2) + ')';
    context.fill();
  }
}
