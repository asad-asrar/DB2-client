<html>
<head>
	<title>PostgreSQL Setup Test</title>
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
$query = 'select CURRENT_TIME';

if ($_POST)
{
	if (isset($_POST['user']))
	{
		$submitted = 'yes';
		$user = $_POST['user'];
		$password = $_POST['password'];
		$host = $_POST['host'];
		$port = $_POST['port'];
		$database = $_POST['database'];
	}
}

?>

	<p>
		Enter the parameters below and hit submit. 
	</p>
	<p> 
		An attempt will be made to access the database and display the results of<br>
		the select CURRENT_TIME query.  If results are displayed, RazorSQL will be able <br>
		to communicate with the database via the RazorSQL PostgreSQL PHP Bridge.
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
				<td>Port (5432):</td>
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
	$connectString = 'host=' . $host . ' port=' .$port;
	if ($database != null)
	{
		$connectString = $connectString . ' dbname=' . $database;
	}
	if ($user != null)
	{
		$connectString = $connectString . ' user=' . $user;
	}
	if ($password != null)
	{
		$connectString = $connectString . ' password=' . $password;
	}

	$link = pg_connect ($connectString);
	if (!$link)
	{
		die('ERROR: Could not connect: ' . pg_last_error());
	}
	
	$result = pg_query($link, $query);
	if (!$result)
	{
		$message = 'ERROR: ' . pg_last_error();
		die($message);
	}
	
	while ($row = pg_fetch_row($result)) 
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
	pg_free_result($result);
	do_close($link);
}

function do_close($link)
{
	pg_close($link);
}
?>

</body>
</html>
