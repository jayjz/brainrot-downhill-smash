@echo off
title Hermes Critic Server (Qwen Coder 7B)
echo ========================================
echo Starting HERMES CRITIC Server
echo Model: Qwen-Coder-7B-Obliterated (Q4_K_M)
echo Hardware Target: RTX 4060 (8GB VRAM Strict Limit)
echo Port: 8080 (OpenAI API Compatible)
echo ========================================

"C:\llama.cpp-cuda12\llama-server.exe" ^
  -m "C:\Models\qwen-coder-7b-obliterated-q4_k_m.gguf" ^
  --host 0.0.0.0 ^
  --port 8080 ^
  -c 16384 ^
  -ngl 999 ^
  --cache-type-k q8_0 ^
  --cache-type-v q8_0 ^
  --flash-attn on ^
  --parallel 1 ^
  --threads 6 ^
  --alias qwen-critic

pause
