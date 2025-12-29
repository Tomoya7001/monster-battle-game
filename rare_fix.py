import json

# Rareファイルを読み込み
with open('/Users/tom/Desktop/monster_battle_game/assets/data/monster_masters_data_rare.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

# 修正リスト（技ファイルを正として）
fixes = {
    # linto
    'linto_002': {'name': '飛行モード', 'cost': 2, 'effect': '3T大地技無効+速さ↑'},
    # wurm
    'wurm_001': {'name': '聖なる鱗', 'cost': 3, 'effect': '3T状態異常無効+被ダメ-20%'},
    'wurm_002': {'name': '浄化のブレス', 'cost': 4, 'power': 'B', 'effect': '自分と相手のバフ・デバフ全解除'},
    'wurm_003': {'name': '聖竜の祝福', 'cost': 3, 'effect': '自分と控え全員HP30回復+状態異常解除'},
    # jack
    'jack_001': {'name': '略奪', 'cost': 3, 'power': 'C', 'effect': '相手のバフを1つ奪う'},
    'jack_002': {'name': '海賊の流儀', 'cost': 3, 'effect': '次攻撃クリ確定'},
    'jack_003': {'name': '荒波', 'cost': 4, 'power': 'B', 'effect': '相手速さ↓'},
    # ram
    'ram_001': {'name': '裁きの雷', 'cost': 5, 'power': 'B', 'effect': '先制'},
    'ram_002': {'name': '雷雲召喚', 'cost': 3, 'effect': '3T雷属性技コスト-1'},
    # eva
    'eva_001': {'name': '深海の歌', 'cost': 4, 'power': 'B', 'effect': '速さ↓↓'},
    'eva_002': {'name': '海竜の加護', 'cost': 2, 'effect': '3T水属性ダメージ無効'},
    # honoo
    'honoo_001': {'name': '太陽光線', 'cost': 5, 'power': 'B', 'effect': '火傷確定'},
    'honoo_002': {'name': '太陽フレア', 'cost': 4, 'effect': 'フィールド「灼熱」設置（5T炎技+50%、水技-30%）'},
    'honoo_003': {'name': '日光浴', 'cost': 3, 'effect': '自分HP40回復'},
    # lilith
    'lilith_001': {'name': '魅了のキス', 'cost': 3, 'power': 'D', 'effect': '魅了確定'},
    'lilith_002': {'name': '悪夢の囁き', 'cost': 2, 'effect': '悪夢確定'},
    'lilith_004': {'name': '夢喰い', 'cost': 3, 'power': 'B', 'effect': '悪夢状態の相手に威力2倍'},
    # luria
    'luria_001': {'name': 'アイドルの魅力', 'cost': 4, 'power': 'D', 'effect': '魅了確定'},
    'luria_003': {'name': '破滅の歌', 'cost': 3, 'effect': '体力の半分消費、2T後相手瀕死（交代でリセット）'},
    'luria_004': {'name': 'シャウト', 'cost': 3, 'power': 'B', 'effect': '恐怖確定'},
    # kyouka
    'kyouka_001': {'name': '呪符渡し', 'cost': 3, 'effect': '相手速さ↓↓'},
    'kyouka_002': {'name': '呪いの人形', 'cost': 4, 'effect': '設置（相手攻撃時相手にも同ダメ30%）'},
    'kyouka_004': {'name': '影縫い', 'cost': 3, 'power': 'D', 'effect': '先制'},
    # leon
    'leon_001': {'name': '聖騎士の守り', 'cost': 2, 'effect': '防御↑+次T被ダメ-30%'},
    'leon_002': {'name': '騎士の誓い', 'cost': 3, 'effect': '防御↑↑速さ↓'},
    'leon_003': {'name': '聖剣撃', 'cost': 4, 'power': 'B', 'effect': '自分HP満タン時威力1.3倍'},
}

# 削除対象（技ファイルに存在しないもの）
skills_to_remove = ['linto_003', 'ram_003', 'eva_003', 'lilith_003', 'jack_004', 'luria_002', 'kyouka_003', 'kyouka_005']

for monster in data['monsters']:
    skill_pool = monster.get('skill_pool', {})
    
    # initial_skills修正
    for skill in skill_pool.get('initial_skills', []):
        if skill['id'] in fixes:
            fix = fixes[skill['id']]
            skill['name'] = fix['name']
            skill['cost'] = fix.get('cost', skill.get('cost'))
            if 'power' in fix:
                skill['power'] = fix['power']
            elif 'power' in skill and 'power' not in fix:
                del skill['power']
            if 'effect' in fix:
                skill['effect'] = fix['effect']
    
    # learnable_skills修正
    new_learnable = []
    for skill in skill_pool.get('learnable_skills', []):
        if skill['id'] in skills_to_remove:
            print(f"Removing: {skill['id']} - {skill['name']}")
            continue
        if skill['id'] in fixes:
            fix = fixes[skill['id']]
            skill['name'] = fix['name']
            skill['cost'] = fix.get('cost', skill.get('cost'))
            if 'power' in fix:
                skill['power'] = fix['power']
            elif 'power' in skill and 'power' not in fix:
                del skill['power']
            if 'effect' in fix:
                skill['effect'] = fix['effect']
            print(f"Fixed: {skill['id']} -> {skill['name']}")
        new_learnable.append(skill)
    skill_pool['learnable_skills'] = new_learnable

# 保存
with open('/Users/tom/Desktop/monster_battle_game/assets/data/monster_masters_data_rare.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print("Done!")
