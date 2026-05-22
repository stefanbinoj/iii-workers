# Architecture

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

| Component          | Runtime            | Responsibility                                                                   |
| ------------------ | ------------------ | -------------------------------------------------------------------------------- |
| API gateway VM     | Docker, Caddy, iii | Exposes HTTP and reverse-proxies traffic to the iii runtime.                     |
| `caller-worker`    | TypeScript         | Registers the HTTP trigger and forwards requests to the inference function.      |
| `inference-worker` | Python             | Loads `SmolLM2-135M-Instruct` GGUF and returns generated assistant text.         |
| Terraform infra    | AWS                | Provisions VPC, public/private subnets, security groups, NAT, and EC2 instances. |

## Live Smoke Test

```sh
curl -X POST http://18.61.41.131/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"role":"user","content":"Explain RPC in one sentence."}]}'
```

## AWS Deployment

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

### 2. Deploy with Terraform

```sh
git clone https://github.com/stefanbinoj/iii-workers.git
cd iii-workers/infra
terraform plan // Optional for previewing changes
terraform apply
```

Terraform outputs:

| Output                | Description                                  |
| --------------------- | -------------------------------------------- |
| `api_public_ip`       | Public IP for the HTTP API gateway.          |
| `worker_1_private_ip` | Private IP for the Python inference worker.  |
| `worker_2_private_ip` | Private IP for the TypeScript caller worker. |

The instances usually need 2-5 minutes after provisioning to install Docker, Node.js, Python dependencies, and load the model.

Note: since AWS free-tier-friendly instance max size is `c7i-flex.large`. The original Gemma model was too heavy for smooth startup/inference on this instance class, so the inference worker uses `SmolLM2-135M-Instruct` and caps generation at `256` tokens for more predictable response times.

To destroy all AWS resources created:

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

## Production Hardening

Before production, I would prioritize:

- Remote Terraform state with locking, instead of local state files.
- Restricting SSH access to a trusted IP range or replacing it with AWS Systems Manager Session Manager.
- TLS with a real domain, managed certificates, and HTTP-to-HTTPS redirects.
- Moving secrets such as Hugging Face tokens into AWS Secrets Manager or SSM Parameter Store.
- Health checks, structured logs, metrics, alarms, and bootstrap failure visibility.
- Immutable deploy artifacts or AMIs instead of cloning from GitHub during EC2 startup.
- Autoscaling and queue-based backpressure for inference traffic.

## Scaling the Model 100x

For a much larger model, I would change the serving layer rather than only resizing EC2:

- Use GPU instances or a managed inference platform.
- Package model weights separately and cache them close to compute.
- Serve through an optimized inference runtime such as vLLM, TGI, or Triton.
- Split API, orchestration, and model serving into independently scalable tiers.
- Add request queuing, batching, rate limits, and timeout controls.
- Track model load time, token latency, GPU utilization, and error budgets.
