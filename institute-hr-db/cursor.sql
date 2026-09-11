-- Курсор для расчета статистики по отделам
CREATE PROCEDURE sp_calculate_department_stats_cursor
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @department_id INT;
    DECLARE @department_name NVARCHAR(100);
    DECLARE @employee_count INT;
    DECLARE @avg_salary DECIMAL(10,2);
    DECLARE @total_salary DECIMAL(10,2);
    
    -- Создаем временную таблицу для результатов
    CREATE TABLE #department_stats (
        department_id INT,
        department_name NVARCHAR(100),
        employee_count INT,
        avg_salary DECIMAL(10,2),
        total_salary DECIMAL(10,2)
    );
    
    -- Объявляем курсор
    DECLARE department_cursor CURSOR FOR
    SELECT d.department_id, d.name
    FROM departments d
    WHERE d.parent_department_id IS NOT NULL
    ORDER BY d.name;
    
    OPEN department_cursor;
    FETCH NEXT FROM department_cursor INTO @department_id, @department_name;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Рассчитываем статистику для текущего отдела
        SELECT 
            @employee_count = COUNT(DISTINCT e.employee_id),
            @avg_salary = AVG(sp.base_salary),
            @total_salary = SUM(sp.base_salary)
        FROM employees e
        JOIN appointments a ON e.employee_id = a.employee_id 
            AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
        JOIN staff_positions sp ON a.staff_position_id = sp.position_id
        WHERE sp.department_id = @department_id
            AND e.dismissal_date IS NULL;
        
        -- Вставляем результат
        INSERT INTO #department_stats 
        VALUES (@department_id, @department_name, 
                ISNULL(@employee_count, 0), 
                ISNULL(@avg_salary, 0), 
                ISNULL(@total_salary, 0));
        
        FETCH NEXT FROM department_cursor INTO @department_id, @department_name;
    END
    
    CLOSE department_cursor;
    DEALLOCATE department_cursor;
    
    -- Выводим результаты
    SELECT * FROM #department_stats
    ORDER BY total_salary DESC;
    
    -- Очищаем временную таблицу
    DROP TABLE #department_stats;
    
    PRINT 'Статистика по отделам рассчитана с использованием курсора.';
END;
GO