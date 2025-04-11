<?php
	if ($_POST || $_GET)
	{
		$testParameter = '';
		if (isset($_POST['test']))
		{
			$testParameter = $_POST['test'];
		}
		else if (isset($_GET['test']))
		{
			$testParameter = $_GET['test'];
		}
		
		if ($testParameter == 'true')
		{
			if (extension_loaded('pgsql'))
			{
				echo 'true';
			}	
			else
			{
				echo 'false';
			}
			return;
		}
	}
		
	if ($_POST)
	{	
		//give $checkPassword a value if you would like the mysql bridge to require
		//a password before continuing.  In the RazorSQL connection wizard,
		//enter the password into the service password field.
		$checkPassword = 'radmin';
		if ($checkPassword != null)
		{
			if (isset($_POST['service_password']))
			{
				$requestPassword = $_POST['service_password'];
				if ($checkPassword != $requestPassword)
				{
					echo '|ERROR|Invalid password for RazorSQL PostgreSQL Bridge';
					return;
				}
			}
			else
			{
				echo '|ERROR|Invalid password for RazorSQL PostgreSQL Bridge';
				return;
			}	
		}
		
		$action = $_POST['action'];
		if ($action == null)
		{
			echo'|ERROR|RazorSQL PostgreSQL Bridge: No action found in request.';
			return;
		}
		
		$host = $_POST['host'];
		$port = $_POST['port'];
		$user = $_POST['user'];
		$password = $_POST['password'];
		$database = $_POST['database'];
		
		if ($host == null)
		{
			$host = 'localhost';
		}
		if ($port == null)
		{
			$port = '5432';
		}
		
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
			die('|ERROR|Could not connect: ' . pg_last_error());
		}
		
		$state = '';
		
		if ($action == 'Statement::executeQuery')
		{
			$query = check_quotes($_POST['query']);
			$tableName = null;
			if (isset($_POST['tableName']))
			{
				$tableName = $_POST['tableName'];
			}
			$fetchSize = $_POST['fetchSize'];
			$fetchAll = $_POST['fetchAll'];
			$state = statementExecuteQuery($query, $fetchSize, $tableName, $fetchAll,
				$database);
		}
		else if ($action == 'Statement::executeUpdate')
		{
			$query = check_quotes($_POST['query']);
			$state = statementExecuteUpdate($query);
		}
		else if ($action == 'Connection::getMetaData')
		{
			$state = connectionGetMetaData($user);
		}
		
		pg_close ($link);
		
		echo $state;
	}
	else
	{
		echo '|ERROR|RazorSQL PostgreSQL Bridge: No valid data found in request.';
		return;
	}	
	
	function connectionGetMetaData($user)
	{
		$state = 'getDatabaseProductName=PostgreSQL!~!getUserName=' . $user .
			'!~!getDriverMajorVersion=1!~!getDriverMinorVersion=0!~!getDriverName=RazorSQL PostgreSQL PHP Bridge';
		return $state;
	}	
	
	function statementExecuteQuery($query, $fetchSize, $tableName, $fetchAll,
		$database)
	{	
		$query = str_replace("<r_newline>", "\n", $query);
		$result = pg_query($query);
		if (!$result) 
		{
			$message = '|ERROR|' . pg_last_error();
			return $message;
		}
		else
		{
			if ($fetchSize == null || $fetchSize < 0 || $fetchAll == 'true')
			{
				//max records to return is 10 million
				$fetchSize = 10000000;
			}
		
			$i = 0;
			$columnNames = '|COLUMNS|';
			$values = '|VALUES|';
			
			$i = 0;
			while ($i < pg_num_fields($result))
			{
				$fieldName = pg_field_name($result, $i);
				$columnNames .= $fieldName . '!~!';
				$i = $i + 1;
			}
			$i = 0;
			
			while ( ($row = pg_fetch_row($result)) && $i < $fetchSize) 
			{
				$count = count($row);
				$y = 0;
				while ($y < $count)
				{
					$c_row = current($row);
					$c_row = str_replace("\n", "<r_newline>", $c_row);
					$values .= $c_row . '!~!';
					next($row);
					$y = $y + 1;
				}
				$values .= '|END_ROW|';
				$i = $i + 1;
			}
			pg_free_result($result);
		}
		
		$retValue = $columnNames . $values;
		
		if ($tableName != null && $database != null)
		{
			$cQuery = "select column_name as RAZOR_NAME, udt_name, character_maximum_length, numeric_precision, numeric_scale, is_nullable from information_schema.columns where upper (TABLE_CATALOG) = upper('" . $database . "') and upper (TABLE_NAME) = upper ('" . $tableName . "') order by ORDINAL_POSITION ";
			$result = pg_query($cQuery);
			if ($result)
			{
				$columnNames = '|SHOW_NAMES|';
				$values = '|SHOW_VALUES|';
				
				$i = 0;
				while ($i < pg_num_fields($result))
				{
					$fieldName = pg_field_name($result, $i);
					$columnNames .= $fieldName . '!~!';
					$i = $i + 1;
				}
				
				$i = 0;
				while ( ($row = pg_fetch_row($result)) && $i < $fetchSize) 
				{
					$count = count($row);
					$y = 0;
					while ($y < $count)
					{
						$values .= current($row) . '!~!';
						next($row);
						$y = $y + 1;
					}
					$values .= '|END_ROW|';
					$i = $i + 1;
				}
				$retValue .= $columnNames . $values;
				pg_free_result($result);
			}
		}
		return ($retValue);
	}
	
	function statementExecuteUpdate ($query)
	{
		$query = str_replace("<r_newline>", "\n", $query);
		$result = pg_query($query);
		if (!$result) 
		{
			$message = '|ERROR|' . pg_last_error();
			return $message;
		}
		
		$message = '|UPDATED_ROWS|-1';
		return $message;
	}
	
	function check_quotes($value)
	{
		if (get_magic_quotes_gpc()) 
		{
			$value = stripslashes($value);
		}
		return $value;
	}
?>