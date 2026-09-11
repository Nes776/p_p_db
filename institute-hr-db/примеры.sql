--EXEC sp_calculate_department_stats_cursor;
/*
SELECT * FROM v_vacancies 
WHERE position_category = 'faculty'
ORDER BY free_positions DESC;

-- Рассчитать подробную статистику по всем отделам
EXEC sp_calculate_department_stats_cursor; - 1 пример из записки 
*/
/*
-- Показать все отпуска за последние 2 года
SELECT * FROM v_current_leaves 
WHERE end_date >= DATEADD(YEAR, -2, GETDATE())
ORDER BY start_date DESC; - 2 пример из записки
*/


/*
-- 1. Добавляем сотрудника
EXEC sp_add_new_employee 
    @last_name = N'Соколов',
    @first_name = N'Александр',
    @middle_name = N'Владимирович',
    @birth_date = '1990-05-15',
    @gender = 'M',
    @phone = '+79991112233',
    @email = 'sokolov@institute.ru',
    @hire_date = '2024-01-15';

-- 2. Получаем ID созданного сотрудника в переменную
DECLARE @EmpId INT;
SELECT @EmpId = employee_id FROM employees WHERE email = 'sokolov@institute.ru';

-- 3. Назначаем на должность (используем переменную)
EXEC sp_assign_employee_position
    @employee_id = @EmpId,
    @position_id = 4,
    @appointment_date = '2024-01-15',
    @appointment_type = 'primary',
    @appointment_rate = 1.00,
    @order_number = N'Приказ-100';

-- 4. Показываем результат
SELECT 
    'Сотрудник успешно добавлен и назначен на должность' AS status,
    @EmpId AS employee_id,
    'Доцент' AS position,
    'Приказ-100' AS order_number; - 3 пример из записки
*/


SELECT 
    e.last_name + ' ' + e.first_name AS employee_name,
    d.name AS department,
    edu.education_level,
    ei.name AS institution,
    at.title_name,
    at.defense_date
FROM employees e
JOIN appointments a ON e.employee_id = a.employee_id 
    AND (a.dismissal_date IS NULL OR a.dismissal_date > GETDATE())
JOIN staff_positions sp ON a.staff_position_id = sp.position_id
JOIN departments d ON sp.department_id = d.department_id
LEFT JOIN education edu ON e.employee_id = edu.employee_id
LEFT JOIN educational_institutions ei ON edu.institution_id = ei.institution_id
LEFT JOIN academic_titles at ON e.employee_id = at.employee_id
WHERE d.department_type = 'academic'
ORDER BY d.name, e.last_name;

-- Получить информацию о детях сотрудников для социальной поддержки
SELECT * FROM fn_get_employee_children(1);

