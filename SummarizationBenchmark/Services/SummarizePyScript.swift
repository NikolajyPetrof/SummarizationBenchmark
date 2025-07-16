// Auto-generated: Python script for Summarize
import Foundation

/// Returns the contents of the summarize.py script used for summarization
func summarizePyScriptContents() -> String {
    return """
    #!/usr/bin/env python3
    # -*- coding: utf-8 -*-

    import sys
    import os
    import argparse
    import json
    from typing import Optional, Dict, Any

    # Скрипт суммаризации с поддержкой различных типов моделей
    try:
        from transformers import AutoTokenizer, AutoModelForSeq2SeqLM, AutoModelForCausalLM, pipeline
        import torch
    except ImportError:
        print("Error: The transformers library is required")
        print("Run: pip install transformers torch")
        sys.exit(1)

    def parse_arguments():
        parser = argparse.ArgumentParser(description='Text summarization')
        
        input_group = parser.add_mutually_exclusive_group(required=True)
        input_group.add_argument('--text', type=str, help='Text to summarize')
        input_group.add_argument('--file', type=str, help='Path to file containing text to summarize')
        
        parser.add_argument('--model', type=str, default='facebook/bart-large-cnn',
                          help='Path to model or Hugging Face identifier')
        parser.add_argument('--max-tokens', type=int, default=256,
                          help='Maximum number of tokens to generate')
        parser.add_argument('--temperature', type=float, default=0.3,
                          help='Generation temperature (0.0-1.0)')
        parser.add_argument('--top-p', type=float, default=0.8,
                          help='Top-p for generation (0.0-1.0)')
        parser.add_argument('--verbose', action='store_true',
                          help='Show additional information')
        
        return parser.parse_args()

    def create_prompt(text, model_name):
        # For summarization models (BART, T5, Pegasus) no special prompt is needed
        if any(name in model_name.lower() for name in ["bart", "t5", "pegasus", "distilbart"]):
            return text
        
        # For chat models (Gemma, Llama, Phi, GPT) use a structured prompt
        elif any(name in model_name.lower() for name in ["gemma", "llama", "phi", "gpt", "mistral"]):
            return f"Text: {text}\n\nSummary:"
        
        # For all other models use a more detailed prompt
        else:
            return f"Summarize the following text concisely:\n\n{text}\n\nSummary:"

    def summarize(text, model_path, max_tokens=256, temperature=0.3, top_p=0.8, verbose=False):
        if verbose:
            print(f"Loading model {model_path}...", file=sys.stderr)
        
        # Determine model type
        is_summarization_model = any(name in model_path.lower() for name in ["bart", "t5", "pegasus", "distilbart", "flan"])
        is_causal_lm = any(name in model_path.lower() for name in ["gemma", "llama", "phi", "gpt", "mistral"])
        
        try:
            if is_summarization_model:
                # Use pipeline for summarization models
                if verbose:
                    print(f"Using summarization pipeline for {model_path}", file=sys.stderr)
                
                # Create summarization pipeline
                summarizer = pipeline(
                    'summarization', 
                    model=model_path,
                    tokenizer=model_path,
                    device=0 if torch.cuda.is_available() else -1
                )
                
                # Configure summarization parameters
                result = summarizer(text, 
                                   max_length=max_tokens, 
                                   min_length=min(50, max_tokens // 4),
                                   do_sample=temperature > 0,
                                   temperature=temperature,
                                   top_p=top_p,
                                   no_repeat_ngram_size=3)
                
                # Extract the result
                summary = result[0]['summary_text']
                
                if verbose:
                    print(f"Generated summary using pipeline: {len(summary)} chars", file=sys.stderr)
                
                return summary.strip()
            
            else:
                # For non-summarization models, use a direct approach
                if verbose:
                    print(f"Using causal language model approach for {model_path}", file=sys.stderr)
                
                # Загружаем токенизатор и модель
                tokenizer = AutoTokenizer.from_pretrained(model_path)
                model = AutoModelForCausalLM.from_pretrained(model_path)
                
                # Создаем промпт для модели
                prompt = create_prompt(text, model_path)
                
                if verbose:
                    print(f"Prompt created, length: {len(prompt)} characters", file=sys.stderr)
                    print(f"Generating summary...", file=sys.stderr)
                
                # Кодируем входные данные
                inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=1024)
                
                # Генерируем суммаризацию
                # Для моделей типа Gemma, Llama, Phi
                with torch.no_grad():
                    outputs = model.generate(
                        inputs["input_ids"],
                        max_length=inputs["input_ids"].shape[1] + max_tokens,
                        temperature=temperature,
                        top_p=top_p,
                        do_sample=temperature > 0.0,
                        pad_token_id=tokenizer.eos_token_id
                    )
                    generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
                    
                    # Извлекаем только суммаризацию из ответа
                    if "Summary:" in generated_text:
                        summary = generated_text.split("Summary:")[1].strip()
                    else:
                        # Если не нашли маркер, возвращаем все сгенерированное после промпта
                        summary = generated_text[len(prompt):].strip()
                    
                    if verbose:
                        print(f"Generated summary using causal LM: {len(summary)} chars", file=sys.stderr)
                    
                    return summary.strip()
                    
        except Exception as e:
            # In case of error with the primary approach, try a fallback method
            if verbose:
                print(f"Error with primary approach: {str(e)}. Trying fallback method.", file=sys.stderr)
            
            # Запасной вариант - используем простой pipeline
            try:
                summarizer = pipeline('summarization', model=model_path)
                result = summarizer(text, max_length=max_tokens, min_length=30)
                return result[0]['summary_text'].strip()
            except Exception as e2:
                # Если и это не сработало, возвращаем ошибку
                error_msg = f"Failed to summarize: {str(e)}. Fallback also failed: {str(e2)}"
                print(error_msg, file=sys.stderr)
                raise Exception(error_msg)

    def main():
        args = parse_arguments()
        
        # Get text for summarization
        if args.text:
            text = args.text
        else:
            try:
                with open(args.file, 'r', encoding='utf-8') as f:
                    text = f.read()
            except Exception as e:
                print(f"Error reading file: {e}", file=sys.stderr)
                sys.exit(1)
        
        try:
            # Суммаризируем текст
            summary = summarize(
                text=text,
                model_path=args.model,
                max_tokens=args.max_tokens,
                temperature=args.temperature,
                top_p=args.top_p,
                verbose=args.verbose
            )
            
            # Выводим результат
            print(summary)
            
        except Exception as e:
            print(f"Error during summarization: {e}", file=sys.stderr)
            sys.exit(1)

    if __name__ == "__main__":
        main()
    """
}
