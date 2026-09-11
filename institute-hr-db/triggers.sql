-- 1. Триггер AFTER INSERT для автоматического создания семейного статуса
CREATE TRIGGER Ы
ON employees
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO family_status (employee_id, marital_status)
    SELECT i.employee_id, 'single'
    FROM inserted i
    LEFT JOIN family_status fs ON i.employee_id = fs.employee_id
    WHERE fs.employee_id IS NULL;
    
    PRINT 'Автоматически создана запись о семейном положении для нового сотрудника.';
END;
GO

-- 2. Триггер INSTEAD OF DELETE для защиты от случайного удаления
CREATE TRIGGER trg_instead_of_employee_delete
ON employees
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @employee_id INT;
    DECLARE @employee_name NVARCHAR(150);
    
    SELECT 
        @employee_id = employee_id,
        @employee_name = last_name + ' ' + first_name
    FROM deleted;
    
    -- Вместо удаления помечаем как уволенного
    UPDATE employees 
    SET dismissal_date = GETDATE()
    WHERE employee_id = @employee_id;
    
    PRINT 'Сотрудник ' + @employee_name + ' помечен как уволенный вместо удаления.';
END;
GO

-- 3. Триггер AFTER UPDATE для логирования изменений зарплаты
CREATE TRIGGER trg_after_salary_update
ON staff_positions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF UPDATE(base_salary)
    BEGIN
        INSERT INTO audit_log (table_name, record_id, operation_type, old_data, new_data, changed_by)
        SELECT 
            'staff_positions',
            i.position_id,
            'UPDATE',
            'Старая зарплата: ' + CAST(d.base_salary AS NVARCHAR(20)),
            'Новая зарплата: ' + CAST(i.base_salary AS NVARCHAR(20)),
            SYSTEM_USER
        FROM inserted i
        JOIN deleted d ON i.position_id = d.position_id
        WHERE i.base_salary != d.base_salary;
        
        PRINT 'Изменения зарплаты залогированы.';
    END
END;
GO

-- 4. Триггер для проверки возраста при приеме на работу
CREATE TRIGGER trg_check_hire_age
ON employees
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @min_age INT = 18;
    DECLARE @max_age INT = 70;
    
    IF EXISTS (
        SELECT 1 FROM inserted 
        WHERE DATEDIFF(YEAR, birth_date, hire_date) < @min_age
           OR DATEDIFF(YEAR, birth_date, hire_date) > @max_age
    )
    BEGIN
        RAISERROR('Возраст сотрудника должен быть от 18 до 70 лет для приема на работу.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Если проверка пройдена, вставляем данные
    INSERT INTO employees (
        last_name, first_name, middle_name, birth_date, gender, 
        phone, email, hire_date, dismissal_date
    )
    SELECT 
        last_name, first_name, middle_name, birth_date, gender,
        phone, email, hire_date, dismissal_date
    FROM inserted;
    
    PRINT 'Данные сотрудника успешно добавлены.';
END;
GO
-- Триггер для обновлямоего представления
CREATE TRIGGER trg_instead_of_v_employees_editable
ON v_employees_editable
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Обработка DELETE
    IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
        DELETE FROM employees
        WHERE employee_id IN (SELECT employee_id FROM deleted);
        PRINT 'Запись удалена через представление.';
    END
    
    -- Обработка UPDATE
    ELSE IF EXISTS (SELECT * FROM deleted) AND EXISTS (SELECT * FROM inserted)
    BEGIN
        UPDATE e
        SET 
            last_name = i.last_name,
            first_name = i.first_name,
            middle_name = i.middle_name,
            birth_date = i.birth_date,
            gender = i.gender,
            phone = i.phone,
            email = i.email,
            hire_date = i.hire_date
        FROM employees e
        JOIN inserted i ON e.employee_id = i.employee_id;
        PRINT 'Запись обновлена через представление.';
    END
    
    -- Обработка INSERT
    ELSE IF NOT EXISTS (SELECT * FROM deleted) AND EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO employees (
            last_name, first_name, middle_name, birth_date, 
            gender, phone, email, hire_date
        )
        SELECT 
            last_name, first_name, middle_name, birth_date,
            gender, phone, email, hire_date
        FROM inserted;
        PRINT 'Новая запись добавлена через представление.';
    END
END;
GO