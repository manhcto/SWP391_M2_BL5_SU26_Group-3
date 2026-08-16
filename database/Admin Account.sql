IF EXISTS (
    SELECT 1 FROM dbo.users
    WHERE LOWER(email) = 'admin@gmail.com'
)
BEGIN
    UPDATE dbo.users
    SET full_name = N'Administrator',
        password_hash = '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C',
        role = 'ADMIN',
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    WHERE LOWER(email) = 'admin@gmail.com';
END
ELSE
BEGIN
    INSERT INTO dbo.users
        (full_name, email, password_hash, role, status)
    VALUES
        (N'Administrator',
         'admin@gmail.com',
         '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C',
         'ADMIN',
         'ACTIVE');
END;

IF EXISTS (
    SELECT 1 FROM dbo.users
    WHERE LOWER(email) = 'mentor@gmail.com'
)
BEGIN
    UPDATE dbo.users
    SET full_name = N'Mentor Demo',
        password_hash = '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C',
        role = 'MENTOR',
        status = 'ACTIVE',
        updated_at = SYSUTCDATETIME()
    WHERE LOWER(email) = 'mentor@gmail.com';
END
ELSE
BEGIN
    INSERT INTO dbo.users
        (full_name, email, password_hash, role, status)
    VALUES
        (N'Mentor Demo',
         'mentor@gmail.com',
         '$2a$10$c4PNSNs0bJn0drrJzAxThu4TBztls3COfVZA.W33b0BL6cquNIS.C',
         'MENTOR',
         'ACTIVE');
END;
