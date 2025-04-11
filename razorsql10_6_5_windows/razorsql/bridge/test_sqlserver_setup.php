<html>
<head>
	<title>SQL Server Setup Test</title>
</head>	
<body>

<?php

$submitted = 'no';
$user = '';
$password = '';
$host = '';
$port = '';
$server = '';
$database = '';
$query = 'select GETDATE()';

if ($_POST)
{
	if (isset($_POST['user']))
	{
		$submitted = 'yes';
		$user = $_POST['user'];
		$password = $_POST['password'];
		$host = $_POST['host'];
		$port = $_POST['port'];
		if ($host == null)
		{
			$host = 'localhost';
		}
		if ($port == null)
		{
			$port = '1433';
		}
		$server = $host . ',' . $port;
		$database = $_POST['database'];
	}
}

?>

	<p>
		Enter the parameters below and hit submit. 
	</p>
	<p> 
		An attempt will be made to access the database and display the results of<br>
		the select GETDATE() query.  If results are displayed, RazorSQL will be able <br>
		to communicate with the database via the RazorSQL MS SQL Server PHP Bridge.
	</p>	
		
	<form name="f" method="POST">
		<table>
			<tr>
				<td>User:</td>
				<td><input type="text" name="user" value="<?php echo $user; ?>"></td>
			</tr>
			<tr>
				<td>Password:</td>
				<td><input type="text" name="password" value="<?php echo $password; ?>"></td>
			</tr>
			<tr>
				<td>Host:</td>
				<td><input type="text" name="host" value="<?php echo $host; ?>"></td>
			</tr>
			<tr>
				<td>Port (1433):</td>
				<td><input type="text" name="port" value="<?php echo $port; ?>"></td>
			</tr>
			<tr>
				<td>Database Name:</td>
				<td><input type="text" name="database" value="<?php echo $database; ?>"></td>
			</tr>
			<tr>
				<td colspan="2"><input type="submit" name="submit" value="Submit"></td>
			</tr>
		</table>
	</form>

<?php

if ($submitted == 'yes')
{
	$link = mssql_connect ($server, $user, $password);
	if (!$link)
	{
		die('ERROR: Could not connect: ' . mssql_get_last_message());
	}
	
	if ($database != null)
	{
		$db_selected = mssql_select_db($database, $link);
		if (!$db_selected)
		{
			do_close($link);
			die('ERROR: Could not select database: ' . $database . '. ');
		}
	}
	
	$result = mssql_query($query, $link);
	if (!$result)
	{
		$message = 'Error running query :' . mssql_get_last_message();
		die($message);
	}
	
	while ($row = mssql_fetch_row($result)) 
	{
		$count = count($row);
		$y = 0;
		while ($y < $count)
		{
			echo current($row) . ' ';
			next($row);
			$y = $y + 1;
		}
		echo '<br>';
	}
	mssql_free_result($result);
	do_close($link);
}

function do_close($link)
{
	mssql_close($link);
}
?>

</body>
</html>
