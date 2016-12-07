<cfcomponent accessors="true" output="false" extends="AbstractFactory" hint="Uses javaloader to create Java objects.">

	<cfproperty name="javaloader">
    <cffunction name="abort" output="yes">
    	<cfargument name="myvar" type="any" required="no" default="">        
        <cfdump var="#arguments.myvar#" />
        <cfabort>
    </cffunction>
    
    <cffunction name="dirList" access="private" output="yes" returntype="array">
    	<cfargument name="strPath" type="string" required="yes" />
        <cfargument name="strMode" type="string" required="no" default="file" />
        <cfargument name="strFilter" type="string" required="no" default="" />
        <cfscript>
			var local = structNew();			
			local.arrResult =  createObject("java","java.io.File").init(Trim(arguments.strPath)).list();
			local.iArrLen = arrayLen(local.arrResult);
			local.arrReturn = arrayNew(1);
			if (compare(arguments.strMode,'path') eq 0) {
				local.strPrefix = arguments.strPath & '/';
				} else {
				local.strPrefix = '';
			}
			if (compare(arguments.strFilter,'') neq 0) {
				for (local.i = 1; local.i lte local.iArrLen; local.i++) {
					if (ReFindNoCase(arguments.strFilter,local.arrResult[local.i],1,false) neq 0) {						
						ArrayAppend(local.arrReturn,local.strPrefix & local.arrResult[local.i]);
					}
				}
			}
			return local.arrReturn;
        </cfscript>
    </cffunction>


	<cffunction name="init" output="true" access="public" returntype="any" hint="">
		<cfargument name="javaloader" type="any" required="false" default="" hint="If you don't provide a fully initialized javaloader instance, we'll attempt to provide one for you"/>
		<cfset var local = {} />
		<cfif isSimpleValue(arguments.javaloader)>			
            <cfset local.jarPaths = dirList( GetDirectoryFromPath(GetCurrentTemplatePath()) &  '../lib','path', "jar$" )>            
			<cfset variables.javaloader = createObject('component','javaloader.JavaLoader').init(local.jarPaths)>
		<cfelse>
			<cfset variables.javaloader = arguments.javaloader>
		</cfif>

		<cfreturn super.init()>
    </cffunction>

	<cffunction name="getObject" output="false" access="public" returntype="any" hint="Creates a Java object">
    	<cfargument name="path" type="string" required="true"/>
		<cfreturn javaloader.create(path)>
    </cffunction>

</cfcomponent>