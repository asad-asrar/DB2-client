<%@ page import="java.sql.*" %>
<%@ page import="java.util.*"%>
<%@ page import="java.net.*"%>
<%@ page import="java.io.*"%>
<%@ page import="java.util.zip.*"%>
<%@ page import="java.lang.reflect.*"%>
<%@ page import="sun.misc.*"%>

<%! String idString = "RazorSQL JDBC Bridge"; %>

<%
	String testParameter = request.getParameter("test");
	if (testParameter != null && testParameter.equals("true"))
	{
		out.println("true");
		return;
	}


	//Add a password value here to force users to pass a correct password to use the service.
	//In the RazorSQL connection wizard, enter the same password in the service password field.
	String checkPassword = "radmin";
	
	String requestPassword = getRequestParameter("service_password", request);
	if (checkPassword != null)
	{
		if (!checkPassword.equals(requestPassword))
		{
			SQLException se = new SQLException(idString+": Invalid password.");
			writeOutput(se, response);
			return;
		}
	}


	String connectionType = request.getParameter("connection_type");
	String action = request.getParameter("action");
	Connection con = null;
	if (connectionType == null || action == null)
	{
		SQLException se = null;
		if (connectionType == null)
		{
			se = new SQLException(idString+": No connection_type found in request.");
		}
		else if (action == null)
		{
			se = new SQLException(idString+": No action found in request.");
		}
		writeOutput(se, response);
		return;
	}	
	
	connectionType = getRequestParameter("connection_type", request);
	action = getRequestParameter("action", request);
	
	if (connectionType.equals("driver_manager"))
	{
		String user = getRequestParameter("login_id", request);
		String password = getRequestParameter("password", request);
		String driverClass = getRequestParameter("driver_class", request);
		String jdbcUrl = getRequestParameter("jdbc_url", request);
		
		try
		{
			Class dbDriver = Class.forName(driverClass);
			if (dbDriver != null)
			{
				Driver db = (Driver)dbDriver.newInstance();
			}
			
			if ( (user != null && user.trim().length() > 0) && (password != null && password.trim().length() > 0) )
			{
				con = DriverManager.getConnection(jdbcUrl, user, password);
			}
			else if (user != null && user.trim().length() > 0)
			{
				con = DriverManager.getConnection(jdbcUrl, user, password);
			}
			else
			{
				con = DriverManager.getConnection(jdbcUrl);
			}
		}
		catch (Exception ex)
		{
			writeOutput(new SQLException(ex.toString()), response);
		}
	}
	else if (connectionType.equals("interface"))
	{
		String driverClass = getRequestParameter("driver_class", request);
		String driverMethod = getRequestParameter("driver_method", request);
		
		try
		{
			Class iClass = Class.forName(driverClass);
			Object iObj = iClass.newInstance();
			Class[] params = new Class[0];
			Method method = iClass.getMethod(driverMethod, params);
			Object[] paramValues = new Object[0];
			Object ret = method.invoke(iObj, paramValues);
			
			if (ret == null)
			{
				throw new SQLException("Null object returned from: "+driverMethod+" call.");
			}
			else if (ret instanceof java.sql.Connection)
			{
				con = (Connection)ret;
			}
			else 
			{
				throw new SQLException("Invalid object returned from: " +driverMethod+" call.");
			}
		}
		catch (Exception ex)
		{
			writeOutput(new SQLException(ex.toString()), response);
		}	
	}
	
	if (con == null)
	{
		SQLException se = new SQLException(idString+": Unable to obtain connection.");
		writeOutput(se, response);
		return;
	}
	
	String exceptionMessage = null;
	try
	{
		String state = null;
		if (action.equals("Statement::executeQuery"))
		{
			String query = getRequestParameter("query", request);
			String fetchSize = getRequestParameter("fetchSize", request);
			String fetchAll = getRequestParameter("fetchAll", request);
			state = statementExecuteQuery(con, query, fetchSize, fetchAll);
		}
		else if (action.equals("Statement::executeUpdate"))
		{
			String query = getRequestParameter("query", request);
			state = statementExecuteUpdate(con, query);
		}
		else if (action.equals("Statement::executeBatch"))
		{
			String queries = getRequestParameter("query", request);
			state = statementExecuteBatch(con, queries);
		}
		else if (action.equals("Statement::execute"))
		{
			String query = getRequestParameter("query", request);
			String fetchSize = getRequestParameter("fetchSize", request);
			String fetchAll = getRequestParameter("fetchAll", request);
			state = statementExecute(con, query, fetchSize, fetchAll);
		}
		else if (action.equals("Connection::getMetaData"))
		{
			state = connectionGetMetaData(con);
		}
		else if (action.equals("DatabaseMetaData::getCatalogs"))
		{
			state = databaseMetaDataGetCatalogs(con);
		}
		else if (action.equals("DatabaseMetaData::getSchemas"))
		{
			state = databaseMetaDataGetSchemas(con);
		}
		else if (action.equals("DatabaseMetaData::getTables"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			state = databaseMetaDataGetTables(con, cat, schema);
		}
		else if (action.equals("DatabaseMetaData::getTableTypes"))
		{
			state = databaseMetaDataGetTableTypes(con);
		}
		else if (action.equals("DatabaseMetaData::getTypeInfo"))
		{
			state = databaseMetaDataGetTypeInfo(con);
		}
		else if (action.equals("DatabaseMetaData::getProcedures"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			state = databaseMetaDataGetProcedures(con, cat, schema);
		}	
		else if (action.equals("DatabaseMetaData::getProcedureColumns"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			String procedureName = getRequestParameter("procedureName", request);
			state = databaseMetaDataGetProcedureColumns(con, cat, schema, procedureName);
		}	
		else if (action.equals("DatabaseMetaData::getColumns"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			String tableName = getRequestParameter("tableName", request);
			state = databaseMetaDataGetColumns(con, cat, schema, tableName);
		}
		else if (action.equals("DatabaseMetaData::getPrimaryKeys"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			String tableName = getRequestParameter("tableName", request);
			state = databaseMetaDataGetPrimaryKeys(con, cat, schema, tableName);
		}
		else if (action.equals("DatabaseMetaData::getImportedKeys"))
		{
			String cat = getRequestParameter("catalog", request);
			String schema = getRequestParameter("schema", request);
			String tableName = getRequestParameter("tableName", request);
			state = databaseMetaDataGetImportedKeys(con, cat, schema, tableName);
		}
		else
		{
			SQLException se = new SQLException(idString+": No valid action in request.");
			writeOutput(se, response);
		}
		
		if (state != null)
		{
			writeOutputNoDescribe(state, response);
		}
		
	}	
	catch (Exception ex)
	{
		exceptionMessage = idString + ": "+ex.toString();
	}
	finally
	{
		String errorMessage = null;
		try
		{
			if (con.getAutoCommit() == false)
			{
				con.commit();
			}
		}
		catch (Exception ex)
		{
			errorMessage = idString + ": " +ex.toString();
		}
		try
		{
			con.close();
		}
		catch (Exception ex)
		{}
		
		if (exceptionMessage != null)
		{
			writeOutput(new SQLException(exceptionMessage), response);
		}
		else if (errorMessage != null)
		{
			writeOutput(new SQLException(errorMessage), response);
		}
	}
	
%>

<%!
	String getRequestParameter(String name, HttpServletRequest req) throws Exception
	{
		String value = req.getParameter(name);
		/*try
		{
			value = URLDecoder.decode(value, "UTF-8");	
		}
		catch (Exception ex)
		{}*/
		if (value != null)
		{
			if (value.equals("null"))
			{
				value = null;
			}
		}
		return value;
	}

	void writeOutputNoDescribe (Object obj, HttpServletResponse r) throws Exception
	{
		PrintWriter writer = r.getWriter();
		writer.println(obj);
		writer.flush();
		writer.close();
	}
	
	void writeOutput (Object obj, HttpServletResponse r) throws Exception
	{
		String state = describeState(obj);
		PrintWriter writer = r.getWriter();
		writer.println(state);
		writer.flush();
		writer.close();
	}
	
	ArrayList populateNameValueList(ResultSet rs, int[] numbers, String[] names) throws Exception
	{
		ArrayList nvList = new ArrayList();
		while (rs.next())
		{
			ArrayList currentList = new ArrayList();
			for (int i = 0; i < names.length; i++)
			{
				ArrayList nv = new ArrayList();
				int check = i+1;
				boolean containsNum = false;
				for (int x = 0; x < numbers.length; x++)
				{
					if (numbers[x] == check)
					{
						containsNum = true;
						break;
					}
				}
				if (containsNum)
				{
					nv.add(names[i]);
					String data = "";
					try{data = rs.getString(numbers[i]);}catch (Exception ex){}
					nv.add(data);
				}
				else
				{
					nv.add("");
					nv.add("");
				}
				currentList.add(nv);
			}
			nvList.add(currentList);
		}
		return nvList;
	}
	
	String databaseMetaDataGetCatalogs(Connection con) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getCatalogs();
			
			int[] numbers = {1};
			String[] names = {"TABLE_CAT"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception ex){}}
		}
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetTableTypes(Connection con) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getTableTypes();
			
			int[] numbers = {1};
			String[] names = {"TABLE_TYPE"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception ex){}}
		}
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetTypeInfo(Connection con) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getTypeInfo();
			
			int[] numbers = {1,2,3,4,5};
			String[] names = {"TYPE_NAME", "DATA_TYPE", "PRECISION", "LITERAL_PREFIX", "LITERAL_SUFFIX"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception ex){}}
		}
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
		
	String databaseMetaDataGetProcedures (Connection con, String cat, String schema) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getProcedures(cat, schema, null);
			
			int[] numbers = {1,2,3};
			String[] names = {"PROCEDURE_CAT", "PROCEDURE_SCHEM", "PROCEDURE_NAME"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetProcedureColumns (Connection con, String cat, String schema,
		String procedureName) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getProcedureColumns(cat, schema, procedureName, null);
			
			int[] numbers = {1,2,3,4,5,6,7,8,9,10,11,12};
			String[] names = {"PROCEDURE_CAT","PROCEDURE_SCHEM","PROCEDURE_NAME",
				"COLUMN_NAME","COLUMN_TYPE","DATA_TYPE","TYPE_NAME",
				"PRECISION","LENGTH","SCALE","RADIX","NULLABLE","REMARKS"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetColumns (Connection con, String cat, String schema,
		String tableName) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getColumns(cat, schema, tableName, null);
			
			int[] numbers = {1,2,3,4,5,6,7,11,18};
			String[] names = {"TABLE_CAT","TABLE_SCHEM","TABLE_NAME","COLUMN_NAME","DATA_TYPE",
				"TYPE_NAME","COLUMN_SIZE","NULLABLE","IS_NULLABLE"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetPrimaryKeys (Connection con, String cat, String schema,
		String tableName) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getPrimaryKeys(cat, schema, tableName);
			
			int[] numbers = {1,2,3,4,5,6};
			String[] names = {"TABLE_CAT","TABLE_SCHEM","TABLE_NAME","COLUMN_NAME","KEY_SEQ","PK_NAME"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetImportedKeys (Connection con, String cat, String schema,
		String tableName) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getImportedKeys(cat, schema, tableName);
			
			int[] numbers = {1,2,3,4,5,6,7,8,9,12,13};
			String[] names = {"PKTABLE_CAT","PKTABLE_SCHEM","PKTABLE_NAME","PKCOLUMN_NAME","FKTABLE_CAT",
				"FKTABLE_SCHEM","FKTABLE_NAME","FKCOLUMN_NAME","KEY_SEQ","FK_NAME","PK_NAME"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetTables (Connection con, String cat, String schema) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getTables(cat, schema, null, null);
			
			int[] numbers = {1,2,3,4};
			String[] names = {"TABLE_CAT","TABLE_SCHEM","TABLE_NAME","TABLE_TYPE"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}
	
	String databaseMetaDataGetSchemas(Connection con) throws Exception
	{
		ResultSet rs = null;
		ArrayList nvList = new ArrayList();
		
		try
		{
			DatabaseMetaData metaData = con.getMetaData();
			rs = metaData.getSchemas();
			
			int[] numbers = {1,2};
			String[] names = {"TABLE_SCHEM", "TABLE_CATALOG"};
			
			nvList = populateNameValueList(rs, numbers, names);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null){try{rs.close();}catch (Exception e){}}
		}	
		ArrayList resultList = new ArrayList();
		resultList.add(new ArrayList());
		resultList.add(nvList);
		
		String retState = describeState(resultList);
		return retState;
	}

	String connectionGetMetaData (Connection con) throws Exception
	{
		DatabaseMetaData meta = con.getMetaData();
		HashMap map = new HashMap();
		
		try{map.put("getDatabaseProductName", meta.getDatabaseProductName());}catch (Exception ex){} catch (Error e){}
		try{map.put("getDatabaseProductVersion", meta.getDatabaseProductVersion());}catch (Exception ex){} catch (Error e){}
		try{map.put("getDriverName", meta.getDriverName());}catch (Exception ex){} catch (Error e){}
		try{map.put("getDriverVersion", meta.getDriverVersion());}catch (Exception ex){} catch (Error e){}
		try{map.put("getURL", meta.getURL());}catch (Exception ex){} catch (Error e){}
		try{map.put("getUserName", meta.getUserName());}catch (Exception ex){} catch (Error e){}
		try{map.put("getDriverMajorVersion", new Integer(meta.getDriverMajorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getDriverMinorVersion", new Integer(meta.getDriverMinorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getDatabaseMajorVersion", new Integer(meta.getDatabaseMajorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getDatabaseMinorVersion", new Integer(meta.getDatabaseMinorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getJDBCMajorVersion", new Integer(meta.getJDBCMajorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getJDBCMinorVersion", new Integer(meta.getJDBCMinorVersion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getResultSetHoldability", new Integer(meta.getResultSetHoldability()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getSQLStateType", new Integer(meta.getSQLStateType()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxStatementLength", new Integer(meta.getMaxStatementLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxStatements", new Integer(meta.getMaxStatements()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxTableNameLength", new Integer(meta.getMaxTableNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxTablesInSelect", new Integer(meta.getMaxTablesInSelect()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxUserNameLength", new Integer(meta.getMaxUserNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getDefaultTransactionIsolation", new Integer(meta.getDefaultTransactionIsolation()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxBinaryLiteralLength", new Integer(meta.getMaxBinaryLiteralLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxCatalogNameLength", new Integer(meta.getMaxCatalogNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxCharLiteralLength", new Integer(meta.getMaxCharLiteralLength()));}catch (Exception ex){}	 catch (Error e){}
		try{map.put("getMaxColumnNameLength", new Integer(meta.getMaxColumnNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxColumnsInGroupBy", new Integer(meta.getMaxColumnsInGroupBy()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxColumnsInIndex", new Integer(meta.getMaxColumnsInIndex()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxColumnsInOrderBy", new Integer(meta.getMaxColumnsInOrderBy()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxColumnsInSelect", new Integer(meta.getMaxColumnsInSelect()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxColumnsInTable", new Integer(meta.getMaxColumnsInTable()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxConnections", new Integer(meta.getMaxConnections()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxCursorNameLength", new Integer(meta.getMaxCursorNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxIndexLength", new Integer(meta.getMaxIndexLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxProcedureNameLength", new Integer(meta.getMaxProcedureNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxRowSize", new Integer(meta.getMaxRowSize()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getMaxSchemaNameLength", new Integer(meta.getMaxSchemaNameLength()));}catch (Exception ex){} catch (Error e){}
		try{map.put("getSchemaTerm", meta.getSchemaTerm());}catch (Exception ex){} catch (Error e){}
		try{map.put("getProcedureTerm", meta.getProcedureTerm());}catch (Exception ex){} catch (Error e){}
		try{map.put("getCatalogTerm", meta.getCatalogTerm());}catch (Exception ex){} catch (Error e){}
		try{map.put("getCatalogSeparator", meta.getCatalogSeparator());}catch (Exception ex){} catch (Error e){}
		try{map.put("getIdentifierQuoteString", meta.getIdentifierQuoteString());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getSQLKeywords", meta.getSQLKeywords());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getNumericFunctions", meta.getNumericFunctions());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getStringFunctions", meta.getStringFunctions());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getSystemFunctions", meta.getSystemFunctions());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getTimeDateFunctions", meta.getTimeDateFunctions());}catch (Exception ex){}  catch (Error e){}
		try{map.put("getSearchStringEscape", meta.getSearchStringEscape());}catch (Exception ex){} catch (Error e){}
		try{map.put("getExtraNameCharacters", meta.getExtraNameCharacters());}catch (Exception ex){}  catch (Error e){}
		try{map.put("allProceduresAreCallable", new Boolean(meta.allProceduresAreCallable()));}catch (Exception ex){} catch (Error e){}
		try{map.put("allTablesAreSelectable", new Boolean(meta.allTablesAreSelectable()));}catch (Exception ex){} catch (Error e){}
		try{map.put("isReadOnly", new Boolean(meta.isReadOnly()));}catch (Exception ex){} catch (Error e){}
		try{map.put("nullsAreSortedHigh", new Boolean(meta.nullsAreSortedHigh()));}catch (Exception ex){} catch (Error e){}
		try{map.put("nullsAreSortedLow", new Boolean(meta.nullsAreSortedLow()));}catch (Exception ex){} catch (Error e){}
		try{map.put("nullsAreSortedAtStart", new Boolean(meta.nullsAreSortedAtStart()));}catch (Exception ex){} catch (Error e){}
		try{map.put("nullsAreSortedAtEnd", new Boolean(meta.nullsAreSortedAtEnd()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("usesLocalFiles", new Boolean(meta.usesLocalFiles()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("usesLocalFilePerTable", new Boolean(meta.usesLocalFilePerTable()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("supportsMixedCaseIdentifiers", new Boolean(meta.supportsMixedCaseIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesUpperCaseIdentifiers", new Boolean(meta.storesUpperCaseIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesLowerCaseIdentifiers", new Boolean(meta.storesLowerCaseIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesMixedCaseIdentifiers", new Boolean(meta.storesMixedCaseIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("supportsMixedCaseQuotedIdentifiers", new Boolean(meta.supportsMixedCaseQuotedIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesUpperCaseQuotedIdentifiers", new Boolean(meta.storesUpperCaseQuotedIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesLowerCaseQuotedIdentifiers", new Boolean(meta.storesLowerCaseQuotedIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("storesMixedCaseQuotedIdentifiers", new Boolean(meta.storesMixedCaseQuotedIdentifiers()));}catch (Exception ex){}  catch (Error e){}
		try{map.put("supportsAlterTableWithAddColumn", new Boolean(meta.supportsAlterTableWithAddColumn()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsAlterTableWithDropColumn", new Boolean(meta.supportsAlterTableWithDropColumn()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsColumnAliasing", new Boolean(meta.supportsColumnAliasing()));}catch (Exception ex){} catch (Error e){}
		try{map.put("nullPlusNonNullIsNull", new Boolean(meta.nullPlusNonNullIsNull()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsConvert", new Boolean(meta.supportsConvert()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsTableCorrelationNames", new Boolean(meta.supportsTableCorrelationNames()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsDifferentTableCorrelationNames", new Boolean(meta.supportsDifferentTableCorrelationNames()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsExpressionsInOrderBy", new Boolean(meta.supportsExpressionsInOrderBy()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOrderByUnrelated", new Boolean(meta.supportsOrderByUnrelated()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsGroupBy", new Boolean(meta.supportsGroupBy()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsGroupByUnrelated", new Boolean(meta.supportsGroupByUnrelated()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsGroupByBeyondSelect", new Boolean(meta.supportsGroupByBeyondSelect()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsLikeEscapeClause", new Boolean(meta.supportsLikeEscapeClause()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsMultipleResultSets", new Boolean(meta.supportsMultipleResultSets()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsMultipleTransactions", new Boolean(meta.supportsMultipleTransactions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsNonNullableColumns", new Boolean(meta.supportsNonNullableColumns()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsMinimumSQLGrammar", new Boolean(meta.supportsMinimumSQLGrammar()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCoreSQLGrammar", new Boolean(meta.supportsCoreSQLGrammar()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsExtendedSQLGrammar", new Boolean(meta.supportsExtendedSQLGrammar()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsANSI92EntryLevelSQL", new Boolean(meta.supportsANSI92EntryLevelSQL()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsANSI92IntermediateSQL", new Boolean(meta.supportsANSI92IntermediateSQL()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsANSI92FullSQL", new Boolean(meta.supportsANSI92FullSQL()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsIntegrityEnhancementFacility", new Boolean(meta.supportsIntegrityEnhancementFacility()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOuterJoins", new Boolean(meta.supportsOuterJoins()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsFullOuterJoins", new Boolean(meta.supportsFullOuterJoins()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsLimitedOuterJoins", new Boolean(meta.supportsLimitedOuterJoins()));}catch (Exception ex){} catch (Error e){}
		try{map.put("isCatalogAtStart", new Boolean(meta.isCatalogAtStart()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSchemasInDataManipulation", new Boolean(meta.supportsSchemasInDataManipulation()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSchemasInProcedureCalls", new Boolean(meta.supportsSchemasInProcedureCalls()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSchemasInTableDefinitions", new Boolean(meta.supportsSchemasInTableDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSchemasInIndexDefinitions", new Boolean(meta.supportsSchemasInIndexDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSchemasInPrivilegeDefinitions", new Boolean(meta.supportsSchemasInPrivilegeDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCatalogsInDataManipulation", new Boolean(meta.supportsCatalogsInDataManipulation()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCatalogsInProcedureCalls", new Boolean(meta.supportsCatalogsInProcedureCalls()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCatalogsInTableDefinitions", new Boolean(meta.supportsCatalogsInTableDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCatalogsInIndexDefinitions", new Boolean(meta.supportsCatalogsInIndexDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCatalogsInPrivilegeDefinitions", new Boolean(meta.supportsCatalogsInPrivilegeDefinitions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsPositionedDelete", new Boolean(meta.supportsPositionedDelete()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsPositionedUpdate", new Boolean(meta.supportsPositionedUpdate()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSelectForUpdate", new Boolean(meta.supportsSelectForUpdate()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsStoredProcedures", new Boolean(meta.supportsStoredProcedures()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSubqueriesInComparisons", new Boolean(meta.supportsSubqueriesInComparisons()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSubqueriesInExists", new Boolean(meta.supportsSubqueriesInExists()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSubqueriesInIns", new Boolean(meta.supportsSubqueriesInIns()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSubqueriesInQuantifieds", new Boolean(meta.supportsSubqueriesInQuantifieds()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsCorrelatedSubqueries", new Boolean(meta.supportsCorrelatedSubqueries()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsUnion", new Boolean(meta.supportsUnion()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsUnionAll", new Boolean(meta.supportsUnionAll()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOpenCursorsAcrossCommit", new Boolean(meta.supportsOpenCursorsAcrossCommit()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOpenCursorsAcrossRollback", new Boolean(meta.supportsOpenCursorsAcrossRollback()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOpenStatementsAcrossCommit", new Boolean(meta.supportsOpenStatementsAcrossCommit()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsOpenStatementsAcrossRollback", new Boolean(meta.supportsOpenStatementsAcrossRollback()));}catch (Exception ex){} catch (Error e){}
		try{map.put("doesMaxRowSizeIncludeBlobs", new Boolean(meta.doesMaxRowSizeIncludeBlobs()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsTransactions", new Boolean(meta.supportsTransactions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsDataDefinitionAndDataManipulationTransactions", new Boolean(meta.supportsDataDefinitionAndDataManipulationTransactions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsDataManipulationTransactionsOnly", new Boolean(meta.supportsDataManipulationTransactionsOnly()));}catch (Exception ex){} catch (Error e){}
		try{map.put("dataDefinitionCausesTransactionCommit", new Boolean(meta.dataDefinitionCausesTransactionCommit()));}catch (Exception ex){} catch (Error e){}
		try{map.put("dataDefinitionIgnoredInTransactions", new Boolean(meta.dataDefinitionIgnoredInTransactions()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsBatchUpdates", new Boolean(meta.supportsBatchUpdates()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsSavepoints", new Boolean(meta.supportsSavepoints()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsNamedParameters", new Boolean(meta.supportsNamedParameters()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsMultipleOpenResults", new Boolean(meta.supportsMultipleOpenResults()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsGetGeneratedKeys", new Boolean(meta.supportsGetGeneratedKeys()));}catch (Exception ex){} catch (Error e){}
		try{map.put("locatorsUpdateCopy", new Boolean(meta.locatorsUpdateCopy()));}catch (Exception ex){} catch (Error e){}
		try{map.put("supportsStatementPooling", new Boolean(meta.supportsStatementPooling()));}catch (Exception ex){} catch (Error e){}
		
		String state = describeState(map);
		return state;
	}	
	
	String statementExecute(Connection conn, String query,
		String fetchSize, String fetchAll) throws Exception
	{
		Statement stmt = null;
		ResultSet rs = null;
		String retState = "";
		HashMap retMap = new HashMap();
		try
		{
			boolean doFetchAll = false;
			if (fetchAll != null)
			{
				if (fetchAll.equals("true"))
				{
					doFetchAll = true;
				}
			}
			stmt = conn.createStatement();
			boolean result = stmt.execute(query);
			retMap.put("result", new Boolean(result));
			
			if (result)
			{
				rs = stmt.getResultSet();
				
				ArrayList rsmdList = populateResultSetMetaData(rs);
				ArrayList nvList = populateQueryResultSet(rs, fetchSize, doFetchAll);
				
				retMap.put("metaData", rsmdList);
				retMap.put("resultSet", nvList);
			}
			else
			{
				int rowCount = stmt.getUpdateCount();
				retMap.put("rowCount", new Integer(rowCount));
			}
			retState = describeState(retMap);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (stmt != null){ try{stmt.close();}catch (Exception e){}}
		}
		return retState;
	}
	
	String statementExecuteUpdate(Connection conn, String query) throws Exception
	{
		Statement stmt = null;
		String retState = "";
		try
		{
			stmt = conn.createStatement();
			int rows = stmt.executeUpdate(query);
			retState = describeState(String.valueOf(rows));
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (stmt != null){ try{stmt.close();}catch (Exception e){}}
		}
		return retState;
	}

	String statementExecuteBatch (Connection conn, String queries) throws Exception
	{
		Statement stmt = null;
		String retState = null;
		try
		{
			ArrayList queryList = tokenize(queries, "!~!");
			stmt = conn.createStatement();
			for (int i = 0; i < queryList.size(); i++)
			{
				stmt.addBatch( (String)queryList.get(i) );
			}
			int[] vals = stmt.executeBatch();
			retState = describeState(vals);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (stmt != null){ try{stmt.close();}catch (Exception e){}}
		}
		return retState;
	}

	String statementExecuteQuery(Connection conn, String query, 
		String fetchSize, String fetchAll) throws Exception
	{
		Statement stmt = null;
		ResultSet rs = null;
		ArrayList nvList = null;
		ArrayList rsmdList = null;
		String retState = "";
		
		try
		{
			boolean doFetchAll = false;
			if (fetchAll != null)
			{
				if (fetchAll.equals("true"))
				{
					doFetchAll = true;
				}
			}
			stmt = conn.createStatement();
			rs = stmt.executeQuery(query);
			
			rsmdList = populateResultSetMetaData(rs);
			nvList = populateQueryResultSet(rs, fetchSize, doFetchAll);
		}
		catch (Exception ex)
		{
			throw new Exception(ex.toString());
		}
		finally
		{
			if (rs != null) { try{rs.close();}catch (Exception ex){}}
			if (stmt != null){ try{stmt.close();}catch (Exception e){}}
		}
		
		if (nvList == null)
		{
			nvList = new ArrayList();
		}
		if (rsmdList == null)
		{
			rsmdList = new ArrayList();
		}
		
		ArrayList resultList = new ArrayList();
		resultList.add(rsmdList);
		resultList.add(nvList);
		
		retState = describeState(resultList);
		return retState;
	}
	
	ArrayList populateQueryResultSet(ResultSet rs, String fetchSize, boolean fetchAll) throws Exception
	{
		ArrayList nvList = new ArrayList();
		ResultSetMetaData data = rs.getMetaData();
		int colCount = data.getColumnCount();
		
		//max rows to return is 10,000,000
		int max = 10000000;
		if (fetchSize != null && fetchAll == false)
		{
			try
			{
				max = Integer.parseInt(fetchSize);
			}
			catch (Exception ex)
			{}
		}
		
		int rowCount = 0;
		while (rs.next() && rowCount < max)
		{
			ArrayList currentList = new ArrayList();
			int index = 1;
			for (int i = 0; i < colCount; i++)
			{
				String colName = data.getColumnName(index);
				String value = rs.getString(index);
				
				ArrayList nv = new ArrayList();
				nv.add(colName);
				nv.add(value);
				
				currentList.add(nv);
				index++;
			}
			nvList.add(currentList);
			rowCount++;
		}
		return nvList;
	}
	
	ArrayList populateResultSetMetaData(ResultSet rs) throws Exception
	{
		ResultSetMetaData data = rs.getMetaData();
		int colCount = data.getColumnCount();
		ArrayList rsmdList = new ArrayList();
		
		for (int i = 0; i < colCount; i++)
		{
			int index = (i+1);
			HashMap rsmdMap = new HashMap();
			rsmdMap.put("columnCount", new Integer(colCount));
			rsmdMap.put("columnName", data.getColumnName(index));
			rsmdMap.put("columnTypeName", data.getColumnTypeName(index));
			rsmdMap.put("columnType", new Integer(data.getColumnType(index)));
			rsmdMap.put("precision", new Integer(data.getPrecision(index)));
			rsmdMap.put("autoIncrement", new Boolean(data.isAutoIncrement(index)));
			rsmdMap.put("readOnly", new Boolean(data.isReadOnly(index)));
			rsmdMap.put("writable", new Boolean(data.isWritable(index)));
			rsmdMap.put("nullable", new Integer(data.isNullable(index)));
			rsmdMap.put("scale", new Integer(data.getScale(index)));
			rsmdMap.put("columnDisplaySize", new Integer(data.getColumnDisplaySize(index)));
			rsmdMap.put("catalogName", data.getCatalogName(index));
			rsmdMap.put("schemaName", data.getSchemaName(index));
			rsmdMap.put("tableName", data.getTableName(index));
			rsmdList.add(rsmdMap);
		}
		return rsmdList;
	}
	
	String replaceAll(String s, char oldChar, char newChar)
	{
		if (s == null){return s;}
		
		char[] arr = s.toCharArray();
		int len = arr.length;
		for (int i = 0; i < len; i++)
		{
			char c = arr[i];
			if (c == oldChar)
			{
				arr[i] = newChar;	
			}	
		}
		return (String.valueOf(arr));
	}
	
	Object populateFromState (String state) throws Exception
	{
		Object retObject = null;
		//check for space.  space is not valid base64 char.  if sent over
		//request stream, + may be replaced with space
		
		/*int spaceIndex = state.indexOf(" ");
		
		if (spaceIndex > -1)
		{
			state = replaceAll(state, ' ', '+');
		}*/
		
		byte[] b = new BASE64Decoder().decodeBuffer(state);
		b = uncompress(b);	
		
		ObjectInputStream ois = null;
		try
		{
			ByteArrayInputStream bis = new ByteArrayInputStream(b);
			ois = new ObjectInputStream(bis);
			retObject = ois.readObject();
		}
		finally
		{
			try
			{
				ois.close();
			}
			catch (Exception e){}
		}
		return retObject;
	}	
	
	String describeState (Object stateObject) throws Exception
	{
		String state = null;

		ByteArrayOutputStream byteStream = new ByteArrayOutputStream();
		ObjectOutputStream oos = new ObjectOutputStream(byteStream);
		oos.writeObject(stateObject);
		oos.close();
		byte[] bytes = byteStream.toByteArray();
		byte[] cData = compress(bytes);
		
		state = new BASE64Encoder().encode(cData);
		
		return state;	
	}
	
	byte[] compress(byte[] input) throws Exception
	{
		Deflater compressor = new Deflater();
		compressor.setInput(input);
		compressor.finish();

		ByteArrayOutputStream bos = new ByteArrayOutputStream(input.length);
		byte[] buf = new byte[1024 * 100];
		try
		{
			while(!compressor.finished())
			{
				int count = compressor.deflate(buf);
				bos.write(buf, 0, count);
			}
		}
		finally
		{
			try
			{
				bos.close();
			}
			catch(Exception e)
			{}
		}
		byte[] compressedData = bos.toByteArray();
		return compressedData;
	} 
	
	private static byte[] uncompress(byte[] compressedData) throws DataFormatException
	{
		Inflater decompressor = new Inflater();
		decompressor.setInput(compressedData);
		
		ByteArrayOutputStream bos = new ByteArrayOutputStream(compressedData.length);

		byte[] buf = new byte[1024 * 100];
		try
		{
			while(!decompressor.finished())
			{
				int count = decompressor.inflate(buf);
				bos.write(buf, 0, count);
			}
		}
		finally
		{
			try
			{
				bos.close();
			}
			catch(IOException e)
			{
			}
		}
		byte[] decompressedData = bos.toByteArray();
		return decompressedData;
	}
	
	private static ArrayList tokenize(String s, String c)
	{
		int[] allIndexes = allIndexes(s,c,false);
		if (allIndexes == null || allIndexes.length == 0)
		{
			ArrayList r = new ArrayList();
			r.add(s);
			return r;
		}
		ArrayList sList = new ArrayList();
		int start = 0;
		for (int i = 0; i < allIndexes.length; i++)
		{
			boolean added = false;
			if (start >= s.length())
			{
				break;
			}
			int index = allIndexes[i];
			if (index > start)
			{
				String val = s.substring(start, index);
				if (!val.equals(c))
				{
					added = true;
					sList.add(val);
				}
				start = index + c.length();
			}
			else
			{
				start = start + c.length();
			}
			if (i == (allIndexes.length-1))
			{
				if (start < s.length())
				{
					String v = s.substring(start, s.length());
					if (!v.equals(c))
					{
						added = true;
						sList.add(v);
					}
				}
			}
			if (added == false)
			{
				sList.add("");
			}	
		}	
		return sList;
	}	
	
	private static int[] allIndexes (String text, String value, boolean ignoreCase)
	{
		ArrayList aList = new ArrayList();
		int index = -1;
		int start = 0;
		
		String s;
		String search;
		
		if (ignoreCase)
		{
			s = text.toLowerCase();
			search = value.toLowerCase();
		}
		else
		{
			s = text;
			search = value;
		}
		
		while ( (index = s.indexOf(search, start)) > -1)
		{
			aList.add(new Integer(index));
			start = index+1;	
		}
		int size = aList.size();
		int[] arr = new int[size];
		for (int i = 0; i < size; i++)
		{
			arr[i] = ((Integer)aList.get(i)).intValue();	
		}
		return arr;
	}	
%>