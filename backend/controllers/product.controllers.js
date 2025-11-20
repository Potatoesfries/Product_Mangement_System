import { getMssqlPool } from "../lib/db.js";
import sql from "mssql";

export const getProducts = async (req, res) => {
    try {
        const pool = await getMssqlPool();

        const result = await pool.request().query('SELECT * FROM Products');

        return res.status(200).json({
            success: true,
            data: result.recordset,
            count: result.recordset.length
        })
    } catch (error) {
        console.error("Error fetching products:", error);
        return res.status(500).json({
            success: false,
            message: "Internal Server Error",
            error: error.message
        });
    }
};

export const getProductById = async (req, res) => {
    try {
        const { id } = req.params;

        if (!id) {
            return res.status(400).json({
                success: false,
                message: "Product ID is required"
            });
        }

        const pool = await getMssqlPool();
        const result = await pool.request()
            .input('id', sql.Int, id)
            .query('SELECT * FROM Products WHERE PRODUCTID = @id');

        if (result.recordset.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Product not found"
            });
        }

        return res.status(200).json({
            success: true,
            data: result.recordset[0]
        });

    } catch (error) {
        console.error("Error fetching product by ID:", error);
        return res.status(500).json({
            success: false,
            message: "Internal Server Error",
            error: error.message
        });
    }
};


export const createProduct = async (req, res) => {
    try {
        const { productname, price, stock } = req.body;

        // Validation for productname
        if (!productname || productname.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Product name is required and cannot be empty'
            });
        }

        // Validation for price
        if (!price || isNaN(price) || parseFloat(price) <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Price must be a positive number'
            });
        }

        // Validation for stock - separated into two checks
        if (stock === undefined || stock === null || stock === '') {
            return res.status(400).json({
                success: false,
                message: 'Stock is required'
            });
        }

        const stockValue = parseInt(stock);
        if (isNaN(stockValue) || stockValue < 0) {
            return res.status(400).json({
                success: false,
                message: 'Stock must be a non-negative number'
            });
        }

        const pool = await getMssqlPool();
        const result = await pool.request()
            .input('productname', sql.NVarChar(100), productname.trim())
            .input('price', sql.Decimal(10, 2), parseFloat(price))
            .input('stock', sql.Int, stockValue)
            .query(`
                INSERT INTO PRODUCTS (PRODUCTNAME, PRICE, STOCK)
                OUTPUT INSERTED.*
                VALUES (@productname, @price, @stock)`);

        return res.status(201).json({
            success: true,
            message: 'Product created successfully',
            data: result.recordset[0]
        });
    } catch (error) {
        console.error('Error creating product:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

export const updateProduct = async (req, res) => {
    try {
        const { id } = req.params;
        const { productname, price, stock } = req.body;

        if (!id) {
            return res.status(400).json({
                success: false,
                message: 'Product ID is required'
            });
        }

        // Validation
        if (!productname || productname.trim() === '') {
            return res.status(400).json({
                success: false,
                message: 'Product name is required and cannot be empty'
            });
        }

        if (!price || isNaN(price) || parseFloat(price) <= 0) {
            return res.status(400).json({
                success: false,
                message: 'Price must be a positive number'
            });
        }

        if (stock === undefined || isNaN(stock) || parseInt(stock) < 0) {
            return res.status(400).json({
                success: false,
                message: 'Stock must be a non-negative number'
            });
        }

        const pool = await getMssqlPool();

        // Check if product exists
        const checkResult = await pool.request()
            .input('id', sql.Int, id)
            .query('SELECT PRODUCTID FROM PRODUCTS WHERE PRODUCTID = @id');

        if (checkResult.recordset.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        // Update product
        const result = await pool.request()
            .input('id', sql.Int, id)
            .input('productname', sql.NVarChar(100), productname.trim())
            .input('price', sql.Decimal(10, 2), parseFloat(price))
            .input('stock', sql.Int, parseInt(stock))
            .query(`
                UPDATE PRODUCTS
                SET PRODUCTNAME = @productname,
                    PRICE = @price,
                    STOCK = @stock
                OUTPUT INSERTED.*
                WHERE PRODUCTID = @id
            `);

        return res.status(200).json({
            success: true,
            message: 'Product updated successfully',
            data: result.recordset[0]
        });

    } catch (error) {
        console.error('Error updating product:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};

export const deleteProduct = async (req, res) => {
    try {
        const { id } = req.params;

        if (!id) {
            return res.status(400).json({
                success: false,
                message: 'Product ID is required'
            });
        }

        const pool = await getMssqlPool();

        // Check if product exists
        const checkResult = await pool.request()
            .input('id', sql.Int, id)
            .query('SELECT * FROM PRODUCTS WHERE PRODUCTID = @id');

        if (checkResult.recordset.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Product not found'
            });
        }

        const deletedProduct = checkResult.recordset[0];

        // Delete product
        await pool.request()
            .input('id', sql.Int, id)
            .query('DELETE FROM PRODUCTS WHERE PRODUCTID = @id');

        return res.status(200).json({
            success: true,
            message: 'Product deleted successfully',
            data: deletedProduct
        });

    } catch (error) {
        console.error('Error deleting product:', error);
        return res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
};