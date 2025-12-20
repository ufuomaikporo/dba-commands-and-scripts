USE DrasInternal

-- Run on master server for link server user 'test'
ALTER ROLE db_datawriter ADD MEMBER [test]
ALTER ROLE db_datareader ADD MEMBER [test]