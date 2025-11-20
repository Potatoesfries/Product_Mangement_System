import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import { getMssqlPool } from './lib/db.js';
import productRoutes from './routes/product.routes.js';

dotenv.config();

const PORT = process.env.PORT;

const app = express();

app.use(express.json());
app.use(cors());

app.use('/', productRoutes);


// connect to pool first
getMssqlPool().then(() => {
    app.listen(PORT, ()=>{
        console.log(`Server is running on port ${PORT}`);
    })
}).catch(err => {
    console.error("Failed to connect to the database pool:", err);
    process.exit(1); 
});