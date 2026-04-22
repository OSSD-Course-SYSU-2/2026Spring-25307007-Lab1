// 游戏引擎 - 主循环、状态管理、合成逻辑
import { PhysicsEngine, FruitBody, CollisionPair } from './Physics';
import {
  GAME_WIDTH, GAME_HEIGHT, MAX_FRUIT_LEVEL,
  FRUIT_RADII, FRUIT_SCORES,
  DANGER_LINE_Y, DROP_START_Y, MAX_FRUITS,
  DROP_COOLDOWN, RANDOM_FRUIT_MAX_LEVEL
} from './Constants';

// 游戏状态
export enum GameState {
  IDLE,       // 等待开始
  PLAYING,    // 游戏中
  GAME_OVER   // 游戏结束
}

// 合成特效信息
export class MergeEffect {
  x: number = 0;
  y: number = 0;
  radius: number = 0;
  timer: number = 10;
  level: number = 0;

  constructor(x: number, y: number, radius: number, level: number) {
    this.x = x;
    this.y = y;
    this.radius = radius;
    this.level = level;
  }
}

// 新水果延迟信息
class NewFruitDelay {
  bodyId: number = 0;
  framesLeft: number = 0;

  constructor(bodyId: number, frames: number) {
    this.bodyId = bodyId;
    this.framesLeft = frames;
  }
}

// 游戏引擎
export class GameEngine {
  private physics: PhysicsEngine = new PhysicsEngine();
  private state: GameState = GameState.IDLE;
  private score: number = 0;
  private bestScore: number = 0;
  private currentLevel: number = 0;       // 当前待释放水果等级
  private dropX: number = GAME_WIDTH / 2;  // 当前释放位置X
  private canDrop: boolean = true;         // 是否可以释放新水果
  private dropCooldownTimer: number = 0;   // 释放冷却计时
  private mergeEffects: MergeEffect[] = []; // 合成特效列表
  private gameOverCheckDelay: number = 0;  // 游戏结束检测延迟
  private newFruitDelays: NewFruitDelay[] = []; // 新水果延迟取消isNew标记

  // 初始化/重新开始游戏
  start(): void {
    this.physics.clear();
    this.state = GameState.PLAYING;
    this.score = 0;
    this.canDrop = true;
    this.dropCooldownTimer = 0;
    this.mergeEffects = [];
    this.newFruitDelays = [];
    this.gameOverCheckDelay = 90; // 等待约1.5秒后才开始检测游戏结束
    this.currentLevel = this.randomLevel();
    this.dropX = GAME_WIDTH / 2;
  }

  // 随机生成水果等级（只生成小水果）
  private randomLevel(): number {
    return Math.floor(Math.random() * (RANDOM_FRUIT_MAX_LEVEL + 1));
  }

  // 设置释放位置
  setDropX(x: number): void {
    if (this.state !== GameState.PLAYING) return;
    const r = FRUIT_RADII[this.currentLevel];
    this.dropX = Math.max(r, Math.min(GAME_WIDTH - r, x));
  }

  // 释放水果
  dropFruit(): void {
    if (this.state !== GameState.PLAYING || !this.canDrop) return;

    const r = FRUIT_RADII[this.currentLevel];
    const bodies = this.physics.getBodies();
    if (bodies.length >= MAX_FRUITS) return;

    // 创建下落水果
    const body = this.physics.addFruit(this.currentLevel, this.dropX, DROP_START_Y, r, true);
    body.vy = 2; // 初始下落速度

    // 设置冷却
    this.canDrop = false;
    this.dropCooldownTimer = DROP_COOLDOWN / 16; // 转换为帧数

    // 生成下一个水果
    this.currentLevel = this.randomLevel();
  }

  // 游戏主循环 - 每帧调用
  update(): void {
    if (this.state !== GameState.PLAYING) return;

    // 更新冷却
    if (!this.canDrop) {
      this.dropCooldownTimer--;
      if (this.dropCooldownTimer <= 0) {
        this.canDrop = true;
      }
    }

    // 更新新水果延迟
    const remainingDelays: NewFruitDelay[] = [];
    for (const d of this.newFruitDelays) {
      d.framesLeft--;
      if (d.framesLeft <= 0) {
        // 找到对应的水果并取消isNew标记
        const allBodies = this.physics.getBodies();
        for (const body of allBodies) {
          if (body.id === d.bodyId) {
            body.isNew = false;
            break;
          }
        }
      } else {
        remainingDelays.push(d);
      }
    }
    this.newFruitDelays = remainingDelays;

    // 更新下落水果状态
    const bodies = this.physics.getBodies();
    for (const body of bodies) {
      if (body.isDropping) {
        // 下落水果到达其他水果上方或底部时，变为普通水果
        body.vy += 0.5; // 重力
        body.y += body.vy;

        // 检查是否到达底部
        if (body.y + body.radius >= GAME_HEIGHT) {
          body.y = GAME_HEIGHT - body.radius;
          body.vy = 0;
          body.isDropping = false;
          body.isNew = true;
          this.newFruitDelays.push(new NewFruitDelay(body.id, 6));
          continue;
        }

        // 检查是否碰到其他水果
        for (const other of bodies) {
          if (other.id === body.id || other.isDropping || other.isMerging) continue;
          const dx = other.x - body.x;
          const dy = other.y - body.y;
          const dist = Math.sqrt(dx * dx + dy * dy);
          if (dist < body.radius + other.radius) {
            body.isDropping = false;
            body.isNew = true;
            body.vy = 0;
            this.newFruitDelays.push(new NewFruitDelay(body.id, 6));
            break;
          }
        }
      }
    }

    // 物理步进
    const mergePairs = this.physics.step();

    // 处理合成
    for (const pair of mergePairs) {
      if (pair.a === null || pair.b === null) continue;
      const a = pair.a;
      const b = pair.b;
      if (a.level >= MAX_FRUIT_LEVEL) continue; // 最高等级不再合成

      // 计算合成位置
      const newX = (a.x + b.x) / 2;
      const newY = (a.y + b.y) / 2;
      const newLevel = a.level + 1;
      const newR = FRUIT_RADII[newLevel];

      // 移除旧水果
      this.physics.removeFruit(a.id);
      this.physics.removeFruit(b.id);

      // 创建新水果
      const newBody = this.physics.addFruit(newLevel, newX, newY, newR);
      newBody.isMerging = true;
      newBody.mergeTimer = 10;

      // 添加合成特效
      this.mergeEffects.push(new MergeEffect(newX, newY, newR, newLevel));

      // 加分
      this.score += FRUIT_SCORES[newLevel];

      // 合成大西瓜特殊加分
      if (newLevel === MAX_FRUIT_LEVEL) {
        this.score += 200;
      }
    }

    // 更新合成特效
    const remainingEffects: MergeEffect[] = [];
    for (const e of this.mergeEffects) {
      e.timer--;
      if (e.timer > 0) {
        remainingEffects.push(e);
      }
    }
    this.mergeEffects = remainingEffects;

    // 游戏结束检测
    if (this.gameOverCheckDelay > 0) {
      this.gameOverCheckDelay--;
    } else {
      if (this.physics.checkGameOver(DANGER_LINE_Y)) {
        this.state = GameState.GAME_OVER;
        if (this.score > this.bestScore) {
          this.bestScore = this.score;
        }
      }
    }
  }

  // 获取游戏状态
  getState(): GameState {
    return this.state;
  }

  // 获取分数
  getScore(): number {
    return this.score;
  }

  // 获取最高分
  getBestScore(): number {
    return this.bestScore;
  }

  // 获取当前水果等级
  getCurrentLevel(): number {
    return this.currentLevel;
  }

  // 获取释放位置
  getDropX(): number {
    return this.dropX;
  }

  // 获取是否可以释放
  getCanDrop(): boolean {
    return this.canDrop;
  }

  // 获取所有水果
  getBodies(): FruitBody[] {
    return this.physics.getBodies();
  }

  // 获取合成特效
  getMergeEffects(): MergeEffect[] {
    return this.mergeEffects;
  }
}
