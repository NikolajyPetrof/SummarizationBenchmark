#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import argparse
import json
from typing import Optional, Dict, Any

try:
    import mlx.core as mx
    from mlx_vlm.models import Gemma
except ImportError:
    print("Ошибка: Необходимо установить библиотеки mlx и mlx-vlm.")
    print("Выполните: pip install mlx mlx-vlm")
    sys.exit(1)

def parse_arguments():
    parser = argparse.ArgumentParser(description='Суммаризация текста с использованием Gemma 3')
    
    input_group = parser.add_mutually_exclusive_group(required=True)
    input_group.add_argument('--text', type=str, help='Текст для суммаризации')
    input_group.add_argument('--file', type=str, help='Путь к файлу с текстом для суммаризации')
    
    parser.add_argument('--model', type=str, default='mlx-community/gemma-3-1b-it-8bit',
                      help='Путь к модели или идентификатор на Hugging Face')
    parser.add_argument('--max-tokens', type=int, default=256,
                      help='Максимальное количество токенов для генерации')
    parser.add_argument('--temperature', type=float, default=0.3,
                      help='Температура для генерации (0.0-1.0)')
    parser.add_argument('--top-p', type=float, default=0.8,
                      help='Top-p для генерации (0.0-1.0)')
    parser.add_argument('--verbose', action='store_true',
                      help='Выводить дополнительную информацию')
    
    return parser.parse_args()

def create_prompt(text: str) -> str:
    """Создает промпт для суммаризации текста."""
    return f"""Text: {text}

Summary:"""

def summarize(text: str, model_path: str, max_tokens: int = 256, 
              temperature: float = 0.3, top_p: float = 0.8, 
              verbose: bool = False) -> str:
    """
    Суммаризирует текст с использованием модели Gemma.
    
    Args:
        text: Текст для суммаризации
        model_path: Путь к модели или идентификатор на Hugging Face
        max_tokens: Максимальное количество токенов для генерации
        temperature: Температура для генерации
        top_p: Top-p для генерации
        verbose: Выводить дополнительную информацию
        
    Returns:
        Суммаризированный текст
    """
    if verbose:
        print(f"Загрузка модели {model_path}...", file=sys.stderr)
    
    # Загрузка модели
    model = Gemma(model_path)
    
    # Создание промпта
    prompt = create_prompt(text)
    
    if verbose:
        print(f"Промпт создан, длина: {len(prompt)} символов", file=sys.stderr)
        print(f"Генерация суммаризации...", file=sys.stderr)
    
    # Генерация суммаризации
    stop_tokens = ["Text:", "Summary:", "\n\n", "User:", "Assistant:"]
    
    generation = model.generate(
        prompt=prompt,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        stop=stop_tokens
    )
    
    if verbose:
        print(f"Суммаризация завершена", file=sys.stderr)
    
    return generation.strip()

def main():
    args = parse_arguments()
    
    # Получение текста для суммаризации
    if args.text:
        text = args.text
    else:
        try:
            with open(args.file, 'r', encoding='utf-8') as f:
                text = f.read()
        except Exception as e:
            print(f"Ошибка при чтении файла: {e}", file=sys.stderr)
            sys.exit(1)
    
    try:
        # Суммаризация текста
        summary = summarize(
            text=text,
            model_path=args.model,
            max_tokens=args.max_tokens,
            temperature=args.temperature,
            top_p=args.top_p,
            verbose=args.verbose
        )
        
        # Вывод результата
        print(summary)
        
    except Exception as e:
        print(f"Ошибка при суммаризации: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
