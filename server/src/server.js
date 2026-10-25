import app from './app.js';
import { config } from './config.js';

app.listen(config.port, () => {
  console.log(`[Hamari Virasat API] Server listening on http://localhost:${config.port}`);
});
