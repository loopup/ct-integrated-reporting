# AI Assistant Instructions

## Keeping Documentation Current

When making changes to this repository, update `README.md` to reflect any changes to:

- **API surface** — REST endpoints, gRPC methods, NServiceBus commands/events handled or published
- **Dependencies** — LoopUp NuGet/npm packages added or removed, external service calls added or changed
- **Configuration** — new or changed `appsettings.json` keys or environment variables
- **Infrastructure** — new databases, message queues, or external systems

Keep the structured AI-navigable sections current:

- `<!-- ai-summary:start/end -->` — update if purpose, tech stack, or runtime changes
- `<!-- ai-loopup-dependencies:start/end -->` — update when LoopUp service dependencies change
- `<!-- ai-inputs-outputs:start/end -->` — update when the API surface changes
