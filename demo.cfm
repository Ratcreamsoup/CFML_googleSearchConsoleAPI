<cfscript>
	variables.libDir = getDirectoryFromPath(getCurrentTemplatePath()) & 'googlesearch/lib/webmasters';
	variables.keyFile = getDirectoryFromPath(getCurrentTemplatePath()) & 'googlesearch/API_Project-123456789012.json';
	variables.javaLoader = 'lib.javaloader.JavaLoader';
	
	variables.objGoogle = createObject('component', 'googlesearch.google')
		.init(
			libDir=variables.libDir,
			keyFile=variables.keyFile,
			javaLoader=variables.javaLoader,			
			appName='SearchConsoleTest',
			disableRequestTimeout=true	
		);
	variables.objGoogle.buildWebmaster();

	variables.arrDimensions = ["date","page"];
	
	variables.strFirst = "-681325/";
	variables.strSecond = "-154107/"; 	

	variables.filterGroups = arrayNew(1);

	variables.filterGroup = structNew();
	variables.filterGroup.groupType = "and";
	variables.filterGroup.filters = arrayNew(1);

	variables.filter = structNew();	
	variables.filter.dimension = "page";
	variables.filter.operator = "contains";
	variables.filter.expression = variables.strFirst;
	arrayAppend(variables.filterGroup.filters, variables.filter);

	variables.filter = structNew();	
	variables.filter.dimension = "page";
	variables.filter.operator = "contains";
	variables.filter.expression = variables.strSecond;
	arrayAppend(variables.filterGroup.filters, variables.filter);
	arrayAppend(variables.filterGroups, variables.filterGroup);

</cfscript>

<cfdump var="#variables.objGoogle.getSites()#" label="getSites" />

<cfdump var="#variables.objGoogle.searchAnalytics(
	siteUrl='http://www.pcgameshardware.de/',
	startDate="2016-11-27",
	aggregationType="auto",
	dimensions=variables.arrDimensions,
	filterGroups=variables.filterGroups,
	rowLimit=3
)#" 
label="searchAnalytics" />