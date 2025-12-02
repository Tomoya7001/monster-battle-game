// lib/presentation/screens/battle/pvp_matching_screen.dart
// PvPカジュアルマッチ マッチング画面

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/entities/monster.dart';
import 'pvp_battle_screen.dart';

/// CPUバレ防止用の名前リスト（500種類用意）
const List<String> _cpuNames = [
  // 日本語名（100種類）
  'タケシ', 'カスミ', 'マサト', 'ハルカ', 'シゲル', 'サトシ', 'ヒカリ', 'シンジ', 'アイリス', 'デント',
  'セレナ', 'シトロン', 'ユリーカ', 'リーリエ', 'マオ', 'スイレン', 'カキ', 'マーマネ', 'グラジオ', 'ホウ',
  'レイジ', 'シュウ', 'ハルヒ', 'ナツキ', 'アキラ', 'ユウキ', 'リク', 'ソラ', 'カイト', 'レン',
  'ミク', 'リン', 'ルカ', 'メイコ', 'カイト', 'ガクポ', 'イア', 'ユカリ', 'ずんだもん', 'きりたん',
  'タクヤ', 'ケンタ', 'リョウマ', 'ユウト', 'ソウタ', 'コウキ', 'ハヤト', 'ダイキ', 'カズマ', 'シンヤ',
  'アヤカ', 'ミユ', 'ナナミ', 'サクラ', 'モモカ', 'ユイ', 'リナ', 'マイ', 'アイ', 'エミ',
  'ヒロト', 'タツヤ', 'ケイスケ', 'ユウジ', 'マサキ', 'ナオト', 'ショウタ', 'コウスケ', 'トモヤ', 'ダイスケ',
  'アスカ', 'レイ', 'シンジ', 'カヲル', 'ミサト', 'リツコ', 'マヤ', 'シゲル', 'マコト', 'ヒカル',
  'アキト', 'ナデシコ', 'ユリカ', 'メグミ', 'リュウセイ', 'ガイ', 'アカツキ', 'サバタ', 'イズミ', 'ホシノ',
  'クロウ', 'ゼロ', 'イチ', 'ニ', 'サン', 'シ', 'ゴ', 'ロク', 'ナナ', 'ハチ',
  
  // 英語風名前（100種類）
  'Alex', 'Blake', 'Charlie', 'Dylan', 'Emma', 'Finn', 'Grace', 'Hunter', 'Ivy', 'Jake',
  'Kai', 'Luna', 'Max', 'Nina', 'Oliver', 'Piper', 'Quinn', 'Riley', 'Sam', 'Taylor',
  'Tyler', 'Victor', 'Will', 'Xavier', 'Yuki', 'Zack', 'Aiden', 'Bella', 'Caleb', 'Daisy',
  'Ethan', 'Fiona', 'Gavin', 'Hannah', 'Isaac', 'Julia', 'Kevin', 'Lily', 'Mason', 'Nora',
  'Owen', 'Penny', 'Quentin', 'Rose', 'Sean', 'Tessa', 'Uriel', 'Violet', 'Wyatt', 'Xena',
  'York', 'Zoe', 'Aaron', 'Brooke', 'Carter', 'Diana', 'Evan', 'Faith', 'Grant', 'Holly',
  'Ivan', 'Jade', 'Kyle', 'Laura', 'Mark', 'Nancy', 'Oscar', 'Paula', 'Ray', 'Sara',
  'Tom', 'Uma', 'Vince', 'Wendy', 'Xander', 'Yvonne', 'Zane', 'Amy', 'Brian', 'Claire',
  'David', 'Emily', 'Frank', 'Gina', 'Henry', 'Iris', 'Jack', 'Kate', 'Leo', 'Mia',
  'Nick', 'Olive', 'Paul', 'Rita', 'Steve', 'Tina', 'Ulric', 'Vera', 'Wade', 'Zara',
  
  // 造語・ゲーム風（100種類）
  'Blaze', 'Storm', 'Shadow', 'Phoenix', 'Dragon', 'Knight', 'Rogue', 'Mage', 'Paladin', 'Ranger',
  'Thunder', 'Frost', 'Flame', 'Wind', 'Earth', 'Light', 'Dark', 'Void', 'Nova', 'Star',
  'Blade', 'Edge', 'Steel', 'Iron', 'Gold', 'Silver', 'Copper', 'Bronze', 'Crystal', 'Ruby',
  'Emerald', 'Sapphire', 'Diamond', 'Pearl', 'Onyx', 'Jade', 'Amber', 'Topaz', 'Opal', 'Quartz',
  'Wolf', 'Tiger', 'Lion', 'Bear', 'Eagle', 'Hawk', 'Falcon', 'Raven', 'Owl', 'Fox',
  'Ninja', 'Samurai', 'Warrior', 'Hunter', 'Archer', 'Swordsman', 'Lancer', 'Axeman', 'Mace', 'Hammer',
  'Zero', 'One', 'Alpha', 'Beta', 'Gamma', 'Delta', 'Omega', 'Sigma', 'Zeta', 'Theta',
  'Ace', 'King', 'Queen', 'Jack', 'Joker', 'Dealer', 'Gambler', 'Lucky', 'Chance', 'Fortune',
  'Rapid', 'Swift', 'Quick', 'Fast', 'Speedy', 'Flash', 'Dash', 'Rush', 'Burst', 'Surge',
  'Mighty', 'Power', 'Strong', 'Force', 'Impact', 'Strike', 'Crush', 'Smash', 'Break', 'Shatter',
  
  // 数字付き（100種類）
  'Player001', 'Player002', 'Player003', 'Player004', 'Player005', 'Player006', 'Player007', 'Player008', 'Player009', 'Player010',
  'Trainer11', 'Trainer22', 'Trainer33', 'Trainer44', 'Trainer55', 'Trainer66', 'Trainer77', 'Trainer88', 'Trainer99', 'Trainer00',
  'Master123', 'Master234', 'Master345', 'Master456', 'Master567', 'Master678', 'Master789', 'Master890', 'Master901', 'Master012',
  'Pro100', 'Pro200', 'Pro300', 'Pro400', 'Pro500', 'Pro600', 'Pro700', 'Pro800', 'Pro900', 'Pro999',
  'Hero01', 'Hero02', 'Hero03', 'Hero04', 'Hero05', 'Hero06', 'Hero07', 'Hero08', 'Hero09', 'Hero10',
  'Legend1', 'Legend2', 'Legend3', 'Legend4', 'Legend5', 'Legend6', 'Legend7', 'Legend8', 'Legend9', 'Legend0',
  'Champion1', 'Champion2', 'Champion3', 'Champion4', 'Champion5', 'Champion6', 'Champion7', 'Champion8', 'Champion9', 'ChampionX',
  'Elite01', 'Elite02', 'Elite03', 'Elite04', 'Elite05', 'Elite06', 'Elite07', 'Elite08', 'Elite09', 'Elite10',
  'Rank1st', 'Rank2nd', 'Rank3rd', 'Rank4th', 'Rank5th', 'Rank6th', 'Rank7th', 'Rank8th', 'Rank9th', 'Rank10th',
  'Top10', 'Top20', 'Top30', 'Top50', 'Top100', 'Top500', 'Top1000', 'Rising1', 'Rising2', 'Rising3',
  
  // 追加（100種類）
  'CloudNine', 'MoonWalk', 'StarDust', 'SunShine', 'RainBow', 'SnowFlake', 'FireBall', 'IceAge', 'ThunderBolt', 'WindMill',
  'SkyHigh', 'DeepSea', 'DarkKnight', 'LightBringer', 'ShadowDancer', 'FlameHeart', 'FrostBite', 'StormRider', 'EarthShaker', 'VoidWalker',
  'DragonSlayer', 'GiantKiller', 'DemonHunter', 'AngelWings', 'GodHand', 'DevilMay', 'HolyGrail', 'DarkSoul', 'BrightStar', 'NightOwl',
  'DawnBreaker', 'DuskFall', 'MidnightSun', 'NoonMoon', 'TwilightZone', 'SunriseSky', 'SunsetGlow', 'MorningDew', 'EveningPrime', 'NightShade',
  'RedHot', 'BlueCool', 'GreenLeaf', 'YellowFlash', 'PurpleHaze', 'OrangeJuice', 'PinkPanther', 'BlackJack', 'WhiteSnow', 'GrayWolf',
  'IronMan', 'SteelHeart', 'GoldRush', 'SilverBullet', 'CopperHead', 'BronzeAge', 'TitanFall', 'MetalGear', 'CrystalClear', 'GemStone',
  'RocketPunch', 'LaserBeam', 'PlasmaCut', 'SonicBoom', 'AtomicBomb', 'NuclearWar', 'CosmicRay', 'GravityPull', 'MagneticField', 'ElectricShock',
  'WaterFall', 'AirStrike', 'FireStorm', 'IceBreaker', 'RockSlide', 'SandStorm', 'MudSlide', 'LavaFlow', 'TidalWave', 'Earthquake',
  'NinjaWay', 'SamuraiSword', 'KnightShield', 'WizardStaff', 'ArcherBow', 'WarriorAxe', 'ThiefDagger', 'MonkFist', 'BardSong', 'DruidNature',
  'GameOver', 'NewGame', 'Continue', 'SavePoint', 'LoadGame', 'QuitGame', 'StartMenu', 'OptionSet', 'CreditRoll', 'TheEnd',
];

/// PvPマッチング画面
class PvpMatchingScreen extends StatefulWidget {
  final List<Monster> playerParty;
  final String playerId;
  final String playerName;
  final bool isDraftBattle;
  final List<Monster>? draftEnemyParty;
  final String? battleId;

  const PvpMatchingScreen({
    Key? key,
    required this.playerParty,
    required this.playerId,
    required this.playerName,
    this.isDraftBattle = false,
    this.draftEnemyParty,
    this.battleId,
  }) : super(key: key);

  @override
  State<PvpMatchingScreen> createState() => _PvpMatchingScreenState();
}

class _PvpMatchingScreenState extends State<PvpMatchingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _rotationAnim;

  Timer? _matchingTimer;
  int _elapsedSeconds = 0;
  bool _foundOpponent = false;
  String? _opponentName;
  
  // マッチング設定: 5〜13秒のランダム
  late int _matchingDuration;

  @override
  void initState() {
    super.initState();

    // 5〜13秒のランダムでマッチング時間を決定
    _matchingDuration = 5 + Random().nextInt(9); // 5〜13秒

    // ローディングアニメーション
    _animController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnim = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(_animController);

    // マッチング開始
    _startMatching();
  }

  @override
  void dispose() {
    _animController.dispose();
    _matchingTimer?.cancel();
    super.dispose();
  }

  void _startMatching() {
    _matchingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _elapsedSeconds++;
      });

      // ランダムな時間経過でマッチング完了
      if (_elapsedSeconds >= _matchingDuration && !_foundOpponent) {
        timer.cancel();
        _matchComplete();
      }
    });
  }

  void _matchComplete() {
    // ランダムなCPU名を選択
    final cpuName = _cpuNames[Random().nextInt(_cpuNames.length)];

    setState(() {
      _foundOpponent = true;
      _opponentName = cpuName;
    });

    // 2秒後にバトル画面へ遷移
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _navigateToBattle(cpuName);
    });
  }

  void _navigateToBattle(String opponentName) {
    if (widget.isDraftBattle) {
      // ドラフトバトルの場合
      Navigator.pop(context, {
        'opponentName': opponentName,
        'isCpu': true,
      });
    } else {
      // カジュアルマッチの場合
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PvpBattleScreen(
            playerParty: widget.playerParty,
            playerId: widget.playerId,
            playerName: widget.playerName,
            opponentName: opponentName,
            isCpuOpponent: true,
          ),
        ),
      );
    }
  }

  void _cancelMatching() {
    _matchingTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelMatching();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black87,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // タイトル
                Text(
                  _foundOpponent ? '対戦相手が見つかりました！' : 'マッチング中...',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 48),

                // プレイヤー情報
                _buildPlayerCard(widget.playerName, isPlayer: true),

                const SizedBox(height: 24),

                // VS or ローディング
                _foundOpponent
                    ? const Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      )
                    : AnimatedBuilder(
                        animation: _rotationAnim,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnim.value,
                            child: const Icon(
                              Icons.sync,
                              size: 64,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),

                const SizedBox(height: 24),

                // 対戦相手情報
                _foundOpponent
                    ? _buildPlayerCard(_opponentName ?? '???', isPlayer: false)
                    : _buildSearchingCard(),

                const SizedBox(height: 48),

                // 経過時間
                if (!_foundOpponent)
                  Text(
                    '経過時間: $_elapsedSeconds 秒',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),

                const SizedBox(height: 24),

                // キャンセルボタン
                if (!_foundOpponent)
                  OutlinedButton.icon(
                    onPressed: _cancelMatching,
                    icon: const Icon(Icons.close),
                    label: const Text('キャンセル'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(String name, {required bool isPlayer}) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPlayer ? Colors.blue.shade800 : Colors.red.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isPlayer ? Colors.blue : Colors.red).withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            isPlayer ? 'あなた' : '対戦相手',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingCard() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade600,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            '検索中...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '対戦相手を探しています',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
