const origin = "http://127.0.0.1:80";
const deadline = Date.now() + 120_000;

while (Date.now() < deadline) {
  try {
    const status = await fetch(`${origin}/status`).then((response) => response.json());

    if (status.isInit) {
      process.exit(0);
    }

    const response = await fetch(`${origin}/init`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        newRoot: { username: "root", password: process.env.ROOT_PASSWORD },
      }),
    });

    if (response.ok) {
      continue;
    }
  } catch {
    // The server is still starting.
  }

  await new Promise((resolve) => setTimeout(resolve, 1000));
}

throw new Error("Audiobookshelf automatic root setup did not complete");
