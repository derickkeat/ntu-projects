# Evaluation helpers for Lab 5: 20 episodes with env seeds 0..19, reported mean return.
import argparse
import os
import random
from typing import List, Tuple

import ale_py
import gymnasium as gym
import imageio
import numpy as np
import torch

gym.register_envs(ale_py)

from dqn_task1 import DQN as DQNTask1, CartPolePreprocessor
from dqn_task2 import DQN as DQNAtari, AtariPreprocessor

EVAL_EPISODES = 20
EVAL_SEEDS: Tuple[int, ...] = tuple(range(20))  # 0 .. 19


def _unwrap_state_dict(ckpt: object) -> dict:
    if not isinstance(ckpt, dict):
        raise ValueError("Checkpoint must be a state_dict or a dict wrapper.")
    if any(k.startswith("network.") for k in ckpt):
        return ckpt
    for key in ("q_net_state_dict", "model_state_dict", "state_dict"):
        inner = ckpt.get(key)
        if isinstance(inner, dict):
            return inner
    return ckpt


def load_q_weights(path: str, map_location) -> dict:
    ckpt = torch.load(path, map_location=map_location)
    return _unwrap_state_dict(ckpt)


def evaluate_task(
    task: int,
    model_path: str,
    output_dir: str,
    save_video: bool,
    device: torch.device,
) -> Tuple[List[float], float]:
    """Run 20 eval episodes (seeds 0..19). Returns per-episode returns and mean."""
    if task == 1:
        env_name = "CartPole-v1"
        env = gym.make(env_name, render_mode="rgb_array")
        preprocessor = CartPolePreprocessor()
        model = DQNTask1(env.action_space.n).to(device)
        def state_to_tensor(state: np.ndarray) -> torch.Tensor:
            return torch.from_numpy(np.asarray(state)).float().unsqueeze(0).to(device)
    elif task in (2, 3):
        env_name = "ALE/Pong-v5"
        env = gym.make(env_name, render_mode="rgb_array")
        preprocessor = AtariPreprocessor()
        model = DQNAtari(env.action_space.n).to(device)
        def state_to_tensor(state: np.ndarray) -> torch.Tensor:
            return torch.from_numpy(state).float().unsqueeze(0).to(device)
    else:
        raise ValueError(f"task must be 1, 2, or 3; got {task}")

    w = load_q_weights(model_path, map_location=device)
    model.load_state_dict(w)
    model.eval()

    os.makedirs(output_dir, exist_ok=True)
    episode_returns: List[float] = []

    for ep, seed in enumerate(EVAL_SEEDS):
        random.seed(seed)
        np.random.seed(seed)
        torch.manual_seed(seed)
        if device.type == "cuda":
            torch.cuda.manual_seed_all(seed)

        obs, _ = env.reset(seed=seed)
        env.action_space.seed(seed)
        env.observation_space.seed(seed)

        state = preprocessor.reset(obs)
        done = False
        total_reward = 0.0
        frames: List[np.ndarray] = []

        while not done:
            if save_video:
                frames.append(env.render())
            with torch.no_grad():
                action = model(state_to_tensor(state)).argmax().item()
            next_obs, reward, terminated, truncated, _ = env.step(action)
            done = terminated or truncated
            total_reward += float(reward)
            state = preprocessor.step(next_obs)

        episode_returns.append(total_reward)
        if save_video:
            out_path = os.path.join(output_dir, f"eval_ep{ep}.mp4")
            with imageio.get_writer(out_path, fps=30) as video:
                for f in frames:
                    video.append_data(f)
            print(f"episode {ep} seed={seed} return={total_reward:.4g} -> {out_path}")
        else:
            print(f"episode {ep} seed={seed} return={total_reward:.4g}")

    mean_ret = float(np.mean(episode_returns))
    print("---")
    print(f"task={task} episodes={EVAL_EPISODES} mean_return={mean_ret:.6f}")
    print(f"per_episode_returns={episode_returns}")
    env.close()
    return episode_returns, mean_ret


def build_arg_parser(task: int) -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=f"Lab 5 task {task} eval: seeds 0-19, {EVAL_EPISODES} episodes."
    )
    p.add_argument(
        "--model_path",
        "--model-path",
        dest="model_path",
        type=str,
        required=True,
        help="Path to q_net .pt (state_dict) from training.",
    )
    p.add_argument(
        "--output_dir",
        "--output-dir",
        dest="output_dir",
        type=str,
        default=f"./eval_outputs/task{task}",
        help="Directory for eval_ep*.mp4",
    )
    p.add_argument(
        "--no_video",
        "--no-video",
        dest="save_video",
        action="store_false",
        help="Skip writing videos (faster; still prints mean return).",
    )
    p.set_defaults(save_video=True)
    p.add_argument(
        "--device",
        type=str,
        default=None,
        help="cuda|cpu (default: auto)",
    )
    return p


def run_cli(task: int) -> None:
    args = build_arg_parser(task).parse_args()
    if args.device:
        device = torch.device(args.device)
    else:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    evaluate_task(
        task=task,
        model_path=args.model_path,
        output_dir=args.output_dir,
        save_video=args.save_video,
        device=device,
    )


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--task", type=int, required=True, choices=(1, 2, 3))
    ns = ap.parse_args()
    run_cli(ns.task)
