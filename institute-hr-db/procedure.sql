-- 1. Процедура: Назначение сотрудника на должность
CREATE PROCEDURE sp_assign_employee_position
    @employee_id INT,
    @position_id INT,
    @appointment_date DATE,
    @appointment_type NVARCHAR(20),
    @appointment_rate DECIMAL(3,2),
    @order_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Создаем приказ
        DECLARE @order_id INT;
        
        INSERT INTO orders (order_number, order_date, order_type, issued_by)
        VALUES (@order_number, GETDATE(), 'appointment', SYSTEM_USER);
        
        SET @order_id = SCOPE_IDENTITY();
        
        -- Назначаем сотрудника
        INSERT INTO appointments (
            employee_id, 
            staff_position_id, 
            appointment_date, 
            appointment_type, 
            appointment_rate, 
            order_id
        )
        VALUES (
            @employee_id,
            @position_id,
            @appointment_date,
            @appointment_type,
            @appointment_rate,
            @order_id
        );
        
        COMMIT TRANSACTION;
        PRINT 'Сотрудник успешно назначен на должность.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Ошибка: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- 2. Процедура: Увольнение сотрудника
CREATE PROCEDURE sp_dismiss_employee
    @employee_id INT,
    @dismissal_date DATE,
    @reason_id INT,
    @order_number NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Создаем приказ об увольнении
        DECLARE @order_id INT;
        
        INSERT INTO orders (order_number, order_date, order_type, issued_by)
        VALUES (@order_number, GETDATE(), 'dismissal', SYSTEM_USER);
        
        SET @order_id = SCOPE_IDENTITY();
        
        -- Записываем факт увольнения
        INSERT INTO dismissals (employee_id, dismissal_date, reason_id, order_number, order_date)
        VALUES (@employee_id, @dismissal_date, @reason_id, @order_number, @dismissal_date);
        
        -- Обновляем дату увольнения в основной таблице
        UPDATE employees 
        SET dismissal_date = @dismissal_date
        WHERE employee_id = @employee_id;
        
        -- Закрываем все активные назначения
        UPDATE appointments 
        SET dismissal_date = @dismissal_date
        WHERE employee_id = @employee_id 
            AND (dismissal_date IS NULL OR dismissal_date > @dismissal_date);
        
        COMMIT TRANSACTION;
        PRINT 'Сотрудник успешно уволен.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Ошибка: ' + ERROR_MESSAGE();
    END CATCH
END;
GO

-- 3. Процедура: Генерация отчета по отделу
CREATE PROCEDURE sp_generate_department_report
    @department_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        d.name AS department_name,
        COUNT(DISTINCT e.employee_id) AS employee_count,
        COUNT(DISTINCT sp.position_id) AS positions_count,
        SUM(sp.base_salary * a.appointment_rate) AS total_salary_fund,
        AVG(DATEDIFF(YEAR, e.hire_date, GETDATE())) AS avg_experience
    FROM departments d
    LEFT JOIN staff_positions sp ON d.department_id = sp.department_id
    LEFT JOIN appointments a ON sp.position_id = a.staff_position_id 
        AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
    LEFT JOIN employees e ON a.employee_id = e.employee_id 
        AND e.dismissal_date IS NULL
    WHERE d.department_id = @department_id
    GROUP BY d.name;
END;
GO

-- 4. Процедура: Добавление нового сотрудника
CREATE PROCEDURE sp_add_new_employee
    @last_name NVARCHAR(50),
    @first_name NVARCHAR(50),
    @middle_name NVARCHAR(50),
    @birth_date DATE,
    @gender CHAR(1),
    @phone NVARCHAR(20),
    @email NVARCHAR(100),
    @hire_date DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO employees (
            last_name, first_name, middle_name, 
            birth_date, gender, phone, email, hire_date
        )
        VALUES (
            @last_name, @first_name, @middle_name,
            @birth_date, @gender, @phone, @email, @hire_date
        );
        
        DECLARE @new_employee_id INT = SCOPE_IDENTITY();
        
        -- Автоматически создаем запись о семейном положении
        INSERT INTO family_status (employee_id, marital_status)
        VALUES (@new_employee_id, 'single');
        
        COMMIT TRANSACTION;
        
        SELECT @new_employee_id AS new_employee_id;
        PRINT 'Новый сотрудник успешно добавлен. ID: ' + CAST(@new_employee_id AS NVARCHAR(10));
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Ошибка при добавлении сотрудника: ' + ERROR_MESSAGE();
    END CATCH
END;
GO