import type { E2EConfig } from 'e2e';
import { web } from '@e2e-dev/web';
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

// Fully local vision model via Ollama's OpenAI-compatible endpoint (no
// sign-in, no key). The community ollama-ai-provider-v2 Responses adapter
// crashes client-side on e2e's screenshot parts
// (convertBase64ToUint8Array(undefined)), so the chat-completions path is
// used instead. The Flutter web build renders to canvas, so the agent
// drives by screenshot.
const local = createOpenAICompatible({
  name: 'local',
  baseURL: 'http://127.0.0.1:11434/v1',
});

// Web target serves the Flutter web release build (build/web) of the Noor
// app: the same Dart code and UI as the Android build. The runner starts and
// stops the static server itself, so runs are self-contained locally and
// in CI. (A mobile/Android target is wanted long-term, but the agent-device
// daemon cannot start on Windows — two upstream bugs reported to the e2e
// team: ftruncate-on-append EPERM killing the daemon, and an ownership
// handshake that never establishes. Refs available in the e2e setup notes.)
export default {
  // Local CPU inference is slow: generous per-attempt budget for agent steps.
  timeout: 600_000,
  targets: [
    {
      // Portrait phone viewport: matches the app's mobile layout and keeps
      // screenshot token load small for local inference.
      engine: web({ viewport: { width: 412, height: 915 } }),
      app: {
        url: 'http://127.0.0.1:3000',
        command: {
          executable: 'node',
          args: ['e2e/serve-web.cjs', '3000'],
          startupTimeout: 30_000,
          log: '.e2e/logs/app.log',
        },
      },
    },
  ],
  // Fully local vision+tools model (Ollama, no sign-in, no key). The
  // Flutter web build renders to canvas, so the agent drives by screenshot.
  // (qwen2.5vl:7b was tried first but Ollama serves it without tools, which
  // agent steps require; qwen3-vl advertises vision+tools.)
  agents: {
    default: {
      model: local.chatModel('qwen3-vl:4b'),
      system: 'You are a thorough QA agent. Verify every outcome on screen.',
      context:
        'The app UI is Arabic (RTL). Key labels: skip onboarding = تخطي, ' +
        'home = الرئيسية, Quran section = القرآن الكريم, Mushaf reader = المصحف, ' +
        'page indicator looks like صفحة 1 / 604, appearance = المظهر.',
    },
  },
} satisfies E2EConfig;
