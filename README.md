# Architecture

<img width="1737" height="777" alt="Screenshot 2026-05-22 at 15-16-23" src="https://github.com/user-attachments/assets/58be5c44-4c44-4b0a-a265-0413fb38be29" />


```text
Client
  |
  | POST /v1/chat/completions
  v
Caddy + iii API VM (public subnet)
  |
  | WebSocket RPC on private IP:49134
  v
TypeScript caller worker (private subnet)
  |
  | inference::run_inference
  v
Python inference worker (private subnet)
```


## Live API
```sh
curl -X POST http://16.112.19.3/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Explain RPC in one sentence."}]}'
```

## Setup
### 1. Configure AWS credentials

```sh
aws configure
```

or export credentials directly:

```sh
export AWS_ACCESS_KEY_ID=your_access_key_id
export AWS_SECRET_ACCESS_KEY=your_secret_access_key
export AWS_DEFAULT_REGION=ap-south-2
```
**Pls crate a ssh key of name 'alchemy-test-2' before proceeding via terraform scipts**

### 2. Deploy with Terraform

```sh
git clone https://github.com/stefanbinoj/iii-workers.git
cd iii-workers/infra
terraform plan // Optional for previewing changes
terraform apply
```

Terraform outputs:

```sh
api_public_ip  
worker_1_private_ip 
worker_2_private_ip
```

> The instances usually need **2-5 minutes** after provisioning to install Docker, Node.js, Python dependencies, and load the model.

> Note: since AWS free-tier-friendly instance max size is `c7i-flex.large`. The original Gemma model was too heavy for smooth startup/inference on this instance class, so the inference worker uses `SmolLM2-135M-Instruct` and caps generation at `256` tokens for more predictable response times.

### 3. To destroy all AWS resources created:

```sh
terraform destroy
```

## API Contract

Endpoint:

```text
POST http://<api_public_ip>/v1/chat/completions
Content-Type: application/json
```

Request:

```json
{
  "messages": [
    {
      "role": "user",
      "content": "Explain RPC in one sentence."
    }
  ]
}
```

Response:

```json
{
  "assistant": "RPC lets one process call functionality running in another process or machine as if it were local."
}
```

Error response while the model is still loading or unavailable:

```json
{
  "error": "Sorry, the inference model is still loading or failed to load. Please try again in a few minutes.",
  "status": "model_unavailable",
  "details": "<runtime error details>"
}
```

**what you would harden before putting this in production?**


- Make it HTTPS (Secured wiht TLS)
- Put an WAF for blocking DDOS and malicious traffic
- API Gateway(for throttling, rate limiting, request size limits, timeout configuration, authentication, logging)
- Maybe Load Balancer if high traffic is there.  


**what you would do differently if the model were 100x larger?**

- Moving off to GPU-based inference (I've heard of SageMaker -- I'm not sure tho)
- Having a more optimized runtime like vLLM, TGI, TensorRT-LLM, or llama.cpp 
- Pulling a small model itself takes 2-3 minutes so ig, I would have to bake the model into an OS image and use that image (hosted in a private artifact registery) 
- Something out of our hands but listing -- quantization, batching, KV cache, .. (optimizing model 😭)


