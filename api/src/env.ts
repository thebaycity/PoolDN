export type Env = {
  Bindings: {
    DB: D1Database;
    JWT_SECRET: string;
    BUCKET: R2Bucket;
  };
  Variables: {
    userId: string;
  };
};
