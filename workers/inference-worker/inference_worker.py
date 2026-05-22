import os
from typing import Any, Dict, List

from dotenv import load_dotenv
from iii import InitOptions, Logger, register_worker
from transformers import AutoModelForCausalLM, AutoTokenizer

load_dotenv()

iii = register_worker(
    os.environ.get("III_URL", "ws://localhost:49134"),
    InitOptions(worker_name="inference-worker"),
)
logger = Logger()

# 1. Install dependencies
# pip install transformers accelerate gguf torch


# model_id = "ggml-org/gemma-3-270m-GGUF" # "Qwen/Qwen3-0.6B-GGUF"
# gguf_file = "gemma-3-270m-Q8_0.gguf" # "Qwen3-0.6B-Q8_0.gguf"  # Q8 quantized variant
model_id = "QuantFactory/SmolLM2-135M-Instruct-GGUF"
gguf_file = "SmolLM2-135M-Instruct.Q4_K_M.gguf"
MAX_NEW_TOKENS = 256

CHAT_TEMPLATE = """{%- for message in messages -%}
<|im_start|>{{ message['role'] }}
{{ message['content'] | trim }}<|im_end|>
{%- endfor -%}
{%- if add_generation_prompt -%}
<|im_start|>assistant
{%- endif -%}"""

logger.info("Loading inference model", {"model_id": model_id, "gguf_file": gguf_file})
hf_token = os.environ.get("HF_TOKEN") or None
tokenizer = AutoTokenizer.from_pretrained(model_id, gguf_file=gguf_file, token=hf_token)
model = AutoModelForCausalLM.from_pretrained(model_id, gguf_file=gguf_file, token=hf_token)
tokenizer.chat_template = CHAT_TEMPLATE
logger.info("Inference model loaded")


# 3. Run inference
def run_inference_handler(payload: Dict[str, str | List[Dict[str, Any]]]) -> Dict[str, Any]:
    # prompt = "Explain quantum entanglement in simple terms."
    try:
        messages = payload.get("messages", [])
        if not messages:
            return {"error": "messages must contain at least one message", "status": "bad_request"}

        print("Received messages for inference:", messages)

        logger.info("Received messages for inference", {"messages": messages, "max_tokens": MAX_NEW_TOKENS})

        text = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        print("step1")
        inputs = tokenizer(text, return_tensors="pt").to(model.device)
        print("step2")

        output = model.generate(**inputs, max_new_tokens=MAX_NEW_TOKENS)
        print("step3")

        result = tokenizer.decode(output[0][inputs["input_ids"].shape[-1]:], skip_special_tokens=True)
        print("step4")

        print(result)
    except Exception as exc:
        logger.error("Inference failed", {"error": str(exc)})
        return {
            "error": "Sorry, the inference model is still loading or failed to load. Please try again in a few minutes.",
            "status": "model_unavailable",
            "details": str(exc),
        }

    # running_inference = iii.trigger(
    #     {
    #         "function_id": "inference::get",
    #         "payload": {"scope": "math", "key": "running_inference"},
    #     }
    # )
    # new_result = payload | {"messages": payload["messages"] + (running_inference or [])}
    # iii.trigger(
    #     {
    #         "function_id": "inference::set",
    #         "payload": {"scope": "math", "key": "running_inference", "value": new_result},
    #     }
    # )
    # result["running_inference"] = new_result
    return {"assistant": result}

# def add_handler(payload: dict) -> dict:
#     a = payload.get("a", 0)
#     b = payload.get("b", 0)
#     logger.info(f"math::add called in Python with a={a}, b={b}")
#     result = {"c": a + b}

#     # --- Uncomment after: iii worker add iii-state ---
#     running_total = iii.trigger(
#         {
#             "function_id": "state::get",
#             "payload": {"scope": "math", "key": "running_total"},
#         }
#     )
#     new_total = (running_total or 0) + result["c"]
#     iii.trigger(
#         {
#             "function_id": "state::set",
#             "payload": {"scope": "math", "key": "running_total", "value": new_total},
#         }
#     )
#     result["running_total"] = new_total

#     return result


# iii.register_function("math::add", add_handler)
iii.register_function("inference::run_inference", run_inference_handler)

print("Inference worker started - listening for calls")
