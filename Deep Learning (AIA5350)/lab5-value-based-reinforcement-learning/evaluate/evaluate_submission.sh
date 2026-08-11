#!/usr/bin/env bash
# Lab 5 — TA evaluation. From repo root after: pip install -r requirements.txt
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export PYTHONUNBUFFERED=1
# Optional: force device
# export CUDA_VISIBLE_DEVICES=0

# Task 1 — CartPole-v1
python test_model_task1.py \
  --model_path "../LAB5_b11505034_task1.pt" \
  --output_dir "eval_outputs/task1"

# Task 2 — ALE/Pong-v5
python test_model_task2.py \
  --model_path "../LAB5_b11505034_task2.pt" \
  --output_dir "eval_outputs/task2"

# Task 3 — ALE/Pong-v5 (milestones: 600k … 2M env steps)
for steps in 600000 1000000 1500000 2000000; do
  python test_model_task3.py \
    --model_path "../LAB5_b11505034_task3_${steps}.pt" \
    --output_dir "eval_outputs/task3_${steps}"
done

echo "Done. Mean return is printed at the end of each block (mean_return=...)."
