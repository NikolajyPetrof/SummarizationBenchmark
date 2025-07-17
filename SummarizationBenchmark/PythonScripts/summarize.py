#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import time
import argparse
import platform
from typing import Optional

def parse_arguments():
    parser = argparse.ArgumentParser(description='Text summarization with MLX and Transformers support')
    parser.add_argument('file', type=str, help='Path to file with text to summarize')
    parser.add_argument('model', type=str, help='Model name or path')
    parser.add_argument('max_tokens', type=int, help='Maximum tokens in summary')
    parser.add_argument('temperature', type=float, help='Generation temperature')
    parser.add_argument('top_p', type=float, help='Top-p for generation')
    parser.add_argument('--use-mlx', action='store_true', help='Use MLX framework')
    parser.add_argument('--verbose', action='store_true', help='Verbose output')
    return parser.parse_args()

def check_dependencies(verbose=False):
    """Check and report on available dependencies"""
    deps = {
        'transformers': False,
        'torch': False,
        'mlx': False,
        'mlx_lm': False
    }
    
    try:
        import transformers
        deps['transformers'] = True
        if verbose:
            print(f"✅ Transformers version: {transformers.__version__}", file=sys.stderr)
    except ImportError:
        if verbose:
            print("❌ Transformers not available", file=sys.stderr)
    
    try:
        import torch
        deps['torch'] = True
        if verbose:
            print(f"✅ PyTorch version: {torch.__version__}", file=sys.stderr)
    except ImportError:
        if verbose:
            print("❌ PyTorch not available", file=sys.stderr)
    
    try:
        import mlx
        deps['mlx'] = True
        if verbose:
            print(f"✅ MLX available", file=sys.stderr)
    except ImportError:
        if verbose:
            print("❌ MLX not available", file=sys.stderr)
    
    try:
        import mlx_lm
        deps['mlx_lm'] = True
        if verbose:
            print(f"✅ MLX-LM available", file=sys.stderr)
    except ImportError:
        if verbose:
            print("❌ MLX-LM not available", file=sys.stderr)
    
    return deps

def is_apple_silicon():
    """Check if running on Apple Silicon"""
    return platform.processor() == "arm" or platform.machine() == "arm64"

def is_mlx_model(model_name):
    """Check if model is from mlx-community"""
    return "mlx-community" in model_name.lower()

def create_prompt_for_model(text, model_name):
    """Create appropriate prompt based on model type"""
    if "smollm" in model_name.lower():
        return f"""Summarize the following text concisely:

{text}

Summary:"""
    
    elif "gemma" in model_name.lower():
        return f"""<start_of_turn>user
Please provide a concise summary of the following text:
{text}
<end_of_turn>
<start_of_turn>model
"""
    
    elif "llama" in model_name.lower():
        return f"""<|begin_of_text|><|start_header_id|>user<|end_header_id|>

Please summarize the following text:
{text}<|eot_id|><|start_header_id|>assistant<|end_header_id|>

"""
    
    elif "phi" in model_name.lower():
        return f"""<|user|>
Summarize this text:
{text}
<|assistant|>
"""
    
    else:
        return f"""Summarize the following text:

{text}

Summary:"""

def summarize_with_mlx(text, model_name, max_tokens, temperature, verbose=False):
    """Summarize text using MLX framework"""
    try:
        if verbose:
            print(f"🔄 Attempting MLX summarization with {model_name}", file=sys.stderr)
        
        from mlx_lm import load, generate
        
        # Load model
        if verbose:
            print(f"📥 Loading MLX model: {model_name}", file=sys.stderr)
        
        model, tokenizer = load(model_name)
        
        if verbose:
            print("✅ MLX model loaded successfully", file=sys.stderr)
        
        # Create prompt
        prompt = create_prompt_for_model(text, model_name)
        
        if verbose:
            print(f"🎯 Generated prompt ({len(prompt)} chars)", file=sys.stderr)
            print("🔄 Starting MLX generation...", file=sys.stderr)
        
        # Generate summary
        response = generate(
            model,
            tokenizer,
            prompt=prompt,
            max_tokens=max_tokens,
            temp=temperature,
            verbose=False  # MLX internal verbose
        )
        
        # Extract summary from response
        if "gemma" in model_name.lower():
            if "<end_of_turn>" in response:
                summary = response.split("<end_of_turn>")[0].strip()
            else:
                summary = response.replace(prompt, "").strip()
        elif "llama" in model_name.lower():
            if "<|eot_id|>" in response:
                summary = response.split("<|eot_id|>")[0].strip()
            else:
                summary = response.replace(prompt, "").strip()
        elif "Summary:" in response:
            summary = response.split("Summary:")[1].strip()
        else:
            summary = response.replace(prompt, "").strip()
        
        if verbose:
            print(f"✅ MLX generation completed ({len(summary)} chars)", file=sys.stderr)
        
        return summary
        
    except Exception as e:
        if verbose:
            print(f"❌ MLX error: {str(e)}", file=sys.stderr)
        return None

def summarize_with_transformers(text, model_name, max_tokens, temperature, top_p, verbose=False):
    """Summarize text using Transformers library"""
    try:
        if verbose:
            print(f"🔄 Attempting Transformers summarization with {model_name}", file=sys.stderr)
        
        from transformers import pipeline, AutoTokenizer, AutoModelForCausalLM
        import torch
        
        # For standard summarization models
        if any(name in model_name.lower() for name in ["bart", "t5", "pegasus"]):
            if verbose:
                print("📥 Loading summarization pipeline", file=sys.stderr)
            
            summarizer = pipeline(
                "summarization",
                model=model_name,
                max_length=max_tokens,
                min_length=30,
                do_sample=temperature > 0,
                temperature=temperature,
                top_p=top_p
            )
            
            result = summarizer(text)
            return result[0]["summary_text"]
        
        # For causal language models
        else:
            if verbose:
                print("📥 Loading causal language model", file=sys.stderr)
            
            tokenizer = AutoTokenizer.from_pretrained(model_name)
            model = AutoModelForCausalLM.from_pretrained(model_name)
            
            prompt = create_prompt_for_model(text, model_name)
            
            inputs = tokenizer(prompt, return_tensors="pt", truncation=True, max_length=2048)
            
            with torch.no_grad():
                outputs = model.generate(
                    inputs.input_ids,
                    max_new_tokens=max_tokens,
                    temperature=temperature,
                    top_p=top_p,
                    do_sample=temperature > 0,
                    pad_token_id=tokenizer.eos_token_id
                )
            
            generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
            
            # Extract summary
            if "Summary:" in generated_text:
                summary = generated_text.split("Summary:")[1].strip()
            else:
                summary = generated_text.replace(prompt, "").strip()
            
            if verbose:
                print(f"✅ Transformers generation completed ({len(summary)} chars)", file=sys.stderr)
            
            return summary
            
    except Exception as e:
        if verbose:
            print(f"❌ Transformers error: {str(e)}", file=sys.stderr)
        return None

def fallback_summarization(text, max_tokens, verbose=False):
    """Fallback to BART summarization"""
    try:
        if verbose:
            print("🔄 Using fallback BART model", file=sys.stderr)
        
        from transformers import pipeline
        
        summarizer = pipeline(
            "summarization",
            model="facebook/bart-large-cnn",
            max_length=max_tokens,
            min_length=30,
            do_sample=False
        )
        
        result = summarizer(text)
        
        if verbose:
            print("✅ Fallback summarization completed", file=sys.stderr)
        
        return result[0]["summary_text"]
        
    except Exception as e:
        if verbose:
            print(f"❌ Fallback error: {str(e)}", file=sys.stderr)
        return f"Error: Could not summarize text. All methods failed."

def main():
    args = parse_arguments()
    
    if args.verbose:
        print("=" * 50, file=sys.stderr)
        print("📝 SUMMARIZATION SCRIPT", file=sys.stderr)
        print("=" * 50, file=sys.stderr)
        print(f"📁 Input file: {args.file}", file=sys.stderr)
        print(f"🤖 Model: {args.model}", file=sys.stderr)
        print(f"📊 Max tokens: {args.max_tokens}", file=sys.stderr)
        print(f"🌡️ Temperature: {args.temperature}", file=sys.stderr)
        print(f"🎯 Top-p: {args.top_p}", file=sys.stderr)
        print(f"🍎 Use MLX: {args.use_mlx}", file=sys.stderr)
        print(f"💻 Platform: {platform.platform()}", file=sys.stderr)
        print(f"🔧 Apple Silicon: {is_apple_silicon()}", file=sys.stderr)
        print(f"📦 MLX Model: {is_mlx_model(args.model)}", file=sys.stderr)
        print("=" * 50, file=sys.stderr)
    
    # Check dependencies
    deps = check_dependencies(args.verbose)
    
    # Read input text
    try:
        with open(args.file, 'r', encoding='utf-8') as f:
            text = f.read().strip()
        
        if args.verbose:
            print(f"📖 Read text: {len(text)} characters, {len(text.split())} words", file=sys.stderr)
    except Exception as e:
        print(f"Error reading file: {e}", file=sys.stderr)
        sys.exit(1)
    
    if not text:
        print("Error: Input text is empty", file=sys.stderr)
        sys.exit(1)
    
    start_time = time.time()
    summary = None
    
    # Strategy 1: Use MLX if requested and available for mlx-community models
    if args.use_mlx and is_mlx_model(args.model) and is_apple_silicon() and deps['mlx_lm']:
        summary = summarize_with_mlx(
            text, args.model, args.max_tokens, args.temperature, args.verbose
        )
    
    # Strategy 2: Use Transformers for non-MLX models or if MLX failed
    if not summary and deps['transformers'] and not is_mlx_model(args.model):
        summary = summarize_with_transformers(
            text, args.model, args.max_tokens, args.temperature, args.top_p, args.verbose
        )
    
    # Strategy 3: Fallback to BART
    if not summary and deps['transformers']:
        if args.verbose:
            print("⚠️ Primary methods failed, using fallback", file=sys.stderr)
        summary = fallback_summarization(text, args.max_tokens, args.verbose)
    
    # Final check
    if not summary or summary.startswith("Error:"):
        if is_mlx_model(args.model):
            print("Error: MLX-community models require MLX framework on Apple Silicon. Install dependencies from the app menu.", file=sys.stderr)
        else:
            print("Error: All summarization methods failed. Check dependencies.", file=sys.stderr)
        sys.exit(1)
    
    end_time = time.time()
    
    if args.verbose:
        print("=" * 50, file=sys.stderr)
        print(f"⏱️ Generation time: {end_time - start_time:.2f} seconds", file=sys.stderr)
        print(f"📏 Summary length: {len(summary)} characters, {len(summary.split())} words", file=sys.stderr)
        print("=" * 50, file=sys.stderr)
    
    print(summary)

if __name__ == "__main__":
    main()
