--select * from LD_PipeSeamType

SELECT 
    dtl.resource_type,
    OBJECT_NAME(dtl.resource_associated_entity_id, dtl.resource_database_id) AS locked_table,
    dtl.request_mode,
    dtl.request_status,
    dtl.request_session_id,
    s.login_name,
    s.host_name,
    r.blocking_session_id,
    r.status AS request_status,
    r.command,
    t.text AS sql_text
FROM sys.dm_tran_locks dtl
JOIN sys.dm_exec_sessions s ON dtl.request_session_id = s.session_id
JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id IS NOT NULL
  AND dtl.resource_type = 'OBJECT'
ORDER BY dtl.request_session_id;

SELECT DB_NAME(dt.resource_database_id) AS database_name,
    OBJECT_NAME(dt.resource_associated_entity_id, dt.resource_database_id) AS table_name,
    at.transaction_id,
    at.name AS transaction_name,
    at.transaction_begin_time,
    at.transaction_state,
    at.transaction_status,
    s.session_id,
    s.login_name,
    r.status AS request_status,
    r.command,
    t.text AS sql_statement
FROM sys.dm_tran_active_transactions at
JOIN sys.dm_tran_session_transactions st ON at.transaction_id = st.transaction_id
JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
LEFT JOIN sys.dm_tran_locks dt ON st.session_id = dt.request_session_id AND dt.resource_type = 'OBJECT'
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE at.transaction_state <> 4 -- 4 = Committed



-- Find current locks and potential deadlocks in SQL Server

DROP TABLE IF EXISTS ##TempTable
SELECT
    l.resource_type,
    DB_NAME(l.resource_database_id) AS database_name,
    OBJECT_NAME(l.resource_associated_entity_id, l.resource_database_id) AS table_name,
    l.request_mode,
    l.request_status AS trans_request_status,
    l.request_session_id,
    s.login_name,
    s.host_name,
    r.blocking_session_id,
    r.status AS dm_request_status,
    r.command,
    t.text AS sql_text
--INTO ##TempTable
FROM sys.dm_tran_locks l
JOIN sys.dm_exec_sessions s ON l.request_session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
LEFT JOIN sys.sysprocesses sp ON l.request_session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) t
WHERE l.resource_type = 'OBJECT'  
ORDER BY l.request_session_id, l.resource_type;

--select * from ##TempTable

-- To find actual deadlocks, check the SQL Server error log or use Extended Events.
-- The above query shows blocking sessions, which may indicate deadlock situations.

DECLARE @tblVariable TABLE(SPID INT, Status VARCHAR(200), [Login] VARCHAR(200), HostName VARCHAR(200), 
    BlkBy VARCHAR(200), DBName VARCHAR(200), Command VARCHAR(200), CPUTime INT, 
    DiskIO INT, LastBatch VARCHAR(200), ProgramName VARCHAR(200), _SPID INT, 
    RequestID INT)

INSERT INTO @tblVariable
EXEC Master.dbo.sp_who2

SELECT v.SPID, v.Status, v.Login, v.HostName, v.BlkBy, v.DBName, 
v.LastBatch, v.ProgramName, v.Command, v.CPUTime, v.DiskIO, v.RequestID
, t.TEXT 
FROM @tblVariable v
INNER JOIN sys.sysprocesses sp ON sp.spid = v.SPID
CROSS APPLY sys.dm_exec_sql_text(sp.sql_handle) AS t
--WHERE v.spId IN (SELECT request_session_id FROM ##TempTable)
ORDER BY BlkBy DESC, CPUTime DESC



