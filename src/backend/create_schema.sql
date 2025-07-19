CREATE TABLE employees (
    employee_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(100),
    department VARCHAR2(100),
    salary NUMBER
);

INSERT INTO employees (name, department, salary) VALUES ('John Doe', 'IT', 75000);
INSERT INTO employees (name, department, salary) VALUES ('Jane Smith', 'HR', 65000);
INSERT INTO employees (name, department, salary) VALUES ('Bob Johnson', 'Finance', 85000);