require('dotenv').config();

const app = require('./app');
const connectDatabase = require('./config/database');

const port = Number(process.env.PORT) || 5000;

async function startServer() {
  await connectDatabase();

  app.listen(port, () => {
    console.log(`Findora API running on port ${port}`);
  });
}

startServer().catch((error) => {
  console.error('Failed to start Findora API:', error.message);
  process.exit(1);
});
