--day 1 assignment
--1
CREATE VIEW production.unsold_products AS
SELECT 
    p.product_id,
    p.product_name,
    b.brand_name,
    c.category_name,
    p.model_year,
    p.list_price
FROM 
    production.products p
JOIN 
    production.brands b ON p.brand_id = b.brand_id
JOIN 
    production.categories c ON p.category_id = c.category_id
LEFT JOIN 
    sales.order_items oi ON p.product_id = oi.product_id
WHERE 
    oi.product_id IS NULL;

SELECT * FROM production.unsold_products

--2

SELECT 
    category_name,
    product_name,
    list_price
FROM (
    SELECT 
        c.category_name,
        p.product_name,
        p.list_price,
        ROW_NUMBER() OVER (
            PARTITION BY c.category_name 
            ORDER BY p.list_price DESC
        ) AS rank
    FROM 
        production.products p
    JOIN 
        production.categories c ON p.category_id = c.category_id
) ranked_products
WHERE rank = 1;

--3

CREATE VIEW production.product_catalog AS
SELECT 
    p.product_id,
    p.product_name,
    b.brand_name,
    c.category_name,
    p.list_price
FROM 
    production.products p
JOIN 
    production.brands b ON p.brand_id = b.brand_id
JOIN 
    production.categories c ON p.category_id = c.category_id
WHERE 
    p.model_year > 2018;

SELECT * FROM production.product_catalog order by category_name, product_name;




--day 2 assignment

--1

CREATE FUNCTION production.fn_get_list_price (
    @product_id INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @price DECIMAL(10, 2);

    SELECT @price = list_price
    FROM production.products
    WHERE product_id = @product_id;

    RETURN @price;
END;

SELECT production.fn_get_list_price(5) AS price_of_product_5;

--2
CREATE FUNCTION production.fn_get_products_by_category (
    @category_id INT
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.product_id,
        p.product_name,
        p.list_price,
        p.model_year,
        b.brand_name
    FROM 
        production.products p
    JOIN 
        production.brands b ON p.brand_id = b.brand_id
    WHERE 
        p.category_id = @category_id
);

SELECT * FROM production.fn_get_products_by_category(2);

--3

CREATE FUNCTION sales.fn_total_sales_by_store (
    @store_id INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @total_sales DECIMAL(18, 2);

    SELECT @total_sales = SUM(oi.list_price * oi.quantity * (1 - oi.discount))
    FROM sales.orders o
    JOIN sales.order_items oi ON o.order_id = oi.order_id
    WHERE o.store_id = @store_id;

    RETURN ISNULL(@total_sales, 0);
END;

SELECT sales.fn_total_sales_by_store(1) AS total_sales;


--4

CREATE FUNCTION sales.fn_get_orders_between_dates (
    @start_date DATE,
    @end_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        order_id,
        customer_id,
        order_status,
        order_date,
        required_date,
        shipped_date,
        store_id,
        staff_id
    FROM 
        sales.orders
    WHERE 
        order_date BETWEEN @start_date AND @end_date
);
SELECT * FROM sales.fn_get_orders_between_dates('2016-01-01', '2016-12-31');

--5

CREATE FUNCTION production.fn_product_count_by_brand (
    @brand_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;

    SELECT @count = COUNT(*)
    FROM production.products
    WHERE brand_id = @brand_id;

    RETURN @count;
END;

SELECT production.fn_product_count_by_brand(3) AS number_of_products;



-- day 3 assignment
--1
CREATE TABLE production.price_change_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    old_price DECIMAL(10, 2) NOT NULL,
    new_price DECIMAL(10, 2) NOT NULL,
    change_date DATETIME NOT NULL DEFAULT GETDATE()
);

CREATE TRIGGER trg_log_price_change
ON production.products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO production.price_change_log (product_id, old_price, new_price, change_date)
    SELECT 
        d.product_id,
        d.list_price AS old_price,
        i.list_price AS new_price,
        GETDATE()
    FROM 
        deleted d
    JOIN 
        inserted i ON d.product_id = i.product_id
    WHERE 
        d.list_price <> i.list_price;
END;

UPDATE production.products
SET list_price = list_price + 100
WHERE product_id = 1;

--SELECT * FROM production.price_change_log;
--2
CREATE TRIGGER trg_prevent_product_delete_if_open_order
ON production.products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM deleted d
        JOIN sales.order_items oi ON d.product_id = oi.product_id
        JOIN sales.orders o ON oi.order_id = o.order_id
        WHERE o.order_status IN (1, 2)
    )
    BEGIN
        RAISERROR (
            'Cannot delete product(s) because they exist in open orders (Pending or Processing).',
            16,
            1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- If no open order reference exists, allow delete
    DELETE FROM production.products
    WHERE product_id IN (SELECT product_id FROM deleted);
END;

--3

SELECT 
    s.store_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_sales
FROM 
    sales.orders o
JOIN 
    sales.order_items oi ON o.order_id = oi.order_id
JOIN 
    sales.stores s ON o.store_id = s.store_id
GROUP BY 
    s.store_name
HAVING 
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 50000;

--4
SELECT TOP 5 
    p.product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM 
    sales.order_items oi
JOIN 
    production.products p ON oi.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    total_quantity_sold DESC;

--5

SELECT 
    FORMAT(o.order_date, 'yyyy-MM') AS month,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS monthly_sales
FROM 
    sales.orders o
JOIN 
    sales.order_items oi ON o.order_id = oi.order_id
WHERE 
    YEAR(o.order_date) = 2016
GROUP BY 
    FORMAT(o.order_date, 'yyyy-MM')
ORDER BY 
    month;

--6

SELECT 
    s.store_name,
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM 
    sales.orders o
JOIN 
    sales.order_items oi ON o.order_id = oi.order_id
JOIN 
    sales.stores s ON o.store_id = s.store_id
GROUP BY 
    s.store_name
HAVING 
    SUM(oi.quantity * oi.list_price * (1 - oi.discount)) > 100000;
