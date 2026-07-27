#!/bin/bash
# 每日辩论/逻辑训练 — 随机抽题脚本
# 每天从题库抽一题，写入当天日期的 markdown 文件

set -e

BASE_DIR="/Users/ssy/Documents/Claude/求职/daily"
POOL="$BASE_DIR/question-pool.json"
USED="$BASE_DIR/used-questions.txt"
TODAY=$(date +%Y-%m-%d)
OUTFILE="$BASE_DIR/$TODAY.md"

# Init used-questions if missing
touch "$USED"

# Check if already generated today
if [ -f "$OUTFILE" ]; then
  exit 0
fi

# Pick a question that hasn't been used yet, or reset if all used
TOTAL=$(python3 -c "import json; print(len(json.load(open('$POOL'))))" 2>/dev/null)
USED_COUNT=$(wc -l < "$USED" | tr -d ' ')

if [ "$USED_COUNT" -ge "$TOTAL" ]; then
  # All questions used — keep only the last 7 as "recently used" and reset the rest
  tail -7 "$USED" > "$USED.tmp" && mv "$USED.tmp" "$USED"
fi

# Pick a random unused question
Q=$(python3 -c "
import json, random, sys
pool = json.load(open('$POOL'))
used = set()
try:
    with open('$USED') as f:
        used = set(line.strip() for line in f if line.strip())
except: pass

available = [q for q in pool if q['q'] not in used]
if not available:
    available = pool  # fallback: reuse old ones

pick = random.choice(available)
print(pick['q'])
# Record it
with open('$USED', 'a') as f:
    f.write(pick['q'] + '\n')
" 2>&1)

# Map type to label
TYPE=$(python3 -c "
import json
pool = json.load(open('$POOL'))
for q in pool:
    if q['q'] == '''$Q''':
        print(q['type'])
        break
" 2>/dev/null)

# Write the daily file
cat > "$OUTFILE" << EOF
# 每日训练 · $TODAY

> 题型：**$TYPE**｜预计用时：15-20 分钟

## 今日问题

$Q

---

## 你的回答

*写出你的论证。记住：*

- **持方辩论** → 选一边，给出三个论据，然后指出自己最大的弱点
- **逻辑挑错** → 精确指出谬误类型，不用情绪用逻辑
- **一句话讲清楚** → 写完念出声，卡了就重写
- **魔鬼代言人** → 为你不同意的立场辩护，用事实不用情绪

---

> 💡 写完可以贴到 Claude Code 让我 review 你的论证结构。
EOF

echo "Generated: $OUTFILE ($TYPE)"
