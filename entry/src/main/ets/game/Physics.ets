// 物理引擎模块 - 处理重力、碰撞检测与响应、边界约束
import { GRAVITY, BOUNCE_DAMPING, FRICTION, VELOCITY_THRESHOLD, GAME_WIDTH, GAME_HEIGHT } from './Constants';

// 水果物理体
export class FruitBody {
  id: number = 0;
  level: number = 0;       // 水果等级
  x: number = 0;           // 中心X坐标
  y: number = 0;           // 中心Y坐标
  radius: number = 0;      // 半径
  vx: number = 0;          // X方向速度
  vy: number = 0;          // Y方向速度
  isDropping: boolean = false; // 是否正在下落（未参与物理计算）
  isMerging: boolean = false;  // 是否正在合成动画中
  mergeTimer: number = 0;     // 合成动画计时器
  isNew: boolean = true;      // 是否刚创建（需要短暂等待才能参与碰撞）

  constructor(id: number, level: number, x: number, y: number, radius: number) {
    this.id = id;
    this.level = level;
    this.x = x;
    this.y = y;
    this.radius = radius;
  }
}

// 碰撞对（用于返回合成信息）
export class CollisionPair {
  a: FruitBody | null = null;
  b: FruitBody | null = null;

  constructor(a: FruitBody, b: FruitBody) {
    this.a = a;
    this.b = b;
  }
}

// 碰撞检测结果
class CollisionResult {
  collided: boolean = false;
  distance: number = 0;

  constructor(collided: boolean, distance: number) {
    this.collided = collided;
    this.distance = distance;
  }
}

// 物理引擎
export class PhysicsEngine {
  private bodies: FruitBody[] = [];
  private nextId: number = 0;

  // 添加水果
  addFruit(level: number, x: number, y: number, radius: number, isDropping: boolean = false): FruitBody {
    const body = new FruitBody(this.nextId++, level, x, y, radius);
    body.isDropping = isDropping;
    this.bodies.push(body);
    return body;
  }

  // 移除水果
  removeFruit(id: number): void {
    let index = -1;
    for (let i = 0; i < this.bodies.length; i++) {
      if (this.bodies[i].id === id) {
        index = i;
        break;
      }
    }
    if (index >= 0) {
      this.bodies.splice(index, 1);
    }
  }

  // 获取所有水果
  getBodies(): FruitBody[] {
    return this.bodies;
  }

  // 清空所有水果
  clear(): void {
    this.bodies = [];
    this.nextId = 0;
  }

  // 物理步进 - 返回需要合成的水果对列表
  step(): CollisionPair[] {
    const mergePairs: CollisionPair[] = [];

    // 更新合成动画
    for (const body of this.bodies) {
      if (body.isMerging) {
        body.mergeTimer--;
        if (body.mergeTimer <= 0) {
          body.isMerging = false;
        }
      }
    }

    // 应用重力和摩擦力
    for (const body of this.bodies) {
      if (body.isDropping || body.isMerging) continue;

      body.vy += GRAVITY;
      body.vx *= FRICTION;
      body.vy *= FRICTION;

      body.x += body.vx;
      body.y += body.vy;
    }

    // 边界约束
    for (const body of this.bodies) {
      if (body.isDropping || body.isMerging) continue;
      this.constrainToBounds(body);
    }

    // 碰撞检测与响应（多次迭代以稳定）
    for (let iter = 0; iter < 5; iter++) {
      for (let i = 0; i < this.bodies.length; i++) {
        const a = this.bodies[i];
        if (a.isDropping || a.isMerging) continue;

        for (let j = i + 1; j < this.bodies.length; j++) {
          const b = this.bodies[j];
          if (b.isDropping || b.isMerging) continue;

          const result = this.checkCollision(a, b);
          if (result.collided) {
            // 检查是否可以合成
            if (a.level === b.level) {
              // 避免重复添加同一对
              let alreadyAdded = false;
              for (const pair of mergePairs) {
                if ((pair.a === a && pair.b === b) || (pair.a === b && pair.b === a)) {
                  alreadyAdded = true;
                  break;
                }
              }
              if (!alreadyAdded) {
                mergePairs.push(new CollisionPair(a, b));
              }
            } else {
              // 不同等级，进行碰撞响应
              this.resolveCollision(a, b, result.distance);
            }
          }
        }
      }
    }

    // 速度衰减 - 低于阈值则归零
    for (const body of this.bodies) {
      if (body.isDropping || body.isMerging) continue;
      if (Math.abs(body.vx) < VELOCITY_THRESHOLD) body.vx = 0;
      if (Math.abs(body.vy) < VELOCITY_THRESHOLD && this.isOnGround(body)) body.vy = 0;
    }

    return mergePairs;
  }

  // 检测两个水果是否碰撞
  private checkCollision(a: FruitBody, b: FruitBody): CollisionResult {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const minDist = a.radius + b.radius;

    if (dist < minDist && dist > 0.01) {
      return new CollisionResult(true, dist);
    }
    return new CollisionResult(false, 0);
  }

  // 碰撞响应
  private resolveCollision(a: FruitBody, b: FruitBody, dist: number): void {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const minDist = a.radius + b.radius;
    const overlap = minDist - dist;

    // 法线方向
    const nx = dx / dist;
    const ny = dy / dist;

    // 分离两个物体（各移一半重叠量）
    const separateX = nx * overlap * 0.5;
    const separateY = ny * overlap * 0.5;
    a.x -= separateX;
    a.y -= separateY;
    b.x += separateX;
    b.y += separateY;

    // 相对速度
    const dvx = a.vx - b.vx;
    const dvy = a.vy - b.vy;
    const dvn = dvx * nx + dvy * ny;

    // 只在物体靠近时处理
    if (dvn > 0) {
      const impulse = dvn * (1 + BOUNCE_DAMPING) * 0.5;
      a.vx -= impulse * nx;
      a.vy -= impulse * ny;
      b.vx += impulse * nx;
      b.vy += impulse * ny;
    }

    // 边界约束
    this.constrainToBounds(a);
    this.constrainToBounds(b);
  }

  // 边界约束
  private constrainToBounds(body: FruitBody): void {
    // 左边界
    if (body.x - body.radius < 0) {
      body.x = body.radius;
      body.vx = Math.abs(body.vx) * BOUNCE_DAMPING;
    }
    // 右边界
    if (body.x + body.radius > GAME_WIDTH) {
      body.x = GAME_WIDTH - body.radius;
      body.vx = -Math.abs(body.vx) * BOUNCE_DAMPING;
    }
    // 底部边界
    if (body.y + body.radius > GAME_HEIGHT) {
      body.y = GAME_HEIGHT - body.radius;
      body.vy = -Math.abs(body.vy) * BOUNCE_DAMPING;
    }
  }

  // 判断是否在地面
  private isOnGround(body: FruitBody): boolean {
    return body.y + body.radius >= GAME_HEIGHT - 1;
  }

  // 检查水果是否超过危险线
  checkGameOver(dangerLineY: number): boolean {
    for (const body of this.bodies) {
      if (body.isDropping || body.isMerging || body.isNew) continue;
      // 水果顶部超过危险线
      if (body.y - body.radius < dangerLineY) {
        // 检查该水果是否基本静止
        if (Math.abs(body.vy) < 2 && Math.abs(body.vx) < 2) {
          return true;
        }
      }
    }
    return false;
  }
}
