-- 1. Скалярная функция: Расчет стажа работы
CREATE FUNCTION fn_calculate_experience (@employee_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @experience INT;
    
    SELECT @experience = DATEDIFF(YEAR, hire_date, ISNULL(dismissal_date, GETDATE()))
    FROM employees
    WHERE employee_id = @employee_id;
    
    RETURN @experience;
END;
GO

-- 2. Табличная функция: Сотрудники отдела
CREATE FUNCTION fn_get_department_employees (@department_id INT)
RETURNS TABLE
AS
RETURN
    SELECT 
        e.employee_id,
        e.last_name + ' ' + e.first_name AS employee_name,
        sp.position_name,
        a.appointment_date
    FROM employees e
    JOIN appointments a ON e.employee_id = a.employee_id 
        AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
    JOIN staff_positions sp ON a.staff_position_id = sp.position_id
    WHERE sp.department_id = @department_id
        AND e.dismissal_date IS NULL;
GO

-- 3. Скалярная функция: Расчет пенсионного возраста
CREATE FUNCTION fn_calculate_pension_age (@gender CHAR(1), @birth_date DATE)
RETURNS DATE
AS
BEGIN
    DECLARE @pension_date DATE;
    
    IF @gender = 'M'
        SET @pension_date = DATEADD(YEAR, 65, @birth_date);
    ELSE
        SET @pension_date = DATEADD(YEAR, 60, @birth_date);
    
    RETURN @pension_date;
END;
GO

-- 4. Табличная функция: Дети сотрудника
CREATE FUNCTION fn_get_employee_children (@employee_id INT)
RETURNS TABLE
AS
RETURN
    SELECT 
        child_id,
        last_name + ' ' + first_name AS child_name,
        birth_date,
        DATEDIFF(YEAR, birth_date, GETDATE()) AS child_age
    FROM children
    WHERE employee_id = @employee_id;
GO