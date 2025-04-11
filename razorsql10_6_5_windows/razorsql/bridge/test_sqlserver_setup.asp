<html>
<head>
	<title>SQL Server Setup Test</title>
</head>	
<body>


<%
Response.Buffer = True 
On Error Resume Next
%>

<%
Dim submitted
Dim user
Dim password
Dim host
Dim port
Dim database
Dim query

query = "select GETDATE()"

user = Request.Form("user")

If user <> "" Then
	submitted = "yes"
	user = Request.Form("user")
	password = Request.Form("password")
	host = Request.Form("host")
	port = Request.Form("port")
	database = Request.Form("database")
	If host = "" Then
		host = "locahost"
	End If
	If port = "" Then
		port = "1433"
	End If
End If



if user <> "" Then
	submitted = "yes"
End If
%>

<p>
		Enter the parameters below and hit submit. 
	</p>
	<p> 
		An attempt will be made to access the database and display the results of<br>
		the select GETDATE() query.  If results are displayed, RazorSQL will be able <br>
		to communicate with the database via the RazorSQL MS SQL Server ASP Bridge.
	</p>	
		
	<form name="f" method="POST">
		<table>
			<tr>
				<td>User:</td>
				<td><input type="text" name="user" value="<%=user%>"></td>
			</tr>
			<tr>
				<td>Password:</td>
				<td><input type="text" name="password" value="<%=password%>"></td>
			</tr>
			<tr>
				<td>Host:</td>
				<td><input type="text" name="host" value="<%=host%>"></td>
			</tr>
			<tr>
				<td>Port (1433):</td>
				<td><input type="text" name="port" value="<%=port%>"></td>
			</tr>
			<tr>
				<td>Database Name:</td>
				<td><input type="text" name="database" value="<%=database%>"></td>
			</tr>
			<tr>
				<td colspan="2"><input type="submit" name="submit" value="Submit"></td>
			</tr>
		</table>
	</form>
	
<%
If submitted = "yes" Then
	Dim conn
	Set conn = Server.CreateObject("ADODB.Connection")
	Dim ds
	ds = host & "," & port
	Dim connString
	connString = "Provider=SQLOLEDB;Data Source=" & ds & ";Network Library=DBMSSOCN;Initial Catalog=" & database & ";User Id=" & user & ";Password=" & password & ";"
	conn.Open connString
	
	If conn.Errors.Count > 0 Then
		Response.Write "Unable to Connect" & Err.Description
		Response.END
	End If
	
	Set rs = conn.Execute(query)
	if conn.Errors.Count > 0 Then
		Response.Write "Query Error " & Err.Description
		rs.Close
		conn.Close
		Response.END
	End If
	
	Response.Write(rs(0).Value)
	
	rs.Close
	conn.Close
	Set conn = Nothing
End If
%>
</body>
</html>
