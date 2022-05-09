#!/usr/bin/env js78
/*usage:  
 * 			a) sandbox_spidermonkey.js code
 * 				in this modality the function "getStdInLines()" is available.  this will read all of stdin. 
 * 			b) sandbox_spidermonkey.js repl
 * 
 * 			the function "loadLibrary(pathToLib)" is also available which allows code to be loaded via script.
 */
 
var loadLibrary = function(pathToLib)
{
	load([pathToLib]);
};

//load up the repl library
loadLibrary("../jsSandbox/sandboxLib.js")

//define read and print strategies for the repl
var defaultReadStrategy = function()
{
	return readline();
}

var leReadStrategy = function()
{
	var line = defaultReadStrategy();
	var actualLine;
	
	//is length encoded? 
	if(lengthEncoder.isIndicated(line))
	{
		//is it fully read?
		if(lengthEncoder.isValid(line))
		{
			actualLine=lengthEncoder.getValue(line);
		}
		else
		{
			//read until we get the full length, within a timeout window
			var totalLine = line;
			var len = lengthEncoder.getExpectedLength(line);
			
			//set the timeout as a function of data size
			var timeoutFn = (size)=>{
				let msPer10000 = 1000;
				return size * msPer10000;
			};
			var expireDate = Date.now() + timeoutFn(len);
			
			while(expireDate > Date.now())
			{
				line = defaultReadStrategy();
				totalLine+=line;
				if(lengthEncoder.isValid(totalLine))
				{
					//we have the full text now
					actualLine = lengthEncoder.getValue(totalLine);
					break;
				}
			}
		}
	}
	else
	{
		actualLine = line;
	}

	return actualLine;
}
				
var defaultPrintStrategy = function(obj)
{
	print(String(obj));
}

var lePrintStrategy = function(obj)
{
	print(lengthEncoder.encode(String(obj)));
}

var printHelp = function()
{
	print("usage: ./sandbox_spidermonkey.js functionDef");
	print("  to retrieve stdin call 'getStdInLines()'");
	print("  to load a lib call 'loadLibrary(pathToFile)'"); 
	print("usage:  echo functionDef | ./sandbox_spidermonkey.js piped");
	print("  to pipe the function from stdin instead of as an argument");
	print("usage: ./sandbox_spidermonkey.js repl");
	print("  starts a repl instance.");
	print("usage: ./sandbox_spidermonkey.js repl le");
	print("  starts a repl instance with length-encoding.");
	print(" ");
	print("additional repl notes:");
	print("  send '_exit_' to close.");
	print("  prefix request with '_echo_' to echo the input.");
	print("  prefix request with '_silent_' to print no results.");
}

if(scriptArgs[0] == null)
{	
	printHelp();
}
else
{	
	//actual logic/////////////////////////////////////////////////////////////////
	switch(scriptArgs[0]){

		case "--help":
			printHelp();
			break;
		case "repl":
			if (scriptArgs[1] == "le")
			{
				__sandbox.startRepl(leReadStrategy, lePrintStrategy);
			}
			else
			{
				__sandbox.startRepl(defaultReadStrategy, defaultPrintStrategy);
			}
			break;
		case "piped":
			var getStdInLines = function()
			{
				let lines=[];
				let line="";
				while (line = readline()) {
					lines.push(line);
				}
				return lines;
			};
			var fnDef=getStdInLines().join("\n");
			__sandbox.evaluateFunction(fnDef, defaultPrintStrategy);
			break;
		default:
			//define a helper function to get stdin 
			var getStdInLines = function()
			{
				let lines=[];
				let line="";
				while (line = readline()) {
					lines.push(line);
				}
				return lines;
			};
			var fnDef=scriptArgs[0];
			__sandbox.evaluateFunction(fnDef, defaultPrintStrategy);
	}
}
