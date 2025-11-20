import sql from 'mssql';
import dotenv from 'dotenv';

dotenv.config();

const config = {
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    options: {
        encrypt: true,
        trustServerCertificate: true,
        enableArithAbort: true
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

// singleton pool instance
let pool;
export async function getMssqlPool() {
    try {
        if (!pool) {
            pool = sql.connect(config); 
            console.log(" MSSQL Connection Pool established successfully.");
        }
        return pool;
    } catch (error) {
        console.error(" Error establishing MSSQL database connection pool:", error.message);
        throw error; 
    }
}
