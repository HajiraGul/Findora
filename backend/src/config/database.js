const mongoose = require('mongoose');

// Cache the connection across serverless invocations. On Vercel the module can
// be reused between requests, so we keep a single connection (and a single
// in-flight connect promise) instead of dialing MongoDB on every request.
let cached = global._mongooseCache;
if (!cached) {
  cached = global._mongooseCache = { conn: null, promise: null };
}

async function connectDatabase() {
  if (cached.conn) {
    return cached.conn;
  }

  const mongoUri = process.env.MONGODB_URI;

  if (!mongoUri) {
    throw new Error('MONGODB_URI is not configured');
  }

  if (!cached.promise) {
    mongoose.set('strictQuery', true);

    cached.promise = mongoose
      .connect(mongoUri, {
        serverSelectionTimeoutMS: 8000,
      })
      .then((mongooseInstance) => {
        console.log('MongoDB connected');
        return mongooseInstance;
      });
  }

  try {
    cached.conn = await cached.promise;
  } catch (error) {
    // Reset so the next request can retry instead of reusing a failed promise.
    cached.promise = null;
    throw error;
  }

  return cached.conn;
}

module.exports = connectDatabase;
