# GoPlanner ✈️🧠

An AI-powered smart itinerary planner that helps users optimize their travel plans based on preferences, real-time weather, and ongoing events.

## 🚀 Features

- AI-generated personalized trip itineraries
- Real-time optimization using live weather and local events
- Seamless multi-platform experience via Flutter app
- Scalable backend infrastructure with message queues

## 🛠️ Tech Stack

- **Frontend**: Flutter
- **Backend**: Go (Golang)
- **AI**: Gemini LLM
- **State & Queue Management**:
  - Redis (for caching and fast state storage)
  - RabbitMQ (for message queuing and task delegation)

## 💡 How It Works

1. User inputs preferences (e.g., interests, travel dates, destination).
2. Gemini LLM generates a rough itinerary.
3. Live data (weather, events) is fetched and used to optimize the plan.
4. Backend services coordinate tasks through RabbitMQ.
5. Redis caches and manages state efficiently.