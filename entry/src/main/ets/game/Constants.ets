// 游戏常量定义

// 游戏区域尺寸
export const GAME_WIDTH: number = 360;
export const GAME_HEIGHT: number = 600;

// 物理参数
export const GRAVITY: number = 0.5;           // 重力加速度
export const BOUNCE_DAMPING: number = 0.3;    // 碰撞反弹衰减
export const FRICTION: number = 0.99;          // 摩擦系数
export const VELOCITY_THRESHOLD: number = 0.5; // 速度阈值（低于此值视为静止）

// 水果等级数量（0-10，共11种）
export const MAX_FRUIT_LEVEL: number = 10;

// 水果半径（从小到大）
export const FRUIT_RADII: number[] = [
  15,  // 0: 葡萄
  20,  // 1: 樱桃
  26,  // 2: 橘子
  32,  // 3: 柠檬
  38,  // 4: 猕猴桃
  44,  // 5: 番茄
  50,  // 6: 桃子
  58,  // 7: 菠萝
  66,  // 8: 椰子
  76,  // 9: 半个西瓜
  86   // 10: 大西瓜
];

// 水果颜色
export const FRUIT_COLORS: string[] = [
  '#8B5CF6',  // 0: 葡萄 - 紫色
  '#EF4444',  // 1: 樱桃 - 红色
  '#F97316',  // 2: 橘子 - 橙色
  '#FDE047',  // 3: 柠檬 - 黄色
  '#84CC16',  // 4: 猕猴桃 - 绿色
  '#DC2626',  // 5: 番茄 - 深红
  '#FB923C',  // 6: 桃子 - 粉橙
  '#FBBF24',  // 7: 菠萝 - 金黄
  '#92400E',  // 8: 椰子 - 棕色
  '#22C55E',  // 9: 半个西瓜 - 浅绿
  '#16A34A'   // 10: 大西瓜 - 深绿
];

// 水果名称
export const FRUIT_NAMES: string[] = [
  '葡萄',
  '樱桃',
  '橘子',
  '柠檬',
  '猕猴桃',
  '番茄',
  '桃子',
  '菠萝',
  '椰子',
  '半西瓜',
  '大西瓜'
];

// 水果合成得分
export const FRUIT_SCORES: number[] = [
  1,    // 0: 葡萄
  3,    // 1: 樱桃
  6,    // 2: 橘子
  10,   // 3: 柠檬
  15,   // 4: 猕猴桃
  21,   // 5: 番茄
  28,   // 6: 桃子
  36,   // 7: 菠萝
  45,   // 8: 椰子
  55,   // 9: 半个西瓜
  100   // 10: 大西瓜
];

// 游戏结束判定线（距顶部距离）
export const DANGER_LINE_Y: number = 100;

// 下落水果的初始Y位置
export const DROP_START_Y: number = 50;

// 每次最多同时存在的水果数量
export const MAX_FRUITS: number = 50;

// 游戏循环间隔（毫秒）
export const GAME_TICK_INTERVAL: number = 16; // ~60fps

// 新水果下落等待时间（毫秒）
export const DROP_COOLDOWN: number = 500;

// 随机生成水果的最大等级（只生成前5种小水果）
export const RANDOM_FRUIT_MAX_LEVEL: number = 4;
