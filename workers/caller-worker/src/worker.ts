import { Logger, registerWorker } from 'iii-sdk';

const iii = registerWorker(process.env.III_URL ?? 'ws://localhost:49134');
const logger = new Logger();

iii.registerFunction(
  'inference::get_response',
  async (payload: { messages: Record<string, any> } & Record<string, any>) => {
    console.log('Received payload in TypeScript worker:', payload);
    logger.info('inference::get_response called in TypeScript', payload);

    return iii.trigger({
      function_id: 'inference::run_inference',
      payload,
    });
  },
);

// --- Uncomment after: iii worker add iii-http ---
iii.registerFunction(
  'http::run_inference_over_http',
  async (payload: { body: { messages: Record<string, any> } & Record<string, any> }) => {
    try {
      const result = await iii.trigger({
        function_id: 'inference::get_response',
        payload: payload.body,
      });
      logger.info("Running http inference...");

      if (result?.status === 'model_unavailable') {
        return {
          status_code: 503,
          body: result,
          headers: { 'Content-Type': 'application/json' },
        };
      }

      return {
        status_code: 200,
        body: result,
        headers: { 'Content-Type': 'application/json' },
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('http::run_inference_over_http failed', { error: message });

      return {
        status_code: 503,
        body: {
          error: 'Sorry, the inference model is still loading or failed to load. Please try again in a few minutes.',
          status: 'model_unavailable',
          details: message,
        },
        headers: { 'Content-Type': 'application/json' },
      };
    }
  },
);

iii.registerTrigger({
  type: 'http',
  function_id: 'http::run_inference_over_http',
  config: { api_path: '/v1/chat/completions', http_method: 'POST' },
});

logger.info('Caller worker started - listening for calls');
