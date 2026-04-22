// 合成大西瓜 - 游戏主页面
import { GameEngine, GameState } from '../game/GameEngine';
import { drawFruit, drawPreviewFruit, drawMergeEffect } from '../game/Fruit';
import {
  GAME_WIDTH, GAME_HEIGHT, DANGER_LINE_Y,
  FRUIT_COLORS, MAX_FRUIT_LEVEL
} from '../game/Constants';

@Entry
@Component
struct Index {
  // 游戏引擎
  private engine: GameEngine = new GameEngine();
  // Canvas上下文
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // 定时器ID
  private timerId: number = -1;
  // Canvas实际显示尺寸（用于坐标转换）
  private displayWidth: number = GAME_WIDTH;
  private displayHeight: number = GAME_HEIGHT;

  // 响应式状态
  @State score: number = 0;
  @State bestScore: number = 0;
  @State isGameOver: boolean = false;
  @State isPlaying: boolean = false;
  @State currentLevel: number = 0;

  aboutToAppear(): void {
    this.engine.start();
    this.isPlaying = true;
    this.startGameLoop();
  }

  aboutToDisappear(): void {
    this.stopGameLoop();
  }

  // 启动游戏循环
  private startGameLoop(): void {
    this.timerId = setInterval(() => {
      this.engine.update();
      this.score = this.engine.getScore();
      this.bestScore = this.engine.getBestScore();
      this.currentLevel = this.engine.getCurrentLevel();

      if (this.engine.getState() === GameState.GAME_OVER && !this.isGameOver) {
        this.isGameOver = true;
        this.isPlaying = false;
      }

      this.render();
    }, 16);
  }

  // 停止游戏循环
  private stopGameLoop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  // 重新开始
  private restart(): void {
    this.engine.start();
    this.isGameOver = false;
    this.isPlaying = true;
    this.score = 0;
  }

  // 渲染游戏画面
  private render(): void {
    const ctx = this.context;
    if (!ctx) return;

    // 清空画布
    ctx.clearRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

    // 绘制背景
    this.drawBackground(ctx);

    // 绘制危险线
    this.drawDangerLine(ctx);

    // 绘制所有水果
    const bodies = this.engine.getBodies();
    for (const body of bodies) {
      drawFruit(ctx, body);
    }

    // 绘制合成特效
    const effects = this.engine.getMergeEffects();
    for (const effect of effects) {
      drawMergeEffect(ctx, effect.x, effect.y, effect.radius, effect.timer);
    }

    // 绘制预览水果（如果可以释放）
    if (this.engine.getCanDrop() && this.isPlaying) {
      drawPreviewFruit(ctx, this.engine.getDropX(), DANGER_LINE_Y - 20, this.engine.getCurrentLevel());
    }

    // 绘制分数
    this.drawScore(ctx);

    // 绘制游戏结束
    if (this.isGameOver) {
      this.drawGameOver(ctx);
    }
  }

  // 绘制背景
  private drawBackground(ctx: CanvasRenderingContext2D): void {
    // 渐变背景
    const gradient = ctx.createLinearGradient(0, 0, 0, GAME_HEIGHT);
    gradient.addColorStop(0, '#1a1a2e');
    gradient.addColorStop(0.5, '#16213e');
    gradient.addColorStop(1, '#0f3460');
    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

    // 游戏区域边框
    ctx.strokeStyle = 'rgba(255,255,255,0.2)';
    ctx.lineWidth = 2;
    ctx.strokeRect(1, DANGER_LINE_Y, GAME_WIDTH - 2, GAME_HEIGHT - DANGER_LINE_Y - 1);

    // 底部装饰
    ctx.fillStyle = 'rgba(255,255,255,0.05)';
    ctx.fillRect(0, GAME_HEIGHT - 3, GAME_WIDTH, 3);
  }

  // 绘制危险线
  private drawDangerLine(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    ctx.setLineDash([8, 4]);
    ctx.beginPath();
    ctx.moveTo(0, DANGER_LINE_Y);
    ctx.lineTo(GAME_WIDTH, DANGER_LINE_Y);
    ctx.strokeStyle = 'rgba(255,80,80,0.6)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    ctx.setLineDash([]);

    // 危险线标签
    ctx.font = '10px sans-serif';
    ctx.fillStyle = 'rgba(255,80,80,0.5)';
    ctx.fillText('DANGER', 5, DANGER_LINE_Y - 5);
    ctx.restore();
  }

  // 绘制分数
  private drawScore(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    // 分数背景
    ctx.fillStyle = 'rgba(0,0,0,0.3)';
    ctx.fillRect(GAME_WIDTH - 110, 5, 105, 35);

    // 分数文字
    ctx.font = 'bold 18px sans-serif';
    ctx.fillStyle = '#FFD700';
    ctx.textAlign = 'right';
    ctx.fillText(`${this.score}`, GAME_WIDTH - 15, 28);

    // 分数标签
    ctx.font = '12px sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.textAlign = 'left';
    ctx.fillText('SCORE', GAME_WIDTH - 105, 22);
    ctx.restore();
  }

  // 绘制游戏结束画面
  private drawGameOver(ctx: CanvasRenderingContext2D): void {
    // 半透明遮罩
    ctx.fillStyle = 'rgba(0,0,0,0.7)';
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT);

    // 游戏结束文字
    ctx.save();
    ctx.textAlign = 'center';

    ctx.font = 'bold 32px sans-serif';
    ctx.fillStyle = '#FF6B6B';
    ctx.fillText('游戏结束', GAME_WIDTH / 2, GAME_HEIGHT / 2 - 60);

    ctx.font = 'bold 24px sans-serif';
    ctx.fillStyle = '#FFD700';
    ctx.fillText(`得分: ${this.score}`, GAME_WIDTH / 2, GAME_HEIGHT / 2 - 10);

    if (this.bestScore > 0) {
      ctx.font = '16px sans-serif';
      ctx.fillStyle = 'rgba(255,255,255,0.7)';
      ctx.fillText(`最高分: ${this.bestScore}`, GAME_WIDTH / 2, GAME_HEIGHT / 2 + 25);
    }

    ctx.font = '16px sans-serif';
    ctx.fillStyle = 'rgba(255,255,255,0.8)';
    ctx.fillText('点击重新开始', GAME_WIDTH / 2, GAME_HEIGHT / 2 + 70);

    ctx.restore();
  }

  // 将屏幕坐标转换为游戏坐标
  private screenToGameX(screenX: number): number {
    const ratio = GAME_WIDTH / this.displayWidth;
    return screenX * ratio;
  }

  // 触摸事件处理
  private handleTouch(screenX: number, screenY: number, isRelease: boolean): void {
    if (this.isGameOver) {
      if (isRelease) {
        this.restart();
      }
      return;
    }

    if (!this.isPlaying) return;

    const gameX = this.screenToGameX(screenX);
    const clampedX = Math.max(0, Math.min(GAME_WIDTH, gameX));

    if (isRelease) {
      this.engine.setDropX(clampedX);
      this.engine.dropFruit();
    } else {
      this.engine.setDropX(clampedX);
    }
  }

  build() {
    Column() {
      // 顶部信息栏
      Row() {
        Text('下一个:')
          .fontSize(14)
          .fontColor('#AAAAAA')
          .margin({ right: 8 })

        // 水果等级指示点
        Row() {
          ForEach([
            0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
          ], (level: number) => {
            Row()
              .width(12)
              .height(12)
              .borderRadius(6)
              .backgroundColor(FRUIT_COLORS[level])
              .opacity(level === this.currentLevel ? 1.0 : 0.3)
              .margin({ right: 2 })
          }, (level: number) => `level_${level}`)
        }

        Blank()

        Text(`分数: ${this.score}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFD700')

        Text(` | 最高: ${this.bestScore}`)
          .fontSize(12)
          .fontColor('#888888')
      }
      .width('100%')
      .height(40)
      .padding({ left: 12, right: 12 })
      .backgroundColor('rgba(0,0,0,0.5)')

      // 游戏Canvas区域
      Stack() {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .onReady(() => {
            this.displayWidth = GAME_WIDTH;
            this.displayHeight = GAME_HEIGHT;
          })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#1a1a2e')
      .onAreaChange((oldArea: Area, newArea: Area) => {
        // 获取Canvas实际显示尺寸
        const width = Number(newArea.width);
        const height = Number(newArea.height);
        if (width > 0 && height > 0) {
          this.displayWidth = width;
          this.displayHeight = height;
        }
      })
      .onTouch((event: TouchEvent) => {
        if (event.touches.length > 0) {
          const touch = event.touches[0];
          if (event.type === TouchType.Down) {
            this.handleTouch(touch.x, touch.y, false);
          } else if (event.type === TouchType.Up) {
            this.handleTouch(touch.x, touch.y, true);
          } else if (event.type === TouchType.Move) {
            this.handleTouch(touch.x, touch.y, false);
          }
        }
      })

      // 底部操作栏
      Row() {
        Button('重新开始')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#E74C3C')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(() => {
            this.restart();
          })

        Text('合成大西瓜')
          .fontSize(14)
          .fontColor('#888888')
          .margin({ left: 12, right: 12 })

        Text('触摸选择位置，松手释放水果')
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.Center)
      .backgroundColor('rgba(0,0,0,0.5)')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0a1a')
  }
}
