<html>
<head>
	<title>MySQL Setup Test</title>
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
$query = 'show databases';

if ($_POST)
{
	if (isset($_POST['user']))
	{
		$submitted = 'yes';
		$user = $_POST['user'];
		$password = $_POST['password'];
		$host = $_POST['host'];
		$port = $_POST['port'];
		$server = $host . ':' . $port;
		$database = $_POST['database'];
	}
}

?>

	<p>
		Enter the parameters below and hit submit. 
	</p>
	<p> 
		An attempt will be made to access the database and display the results of<br>
		the Show Databases query.  If results are displayed, RazorSQL will be able <br>
		to communicate with the database via the RazorSQL MySQL PHP Bridge.
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
				<td>Host (localhost):</td>
				<td><input type="text" name="host" value="<?php echo $host; ?>"></td>
			</tr>
			<tr>
				<td>Port (3306):</td>
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
	$link = mysql_connect ($server, $user, $password);
	if (!$link)
	{
		die('ERROR: Could not connect: ' . mysql_error());
	}
	
	$db_selected = mysql_select_db($database, $link);
	if (!$db_selected)
	{
		do_close($link);
		die('ERROR: Could not select database: ' . $database . ': error = ' . mysql_error());
	}
	
	$result = mysql_query($query, $link);
	if (!$result)
	{
		$message = 'ERROR: ' . mysql_error();
		die($message);
	}
	
	while ($row = mysql_fetch_row($result)) 
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
	mysql_free_result($result);
	do_close($link);
}

function do_close($link)
{
	mysql_close($link);
}
?>

</body>
</html>
