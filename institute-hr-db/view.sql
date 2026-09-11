-- 1. Представление: Полная информация о сотрудниках
CREATE VIEW v_employee_full_info AS
SELECT 
    e.employee_id,
    e.last_name + ' ' + e.first_name + ' ' + ISNULL(e.middle_name, '') AS full_name,
    e.birth_date,
    DATEDIFF(YEAR, e.birth_date, GETDATE()) AS age,
    e.gender,
    e.phone,
    e.email,
    d.name AS department,
    sp.position_name,
    a.appointment_date,
    a.appointment_rate,
    e.hire_date,
    e.dismissal_date
FROM employees e
LEFT JOIN appointments a ON e.employee_id = a.employee_id 
    AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
LEFT JOIN staff_positions sp ON a.staff_position_id = sp.position_id
LEFT JOIN departments d ON sp.department_id = d.department_id
WHERE e.dismissal_date IS NULL;
GO

-- 2. Представление: Вакантные должности
CREATE VIEW v_vacancies AS
SELECT 
    d.name AS department,
    sp.position_name,
    sp.position_category,
    sp.base_salary,
    sp.vacancies_count - COUNT(a.appointment_id) AS free_positions
FROM staff_positions sp
JOIN departments d ON sp.department_id = d.department_id
LEFT JOIN appointments a ON sp.position_id = a.staff_position_id 
    AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
WHERE sp.vacancies_count > 0
GROUP BY d.name, sp.position_name, sp.position_category, 
         sp.base_salary, sp.vacancies_count
HAVING sp.vacancies_count - COUNT(a.appointment_id) > 0;
GO

-- 3. Представление: Отпуска сотрудников
CREATE VIEW v_current_leaves AS
SELECT 
    e.last_name + ' ' + e.first_name AS employee_name,
    l.leave_type,
    l.start_date,
    l.end_date,
    DATEDIFF(DAY, l.start_date, l.end_date) AS days_count,
    d.name AS department,
    sp.position_name
FROM leaves l
JOIN employees e ON l.employee_id = e.employee_id
LEFT JOIN appointments a ON e.employee_id = a.employee_id 
    AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
LEFT JOIN staff_positions sp ON a.staff_position_id = sp.position_id
LEFT JOIN departments d ON sp.department_id = d.department_id
WHERE GETDATE() BETWEEN l.start_date AND l.end_date
    AND e.dismissal_date IS NULL;
GO

-- 4. Представление: Обновляемое (для выполнения требований по UPDATE/INSERT/DELETE)
CREATE VIEW v_employees_editable AS
SELECT 
    employee_id,
    last_name,
    first_name,
    middle_name,
    birth_date,
    gender,
    phone,
    email,
    hire_date
FROM employees;
GO