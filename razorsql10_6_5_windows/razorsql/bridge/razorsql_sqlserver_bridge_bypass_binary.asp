<%
Response.Buffer = True 
On Error Resume Next

Function statementExecuteQuery(conn, query, inFetchSize, tableName, fetchAll, database)
	On Error Resume Next
	Dim retValue : retValue = ""
	query = Replace(query, "<r_newline>", vbNewLine)
	
	Set rs = conn.Execute(query)
	If conn.Errors.Count > 0 Then
		retValue = "|ERROR|" & Err.Description
	Else
		If fetchSize = "" Or fetchSize < 0 Or fetchAll = "true" Then
			fetchSize = 10000000
		End If
	
		Dim i
		Dim fetchSize
		fetchSize = inFetchSize * 1
		Dim columnNames
		Dim values
		
		columnNames = "|COLUMNS|"
		values = "|VALUES|"
		
		For Each objField in rs.Fields
			columnNames = columnNames & objField.Name & "!~!"
		Next
		
		i = 0
		While Not rs.EOF And i < fetchSize
			For Each objField in rs.Fields
				values = values & rs(objField.Name) & "!~!"
				If Err Then
    				values = values & "" & "!~!"
				End If
			Next
			rs.MoveNext
			values = values & "|END_ROW|"
			i = i + 1	
		Wend
		
		retValue = columnNames & values
		
		rs.Close
		
		If tableName <> "" And database <> "" Then
			Dim cQuery
			Dim cColumnNames
			Dim cValues
			cQuery = "select COLUMN_NAME as RAZOR_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH as CHAR_LEN, NUMERIC_PRECISION, NUMERIC_SCALE, IS_NULLABLE from INFORMATION_SCHEMA.COLUMNS where upper (TABLE_CATALOG) = upper('" & database & "') and upper (TABLE_NAME) = upper ('" & tableName & "') order by ORDINAL_POSITION "
			
			cColumnNames = "|SHOW_NAMES|"
			cValues = "|SHOW_VALUES|"
			
			Set rs = conn.Execute(cQuery)
			
			If conn.Errors.Count < 1 Then
				i = 0
				While Not rs.EOF And i < fetchSize
					For Each objField in rs.Fields
						If i = 0 Then
							cColumnNames = cColumnNames & objField.Name & "!~!"
						End If
						cValues = cValues & rs(objField.Name) & "!~!"
					Next
					rs.MoveNext
					cValues = cValues & "|END_ROW|"
					i = i + 1	
				Wend
				retValue = retValue & cColumnNames & cValues
				rs.Close
			End If
		End If
	End If
	statementExecuteQuery = retValue
End Function

Function statementExecuteUpdate(conn, query)
	On Error Resume Next
	Dim retValue : retValue = ""
	query = Replace(query, "<r_newline>", vbNewLine)
	conn.Execute query
	If Err <> 0 Then
		retValue = "|ERROR|" & Err.Description
	Else
		retValue = "|UPDATED_ROWS|-1" 
	End If
	statementExecuteUpdate = retValue
End Function

Function connectionGetMetaData(user)
	Dim retValue
	retValue = "getDatabaseProductName=Microsoft SQL Server!~!getUserName=" & user & "!~!getDriverMajorVersion=1!~!getDriverMinorVersion=0!~!getDriverName=RazorSQL SQL Server ASP Bridge"
	connectionGetMetaData = retValue
End Function

Dim testParameter
testParameter = Request.Form("test")
If testParameter <> "" Then
	Response.Write("true")
	Response.End
End If

Dim checkPassword

'give checkPassword a value if you would like the mysql bridge to require
'a password before continuing.  In the RazorSQL connection wizard,
'enter the password into the service password field.
checkPassword = "radmin"

Dim requestPassword

requestPassword = Request.Form("service_password")
If requestPassword <> checkPassword Then
	Response.Write("|ERROR|Invalid password for RazorSQL SQL Server Bridge")
	Response.End
End If

Dim action
Dim host
Dim port
Dim user
Dim password
Dim database

action = Request.Form("action")
If action = "" Then
	Response.Write("|ERROR|RazorSQL SQL Server Bridge: No action found in request.")
End If

host = Request.Form("host")
port = Request.Form("port")
user = Request.Form("user")
password = Request.Form("password")
database = Request.Form("database")

If host = "" Then
	host = "locahost"
End If
If port = "" Then
	port = "1433"
End If

Dim conn
Set conn = Server.CreateObject("ADODB.Connection")
Dim ds
ds = host & "," & port
Dim connString
connString = "Provider=SQLOLEDB;Data Source=" & ds & ";Network Library=DBMSSOCN;Initial Catalog=" & database & ";User Id=" & user & ";Password=" & password & ";"
conn.Open connString

If conn.Errors.Count > 0 Then
	Response.Write "|ERROR|Unable to Connect" & Err.Description
	Response.END
End If

Dim state
Dim query
If action = "Statement::executeQuery" Then
	Dim tableName
	Dim fetchSize
	Dim fetchAll
	
	query = Request.Form("query")
	tableName = Request.Form("tableName")
	fetchSize = Request.Form("fetchSize")
	fetchAll = Request.Form("fetchAll")
	
	state = statementExecuteQuery(conn, query, fetchSize, tableName, fetchAll, database)
End If

If action = "Statement::executeUpdate" Then
	query = Request.Form("query")
	
	state = statementExecuteUpdate(conn,query)
End If

If action = "Connection::getMetaData" Then
	state = connectionGetMetaData(user)
End If

Response.Write state

conn.Close
Set conn = Nothing
%>