CREATE DATABASE hr_institute;
GO

USE hr_institute;
GO

-- 1. Таблица сотрудников 
CREATE TABLE employees (
    employee_id INT PRIMARY KEY IDENTITY(1,1),
    last_name NVARCHAR(50) NOT NULL,
    first_name NVARCHAR(50) NOT NULL,
    middle_name NVARCHAR(50),
    birth_date DATE NOT NULL,
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    inn NVARCHAR(12),
    snils NVARCHAR(14),
    address NVARCHAR(200),
    phone NVARCHAR(20),
    email NVARCHAR(100),
    hire_date DATE NOT NULL,
    dismissal_date DATE,
    CONSTRAINT CHK_dates CHECK (hire_date <= ISNULL(dismissal_date, GETDATE()))
);
GO

-- 2. Паспортные данные
CREATE TABLE passport_data (
    passport_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL UNIQUE,
    passport_series NVARCHAR(4),
    passport_number NVARCHAR(6),
    issue_date DATE,
    issue_authority NVARCHAR(200),
    CONSTRAINT FK_passport_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 3. Причины увольнения (справочник)
CREATE TABLE dismissal_reasons (
    reason_id INT PRIMARY KEY IDENTITY(1,1),
    reason_code NVARCHAR(10) NOT NULL UNIQUE,
    reason_name NVARCHAR(100) NOT NULL,
    description NVARCHAR(300)
);
GO

-- 4. Факты увольнения
CREATE TABLE dismissals (
    dismissal_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    dismissal_date DATE NOT NULL,
    reason_id INT,
    order_number NVARCHAR(20),
    order_date DATE,
    notes NVARCHAR(500),
    CONSTRAINT FK_dismissals_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id),
    CONSTRAINT FK_dismissals_reason FOREIGN KEY (reason_id) 
        REFERENCES dismissal_reasons(reason_id)
);
GO

-- 5. Таблица структурных подразделений 
CREATE TABLE departments (
    department_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(10) NOT NULL UNIQUE,
    name NVARCHAR(100) NOT NULL,
    department_type NVARCHAR(20) CHECK (department_type IN ('administration', 'academic', 'technical')),
    parent_department_id INT,
    head_employee_id INT,
    establishment_date DATE,
    CONSTRAINT FK_departments_parent FOREIGN KEY (parent_department_id) 
        REFERENCES departments(department_id),
    CONSTRAINT FK_departments_head FOREIGN KEY (head_employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 6. Таблица штатных единиц 
CREATE TABLE staff_positions (
    position_id INT PRIMARY KEY IDENTITY(1,1),
    department_id INT NOT NULL,
    position_name NVARCHAR(100) NOT NULL,
    position_category NVARCHAR(50) CHECK (position_category IN ('faculty', 'administration', 'technical')),
    salary_grade INT,
    base_salary DECIMAL(10,2),
    rate_count DECIMAL(3,2) DEFAULT 1.00,
    vacancies_count INT DEFAULT 1,
    establishment_date DATE,
    CONSTRAINT FK_staff_positions_department FOREIGN KEY (department_id) 
        REFERENCES departments(department_id)
);
GO

-- 7. Таблица назначений 
CREATE TABLE appointments (
    appointment_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    staff_position_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    dismissal_date DATE,
    appointment_type NVARCHAR(20) CHECK (appointment_type IN ('primary', 'secondary', 'temporary')),
    appointment_rate DECIMAL(3,2) DEFAULT 1.00,
    order_id INT, -- Ссылка на приказ
    CONSTRAINT FK_appointments_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id),
    CONSTRAINT FK_appointments_position FOREIGN KEY (staff_position_id) 
        REFERENCES staff_positions(position_id),
    CONSTRAINT UQ_active_appointment UNIQUE (employee_id, appointment_type, dismissal_date)
);
GO

-- 8. Приказы 
CREATE TABLE orders (
    order_id INT PRIMARY KEY IDENTITY(1,1),
    order_number NVARCHAR(20) NOT NULL UNIQUE,
    order_date DATE NOT NULL,
    order_type NVARCHAR(30) CHECK (order_type IN ('appointment', 'dismissal', 'leave', 'transfer')),
    issued_by NVARCHAR(100),
    notes NVARCHAR(500)
);
GO

-- 9. Таблица образования 
CREATE TABLE education (
    education_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    education_level NVARCHAR(50) CHECK (education_level IN ('secondary', 'special', 'bachelor', 'master', 'phd', 'doctor')),
    institution_id INT, -- Ссылка на справочник учреждений
    diploma_number NVARCHAR(20) NOT NULL UNIQUE,
    graduation_year INT,
    specialty_id INT, -- Ссылка на справочник специальностей
    CONSTRAINT FK_education_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 10. Учебные заведения
CREATE TABLE educational_institutions (
    institution_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(200) NOT NULL,
    type NVARCHAR(50),
    city NVARCHAR(50),
    country NVARCHAR(50)
);
GO

-- 11. Специальности
CREATE TABLE specialties (
    specialty_id INT PRIMARY KEY IDENTITY(1,1),
    code NVARCHAR(20) NOT NULL UNIQUE,
    name NVARCHAR(150) NOT NULL,
    field NVARCHAR(100)
);
GO

-- 12. Таблица ученых степеней и званий 
CREATE TABLE academic_titles (
    title_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    title_type NVARCHAR(30) CHECK (title_type IN ('degree', 'rank')),
    title_name NVARCHAR(100) NOT NULL,
    specialty_code NVARCHAR(20),
    dissertation_topic NVARCHAR(300),
    defense_date DATE,
    diploma_number NVARCHAR(20),
    CONSTRAINT FK_academic_titles_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 13. Таблица повышения квалификации 
CREATE TABLE professional_development (
    development_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    program_name NVARCHAR(200) NOT NULL,
    institution_name NVARCHAR(200),
    start_date DATE,
    end_date DATE,
    hours_count INT,
    certificate_number NVARCHAR(30),
    CONSTRAINT FK_development_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 14. Таблица отпусков 
CREATE TABLE leaves (
    leave_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    leave_type NVARCHAR(30) CHECK (leave_type IN ('annual', 'childcare', 'sick', 'administrative', 'study')),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    order_id INT, -- Ссылка на приказ
    notes NVARCHAR(300),
    CONSTRAINT FK_leaves_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id),
    CONSTRAINT FK_leaves_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id),
    CONSTRAINT CHK_leave_dates CHECK (start_date <= end_date)
);
GO

-- 15. Таблица семейного положения 
CREATE TABLE family_status (
    family_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL UNIQUE,
    marital_status NVARCHAR(20) CHECK (marital_status IN ('single', 'married', 'divorced', 'widowed')),
    spouse_name NVARCHAR(100),
    marriage_date DATE,
    divorce_date DATE,
   
    CONSTRAINT FK_family_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id),
    CONSTRAINT CHK_marriage_dates CHECK (marriage_date <= ISNULL(divorce_date, GETDATE()))
);
GO

-- 16. Таблица детей 
CREATE TABLE children (
    child_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    last_name NVARCHAR(50),
    first_name NVARCHAR(50),
    middle_name NVARCHAR(50),
    birth_date DATE NOT NULL,
    birth_certificate NVARCHAR(30),
    CONSTRAINT FK_children_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 17. Таблица воинского учета 
CREATE TABLE military_records (
    record_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL UNIQUE,
    military_status NVARCHAR(30) CHECK (military_status IN ('liable', 'exempt', 'reserve', 'served')),
    rank NVARCHAR(50),
    military_specialty NVARCHAR(100),
    registration_office NVARCHAR(200),
    CONSTRAINT FK_military_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- 18. Таблица наград и поощрений 
CREATE TABLE awards (
    award_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    award_name NVARCHAR(200) NOT NULL,
    awarding_organization NVARCHAR(200),
    award_date DATE,
    award_number NVARCHAR(30),
    CONSTRAINT FK_awards_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id)
);
GO

-- Обновляем внешние ключи 
ALTER TABLE appointments
ADD CONSTRAINT FK_appointments_order FOREIGN KEY (order_id) 
    REFERENCES orders(order_id);
GO

ALTER TABLE education
ADD CONSTRAINT FK_education_institution FOREIGN KEY (institution_id) 
    REFERENCES educational_institutions(institution_id);
GO

ALTER TABLE education
ADD CONSTRAINT FK_education_specialty FOREIGN KEY (specialty_id) 
    REFERENCES specialties(specialty_id);
GO
-- 19. Таблица для истории изменений должностей (для триггеров)
CREATE TABLE position_history (
    history_id INT PRIMARY KEY IDENTITY(1,1),
    employee_id INT NOT NULL,
    old_position_id INT NULL,
    new_position_id INT NOT NULL,
    change_date DATETIME NOT NULL DEFAULT GETDATE(),
    change_type NVARCHAR(20) CHECK (change_type IN ('appointment', 'transfer', 'dismissal')),
    order_id INT NULL,
    CONSTRAINT FK_position_history_employee FOREIGN KEY (employee_id) 
        REFERENCES employees(employee_id),
    CONSTRAINT FK_position_history_old FOREIGN KEY (old_position_id) 
        REFERENCES staff_positions(position_id),
    CONSTRAINT FK_position_history_new FOREIGN KEY (new_position_id) 
        REFERENCES staff_positions(position_id),
    CONSTRAINT FK_position_history_order FOREIGN KEY (order_id) 
        REFERENCES orders(order_id)
);
GO

-- 20. Таблица для аудита (логирования изменений)
CREATE TABLE audit_log (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    table_name NVARCHAR(100) NOT NULL,
    record_id INT NOT NULL,
    operation_type NVARCHAR(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data NVARCHAR(MAX),
    new_data NVARCHAR(MAX),
    changed_by NVARCHAR(100),
    change_date DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-- Создание индексов
CREATE INDEX IX_employees_name ON employees(last_name, first_name, middle_name);
CREATE INDEX IX_employees_birth_date ON employees(birth_date);
CREATE INDEX IX_employees_hire_date ON employees(hire_date);
CREATE INDEX IX_appointments_dates ON appointments(appointment_date, dismissal_date);
CREATE INDEX IX_leaves_dates ON leaves(start_date, end_date);
CREATE INDEX IX_children_employee ON children(employee_id);
GO