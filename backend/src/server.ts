import { app } from "./app";
import { env } from "./config/env";

app.listen(env.port, () => {
  console.log(`Yaro0 API running on port ${env.port}`);
});
