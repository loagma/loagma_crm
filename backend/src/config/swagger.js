import swaggerJSDoc from "swagger-jsdoc";
import path from "path";
import { fileURLToPath } from "url";

// Resolve the routes path relative to this config file,
// not the process working directory, so swagger-jsdoc
// can always find your annotated route files.
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const options = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "My API Documentation",
      version: "1.0.0",
      description: "API Documentation for my Node.js project",
    },
    servers: [
      {
        url: process.env.API_BASE_URL || "http://localhost:5000",
      },
    ],
  },
  // Point directly at `backend/src/routes/**/*.js`
  apis: [path.join(__dirname, "../routes/**/*.js")],
};

const swaggerSpec = swaggerJSDoc(options);

export default swaggerSpec;
