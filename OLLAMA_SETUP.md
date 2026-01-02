# Setting up Ollama with Claude Code Router

This guide walks you through configuring Ollama as a local model provider for claude-code-router.

## Prerequisites

1. **Ollama installed**: Download from [ollama.ai](https://ollama.ai)
2. **Ollama running locally**: By default, Ollama listens on `http://localhost:11434`
3. **A model pulled**: Pull your desired model first, e.g., `ollama pull qwen2.5-coder:latest`

## Step 1: Start Ollama

Ollama typically runs as a background service. If it's not running, start it:

```bash
# macOS/Linux (if installed as service)
# It should already be running in the background

# Or manually start it:
ollama serve
```

Verify Ollama is running:

```bash
curl http://localhost:11434/api/tags
```

## Step 2: Pull a Model

Pull a model suitable for coding:

```bash
# Popular coding models
ollama pull qwen2.5-coder:latest
ollama pull deepseek-coder:latest
ollama pull codellama:latest
ollama pull mistral:latest

# Or get a smaller model for testing
ollama pull phi:latest
```

List available models:

```bash
ollama list
```

## Step 3: Configure Claude Code Router

Edit your `~/.claude-code-router/config.json` and add the Ollama provider:

### Minimal Configuration (Ollama Only)

```json
{
  "Providers": [
    {
      "name": "ollama",
      "api_base_url": "http://localhost:11434/v1/chat/completions",
      "api_key": "ollama",
      "models": ["qwen2.5-coder:latest"]
    }
  ],
  "Router": {
    "default": "ollama,qwen2.5-coder:latest"
  }
}
```

### Full Configuration (Multiple Providers)

```json
{
  "LOG": true,
  "LOG_LEVEL": "debug",
  "API_TIMEOUT_MS": 600000,
  "Providers": [
    {
      "name": "ollama",
      "api_base_url": "http://localhost:11434/v1/chat/completions",
      "api_key": "ollama",
      "models": [
        "qwen2.5-coder:latest",
        "deepseek-coder:latest",
        "codellama:latest"
      ]
    }
  ],
  "Router": {
    "default": "ollama,qwen2.5-coder:latest",
    "background": "ollama,phi:latest",
    "think": "ollama,deepseek-coder:latest"
  }
}
```

### With Multiple Providers

If you want to use Ollama alongside other providers:

```json
{
  "Providers": [
    {
      "name": "ollama",
      "api_base_url": "http://localhost:11434/v1/chat/completions",
      "api_key": "ollama",
      "models": ["qwen2.5-coder:latest", "deepseek-coder:latest"]
    },
    {
      "name": "openai",
      "api_base_url": "https://api.openai.com/v1/chat/completions",
      "api_key": "$OPENAI_API_KEY",
      "models": ["gpt-4", "gpt-4-turbo"]
    }
  ],
  "Router": {
    "default": "ollama,qwen2.5-coder:latest",
    "think": "openai,gpt-4"
  }
}
```

## Step 4: Restart the Router Service

For changes to take effect:

```bash
ccr restart
```

Or stop and start:

```bash
ccr stop
ccr start
```

## Step 5: Test the Configuration

Test using the CLI:

```bash
ccr code "Write a simple Hello World program in Python"
```

Or use the interactive model selector:

```bash
ccr model
```

## Troubleshooting

### Connection Error: "Cannot connect to localhost:11434"

- **Problem**: Ollama is not running
- **Solution**: 
  ```bash
  # Check if Ollama is running
  curl http://localhost:11434/api/tags
  
  # If not, start it
  ollama serve
  ```

### Model Not Found Error

- **Problem**: Model name doesn't match what you pulled
- **Solution**:
  ```bash
  # Check exact model names
  ollama list
  
  # Use the exact name in config.json (case-sensitive)
  ```

### Timeout Errors

- **Problem**: Model responses are too slow for default timeout
- **Solution**: Increase `API_TIMEOUT_MS` in config.json:
  ```json
  {
    "API_TIMEOUT_MS": 900000
  }
  ```

### Port Already in Use

- **Problem**: Port 11434 is in use by another service
- **Solution**: Configure Ollama to use a different port:
  ```bash
  OLLAMA_HOST=127.0.0.1:11435 ollama serve
  ```
  Then update `api_base_url` in config.json accordingly.

### Memory Issues

- **Problem**: Ollama runs out of memory with large models
- **Solution**:
  ```bash
  # Unload models to free memory
  ollama list
  ollama rm model_name
  
  # Or increase system swap/memory
  ```

## Model Recommendations

### For Code Generation
- **qwen2.5-coder** - Excellent for code (recommended)
- **deepseek-coder** - Fast and capable
- **codellama** - Specialized for code

### For Lightweight/CPU
- **phi** - Small but capable
- **neural-chat** - Smaller model
- **tinyllama** - Minimal resource usage

### For Reasoning
- **qwen2.5** - Good reasoning ability
- **mistral** - Balanced performance

## Advanced Configuration

### Using Ollama with a Remote Server

If Ollama is running on another machine:

```json
{
  "Providers": [
    {
      "name": "ollama",
      "api_base_url": "http://192.168.1.100:11434/v1/chat/completions",
      "api_key": "ollama",
      "models": ["qwen2.5-coder:latest"]
    }
  ]
}
```

### Combining with Transformers

Some transformers may not be needed for Ollama (which uses OpenAI-compatible format), but you can use:

```json
{
  "name": "ollama",
  "api_base_url": "http://localhost:11434/v1/chat/completions",
  "api_key": "ollama",
  "models": ["qwen2.5-coder:latest"],
  "transformer": {
    "use": [
      [
        "maxtoken",
        {
          "max_tokens": 8192
        }
      ]
    ]
  }
}
```

## Performance Tips

1. **Pull models with smaller variants**: `ollama pull qwen2.5-coder:7b-instruct` uses less memory than default
2. **Run background tasks on smaller models**: Use a different model in the `Router.background` setting
3. **Monitor Ollama memory**: Use `ollama ps` to see loaded models
4. **Keep models in memory**: Use `ollama keep-alive` parameter if needed

## Useful Ollama Commands

```bash
# List all pulled models
ollama list

# View currently loaded models
ollama ps

# Pull a specific model
ollama pull qwen2.5-coder:latest

# Remove a model to free space
ollama rm model_name

# Run a model interactively (for testing)
ollama run qwen2.5-coder:latest

# Check API health
curl http://localhost:11434/api/tags
```

## References

- [Ollama Documentation](https://github.com/ollama/ollama)
- [Claude Code Router README](README.md)
- [OpenAI API Compatibility](https://platform.openai.com/docs/api-reference/chat/create)
