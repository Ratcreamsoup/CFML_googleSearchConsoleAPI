<cfcomponent>

	<cffunction name="init" access="public" output="false" returntype="any">
		<cfargument name="libDir" type="string" required="true" />
		<cfargument name="keyFile" type="string" required="true" />
		<cfargument name="appName" type="string" required="false" default="SearchConsole" />
		<cfargument name="javaLoader" type="string" required="false" default="javaloader.JavaLoader" />
		<cfargument name="disableRequestTimeout" type="boolean" required="false" default="false" />
		<cfscript>
			var local = structNew();
			local.objLoader 					= getGoogleLoader(javaLoader=arguments.javaLoader,libDir=arguments.libDir);						
			variables.searchConsoleAppName 		= arguments.appName;
			variables.keyFile 					= arguments.keyFile;
			
			variables.JSON_Factory             	= local.objLoader.create("com.google.api.client.json.jackson2.JacksonFactory").init();			
			variables.WebmasterScopes 			= local.objLoader.create("com.google.api.services.webmasters.WebmastersScopes");
			variables.SAQueryRequest			= local.objLoader.create("com.google.api.services.webmasters.model.SearchAnalyticsQueryRequest");
			variables.objFilterGroup 			= local.objLoader.create("com.google.api.services.webmasters.model.ApiDimensionFilterGroup");
			variables.objFilter 				= local.objLoader.create("com.google.api.services.webmasters.model.ApiDimensionFilter");
			variables.HTTP_Transport 			= local.objLoader.create("com.google.api.client.googleapis.javanet.GoogleNetHttpTransport").newTrustedTransport();

			variables.GoogleCredentialBuilder 	= local.objLoader.create("com.google.api.client.googleapis.auth.oauth2.GoogleCredential$Builder")
				.setTransport(variables.HTTP_Transport)
				.setJsonFactory(variables.JSON_Factory)    			
				.build();			
			
			variables.Collections				= createObject("java", "java.util.Collections");
			
			if (arguments.disableRequestTimeout) {				
				variables.WebmastersBuilder 	= local.objLoader.create("com.google.api.services.webmasters.Webmasters$Builder").init(
			     variables.HTTP_Transport, 
			     variables.JSON_Factory, local.objLoader.create("com.google.api.client.http.DisableTimeout"));
			} else {
				variables.WebmastersBuilder 	= local.objLoader.create("com.google.api.services.webmasters.Webmasters$Builder").init(
			     variables.HTTP_Transport, 
			     variables.JSON_Factory, javaCast("null", ""));
			}
			return this;
		</cfscript>
	</cffunction>

	<cffunction name="buildWebmaster" access="public" output="false" returntype="struct" hint="creates webmaster object">
		<cfscript>
			var local 			= structNew();
			local.structReturn 	= {success=true, error=""};

			try {
				local.keyFile 			= createObject("java", "java.io.File").init(variables.keyFile);
	    		local.keyInputStream	= createObject("java", "java.io.FileInputStream").init(local.keyFile);     		    		
	    		local.credential 		= variables.GoogleCredentialBuilder	    			
	    			.fromStream(local.keyInputStream,variables.HTTP_Transport,variables.JSON_Factory)
	    			.createScoped(variables.Collections.singleton(variables.WebmasterScopes.WEBMASTERS_READONLY));	    		
	    		local.keyInputStream.close();	    		
    		} catch (Any e) {
    			local.structReturn.success 	= false;
    			local.structReturn.error 	= "Credential Object Error: " & e.message & " - " & e.detail;
    		}
    		try {
	    		variables.Webmasters 	= variables.WebmastersBuilder
	    			.setApplicationName(variables.searchConsoleAppName)
					.setHttpRequestInitializer(local.credential)
					.build();
			} catch (Any e) {
    			local.structReturn.success 	= false;
    			local.structReturn.error 	= "Webmasters Object Error: " & e.message & " - " & e.detail;
    		}			
			return local.structReturn;
		</cfscript>
	</cffunction>

	<cffunction name="getSites" access="public" output="false" returntype="struct" hint="returns all sites visible to application">
		<cfscript>
			var local 			= structNew();
			local.structReturn 	= {success=true, error=""};						
			try {
				local.structReturn.value = variables.Webmasters.sites().list().execute();				
			} catch(Any e) {
					local.structReturn.error 	= "Site List Error: " & e.message & " - " & e.detail;
					local.structReturn.success 	= false;					
			}
			return local.structReturn;
		</cfscript>		
	</cffunction>

	<cffunction name="searchAnalytics" access="public" output="false" bufferoutput="false" returntype="struct" hint="returns search analytics query result">
		<cfargument name="siteUrl" type="string" required="true" />		
		<cfargument name="startDate" type="string" required="no" default="" 
			hint="Start date of the requested date range, in YYYY-MM-DD format, in PST time (UTC - 8:00). Must be less than or equal to the end date. This value is included in the range." />
		<cfargument name="endDate" type="string" required="no" default=""
			hint="End date of the requested date range, in YYYY-MM-DD format, in PST time (UTC - 8:00). Must be greater than or equal to the start date. This value is included in the range." />
		<cfargument name="searchType" type="string" required="no" default="web" hint="one of [web,video,image]" />
		<cfargument name="aggregationType" type="string" required="no" default="auto" hint="one of [auto,byPage,byProperty]" />
		<cfargument name="rowLimit" type="numeric" required="no" default="1000" hint="The maximum number of rows to return. The API does not support paged results." />
		<cfargument name="startRow" type="numeric" required="no" default="0" hint="Zero-based index of the first row in the response. Must be a non-negative number." />
		<cfargument name="dimensions" type="array" required="no" default="#arrayNew(1)#" hint="Zero or more dimensions to group results by." />
		<cfargument name="filterGroups" type="array" required="no" default="#arrayNew(1)#" hint="Zero or more filters to test against the row. 
			Each filter consists of a dimension name, an operator, and a value. ." />
		<cfscript>
			var local 			= structNew();
			local.structReturn 	= {success=true, error=""};			

			switch (arguments.searchType) {
				case 'video':
				case 'image':
					local.searchType = lCase(arguments.searchType);
					break;
				default:
					local.searchType = 'web';
			}

			switch (arguments.aggregationType) {
				case 'byPage':
					local.aggregationType = 'byPage';
					break;
				case 'byProperty':
					local.aggregationType = 'byProperty';
					break;
				default:
					local.aggregationType = 'auto';
			}

			local.queryRequest = variables.SAQueryRequest
				.clone()
				.setStartDate(sanitizeDateString(strDate=arguments.startDate))
				.setEndDate(sanitizeDateString(strDate=arguments.endDate,type="end"))
				.setRowLimit(javacast('int', arguments.rowLimit))
				.setStartRow(javacast('int', arguments.startRow))
				.setSearchType(local.searchType)
				.setAggregationType(local.aggregationType);

			if (arrayLen(arguments.dimensions)) {
				local.queryRequest.setDimensions(arguments.dimensions);
			}

			local.iLenFilterGroups = arrayLen(arguments.filterGroups);
			if (local.iLenFilterGroups gt 0) {
				local.lstFiltergroups = arrayNew(1);
				for (local.i=1; local.i lte iLenFilterGroups; local.i++){

					local.structFilterGroup = arguments.filterGroups[local.i];

					if (structKeyExists(local.structFilterGroup, 'filters')) {

						local.objFilterGroup = variables.objFilterGroup.clone();
						if (structKeyExists(local.structFilterGroup, 'groupType')) {
							local.objFilterGroup.setGroupType(javacast('string', local.structFilterGroup.groupType));
						} else {
							local.objFilterGroup.setGroupType(javacast('string', 'and'));
						}
						local.arrFilters = local.structFilterGroup.filters;
						local.iLenFilters = arrayLen(local.arrFilters);
						local.lstFilters = arrayNew(1);
						for (local.j=1; local.j lte iLenFilters; local.j++){
							local.objFilter = variables.objFilter.clone();
							local.objFilter.setDimension(local.arrFilters[local.j].dimension);
							local.objFilter.setOperator(local.arrFilters[local.j].operator);
							local.objFilter.setExpression(local.arrFilters[local.j].expression);
							arrayAppend(local.lstFilters,local.objFilter);
						}
						local.objFilterGroup.setFilters(local.lstFilters);						
					}
					arrayAppend(local.lstFiltergroups,local.objFilterGroup);
				}				
				local.queryRequest.setDimensionFilterGroups(local.lstFiltergroups);				
			}
					
			local.structReturn.response = variables.Webmasters.searchanalytics().query(JavaCast('string',arguments.siteUrl),local.queryRequest).execute();			
			local.structReturn.request = local.queryRequest;
			return local.structReturn;
		</cfscript>
	</cffunction>

	<cffunction name="sanitizeDateString" access="private" output="false" returntype="string">
		<cfargument name="strDate" type="string" required="true">
		<cfargument name="type" type="string" required="false" default="start">
		<cfscript>
		var myDate = now();
		if (ReFind('^\d{4}\-\d{2}\-\d{2}$',arguments.strDate)) return arguments.strDate;		
		if (arguments.type eq 'start') {
			myDate = dateAdd('m', -1, myDate);
		} else {
			myDate = dateAdd('d', -1, myDate);
		}
		return dateFormat(myDate,'YYYY-MM-DD');
		</cfscript>
	</cffunction>

	<cffunction name="getGoogleLoader" access="public" returntype="any" output="false" hint="returns a loader object for the Google API libaries">
		<cfargument name="javaLoader" type="string" required="true" />
		<cfargument name="libDir" type="string" required="true" />
		<cfscript>
			var local = structNew();
			local.strLoaderUUID = "21efe785-591b-41d1-adc3-29924ed5bef8";
			if (structKeyExists(SERVER,local.strLoaderUUID)) {
				return SERVER[local.strLoaderUUID];
			}
			local.arrJars = arrayNew(1);
			local.libPath = arguments.libDir;
			if (!javaCast('string',local.libPath).endsWith('/')) local.libPath &= '/';
		</cfscript>		
		<cfdirectory action="list" directory="#local.libPath#" filter="*.jar" listinfo="name" recurse="true" name="local.qJars">
		<cfscript>
			for (local.i=1; local.i lte local.qJars.RecordCount; local.i++) {
				if (len(local.qJars.name[local.i]) && !ReFind('(^libs\-sources/|\-sources\.jar$)',local.qJars.name[local.i])) {
					arrayAppend(local.arrJars,local.libPath & local.qJars.name[local.i]);
				}
			}
			arrayAppend(local.arrJars, getDirectoryFromPath(getCurrentTemplatePath()) & 'lib/DisableTimeout.jar');
            SERVER[local.strLoaderUUID] = createObject('component', arguments.javaLoader).init(local.arrJars,javacast('boolean',false));
            return SERVER[local.strLoaderUUID];
		</cfscript>
	</cffunction>

</cfcomponent>