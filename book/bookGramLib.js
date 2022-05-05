#!/usr/bin/env js78

/*this script provides a key-values (note the plurality) data structure that also supports parent-child keys.
 * -all mutations are append only.
 *   -there are 2 mutations.  add.  remove.
 *   -remove mutations can be specific to a single add entry, or they can apply to any entries in the parent-child tree. 
 *   	-to specify a specific removal both key and data need to be provided.
 * 		-to specify a tree removal only key is provided. 
 * -the net state of the graph is calculated by walking the structure and applying any remove entries to existing add entries.  this is called "emerging". 
 * -the data can be queried for text matches
 * -each entry is a single line in the datagram.
 * -all operations are fluent (meaning the gram is sent in via stdin, and returned via stdout) with the exceptions of the operations "format" and "getExactValues"
 * 	 -this avails chaining a series of mutations together in one line.
 * -the typical usage pattern for reading data would be a 2 step operation.  emerge -> format
 * -data can be multiline.  it is encoded to be one line.  
 * 
 * 
 * the design drivers for this data structure were:
 *   -reducing the complexity problems around graph mutation particularly under multi-threaded load.  the critical section is the end of the file only.
 * 		and it is only critical when mutations have the exact same key.  otherwise there is no functional difference in mutation sequence.
 *   -append-only.  this ensures that the state of a given graph can be easily tested for deltas.  if the gram is longer, a change has happened.  there is only 
 * 		one place to look for changes in the data structure - the end of the file.
 * 	 -nesting keys.  data that is organized under a single umbrella can be more easily parsed.  this also fits the "append-only" ethos.  newly added data
 * 		has the longest keys in the path.  there is an inherent sequencing to the data.
 *   -having somewhat performant string operations in shell.  bash is notoriously slow for this.  
 *   -observability of changes is easy.
 *   -checks against data corruption in the graph.  all entries have length metadata.  this means that the parsing of key and value is an exact instruction.  
 * 		there is no room for ambiguity.  there are no steps in the flow of parsing where corruption can happen.
 * 		-additional data corruption checks can be applied to the graph with trivial effort.  adding checksums, etc. would be the introduction of another length-delimited
 * 			item on the entry line.  thus this data structure is easily "decoratable". 
 * 	 -the association of data need not happen only within a given path/branch.  the search functionality allows for associations between branches to be easily discovered.
 * 		all you have to do is look for all of the places where a partial path is found.  this does not limit the modelling paradigm to operating only with hierarchical
 * 		groupings.  you can get "object"-y functionality and also cross-cutting functionality.
 * 	 
 * not design drivers but still interesting:
 * 	-symmetry.  the symmetry of this structure shows itself in pretty ways, not dissimilar to how arithmetic systems modelled with 
 * 		circular lists has an inherent symmetry to it.  there is fractal symmetry in this, too.  there is a negative and a positive that can be summed or 
 * 		"emerged".  there is inherent sequencing of data.  the growth is sequential in both key and the graph itself, while also providing grouping.  interestingly
 * 		this structure could also be used to model arithmetic systems where keys could represent orders of magnitude.  mathematical expressions could be encoded 
 * 		into the structure.     
 */ 

//helpers------------------------
const JSMeta = 
{
	/*primitive is tests------------------------------------------*/
	isNull : function(val)
	{
		"use strict";
		return val === null;
	},
	isUndefined : function(val)
	{
		"use strict";
		return val === undefined;
	},
	isNullOrUndefined : function(val)
	{
		"use strict";
		return JSMeta.isUndefined(val)  || JSMeta.isNull(val);
	},
	isEmpty : function(val)
	{
		//ECMA5+ 
		return Object.keys(val).length === 0 && val.constructor === Object;
		/*
		for(var prop in val) 
		{
			if(val.hasOwnProperty(prop))
				return false;
		}

		return JSON.stringify(val) === JSON.stringify({});
		*/
	},
	/*is something a javascript primitive type or an array*/
	isPrimitive : function(val)
	{
		"use strict";
			
		if(JSMeta.isNullOrUndefined(val))
			return true;
		
		var valType = typeof val;

		var rv = false;
		
		if(valType === "boolean")
		{
			rv = true;
		}
		else if (valType === "number")
		{
			rv = true;
		}
		else if (valType === "string")
		{
			rv = true;
		}
		else if (valType === "symbol")
		{
			rv = true;
		}
		else if(Array.isArray(val))
		{
			rv = true;
		}
		return rv;
	},
	isFunction : function (obj)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(obj))
			return false;
		
		if(typeof obj !== "function")
			return false;
		
		return true;
	},
	/* reflection utilities ---------------------------------------------------------*/
	getMemberNamesAsArray : function(obj)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(obj))
			throw new Error("nullOrUndefined");
		
		var rv = [];
		for(var p in obj)
		{
			rv.push(p);
		}
		return rv;
	},
	/* does the object have the provided properties */
	hasMembers : function(/* object to test membership on */ obj /*, ...list of members */)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(obj))
			throw new Error("nullOrUndefined");
		
		var args = arguments;
		for(var i=1;i<args.length;i++)
		{
			if(!obj.hasOwnProperty(args[i]))
				return false;
		}
		return true;
	},
	/*function reflection ---------------------------------------------------*/
	/* parses the raw function signature */
	getFunctionRawSignature : function(func)
	{   
		"use strict";
		if(!JSMeta.isFunction(func))
			throw new Error("not a function");
		
		//parse to 1st "{"
		var origText = func.toString();
		var sig = origText.split('{',1)[0];
		
		//scrub trailing whitespace
		sig = sig.trim();

		return sig;
	},
	getFunctionBody : function(func)
	{   
		"use strict";
		if(!JSMeta.isFunction(func))
			throw new Error("not a function");
		
		//parse to 1st "{"
		var origText = func.toString();
		var body = origText.split('{',1)[1];
		
		return body;
	},
	/* parses the function text to get a list of argument names */
	getFunctionArgNamesAsArray : function(func) 
	{   
		"use strict";
		if(!JSMeta.isFunction(func))
			throw new Error("not a function");
		
		// First match everything inside the function argument parens.
		var args = func.toString().match(/function\s.*?\(([^)]*)\)/)[1];

		// Split the arguments string into an array comma delimited.
		return args.split(',').map(function(arg) {
			// Ensure no inline comments are parsed and trim the whitespace.
			return arg.replace(/\/\*.*\*\//, '').trim();
		}).filter(function(arg) {
			// Ensure no undefined values are added.
			return arg;
		})
	},
	hasSameFunctionSignature : function(fnA, fnB, isStrict)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(fnA))
			throw new Error("nullOrUndefined");
		if(JSMeta.isNullOrUndefined(fnB))
			throw new Error("nullOrUndefined");

		if(!JSMeta.isFunction(fnA))
			throw new Error("not a function");
		if(!JSMeta.isFunction(fnB))
			throw new Error("not a function");


		//run a strict mode compare
		if(isStrict)
		{
			var sigA = JSMeta.getFunctionRawSignature(fnA);
			var sigB = JSMeta.getFunctionRawSignature(fnB);
			
			return sigA === sigB;
		}

		//otherwise just compare argument names
		var namesA = JSMeta.getFunctionArgNamesAsArray(fnA);
		var namesB = JSMeta.getFunctionArgNamesAsArray(fnB);
		
		if(!ArrayUtil.areArraysEqual(namesA, namesB))
			return false;
		
		return true;
	},
	/* converts an arguments array into a map using the parsed argument names as keys*/
	convertFunctionArgsToMap : function(func, args)
	{    
		"use strict";
		if(!JSMeta.isFunction(func))
			throw new Error("not a function");
		
		var rv = {};
		
		//if there are no args, there is no return data
		if(JSMeta.isNullOrUndefined(args))
			return rv;
		
		//parse the arg names
		var argNames = JSMeta.getFunctionArgNamesAsArray(func);
		
		//if there are no names for the map, there is no return data
		if(argNames.length == 0)
			return rv;
		
		for(var i=0; i < argNames.length; i++)
		{
			rv[argNames[i]] = args[i];    
		}

		return rv;
	},


	/* does the function have the provided args in the specified order */
	hasFunctionArgNames : function( /*expects a function */ func, /* expects an array of names */ expectedArgNames)
	{    
		"use strict";
		if(!JSMeta.isFunction(func))
			throw new Error("not a function");
		
		if(!Array.isArray(expectedArgNames))
			throw new Error("not an array");
		
		var argNames = JSMeta.getFunctionArgNamesAsArray(func);
		
		return ArrayUtil.areArraysEqual(argNames, expectedArgNames);
	},
		/* 
		examines obj to see if a function of name exists, and if its args pass the validation function
	*/
	isValidFunctionSignature : function(obj, name, /* function(argNames) */ argValidationFn)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(obj))
			throw new Error("nullOrUndefined");
		if(JSMeta.isNullOrUndefined(name))
			throw new Error("nullOrUndefined");
		if(JSMeta.isNullOrUndefined(argValidationFn))
			throw new Error("nullOrUndefined");
	   
		//does the member exist?
		if(!JSMeta.hasMembers(obj, name))
			return false;
		
		//is it a function?
		var fn = obj[name];
		if(!JSMeta.isFunction(fn))
			return false;
		
		//get the args
		var argNames = JSMeta.getFunctionArgNamesAsArray(obj[name]);
		
		//do the args validate?
		try
		{    
			if(!argValidationFn(argNames))
				return false;
		}
		catch(e)
		{
			return false;    
		}
		return true;
	},
	/*object meta ----------------------------------------------------------*/
	/*  has same member names && functions have same signatures.  uses templateObj as the members to query for */
	hasSameObjectSignaturesAsTemplate : function(templateObj, testObj, /* expects array of members to ignore*/ excludeList)
	{    
		"use strict";
		if(JSMeta.isNullOrUndefined(templateObj))
			throw new Error("nullOrUndefined");
		if(JSMeta.isNullOrUndefined(testObj))
			throw new Error("nullOrUndefined");

		if(excludeList)
			if(!Array.isArray(excludeList))
				throw new Error("not an array");
			
		var hasExclusions = !!excludeList;
		
		for(var p in templateObj)
		{
			if(hasExclusions)
				if(excludeList.indexOf(p) > -1)
					continue;
			
			if(!(p in testObj))
				return false;

			var templateMember = templateObj[p];
			if(JSMeta.isFunction(templateMember))
			{
				var testMember = testObj[p];
				if(JSMeta.isFunction(testMember))
				{
					var templateArgs = JSMeta.getFunctionArgNamesAsArray(templateMember);
					var testMemberArgs = JSMeta.getFunctionArgNamesAsArray(testMember);
				
					if(!JSMeta.arrayutil.areArraysEqual(templateArgs, testMemberArgs))
						return false;
				
				}
				else
				{
					return false;
				}
			}
		}

		return true;
	}
};

//string helper extension functions
String.prototype.getBefore = function (tag) {
    var index = this.indexOf(tag);

    if (index === -1) {
		return "";
    } else {
		return this.substr(0, index);
    }
};
String.prototype.getAfter = function (tag) {
    var index = this.indexOf(tag);

    if (index === -1) {
		return "";
    } else {
		return this.substr(index + tag.length);
    }
};
String.prototype.format = String.prototype.f = function() {
    var s = this,
        i = arguments.length;

    while (i--) {
        s = s.replace(new RegExp('\\{' + i + '\\}', 'gm'), arguments[i]);
    }
    return s;
};

//script logic -------------------------------------
var bookGram = (function(){
	var rv = {};
	
	//helpers
	let _buildEntry = function(op, key, val)
	{
		let entry=op + "_" + key.length + "_";
		
		if (JSMeta.isNullOrUndefined(val))
		{
			entry += "0_" + key;
		}
		else
		{
			let newData=val.split("\n").join("<NL>")
			entry += newData.length + "_" + key + "_" + newData ;
		} 
		return entry;
	};

	//members
	rv.addEntry = function(lines, key, val)
	{
		lines.push(_buildEntry("add", key, val));
		return lines;
	};
	rv.removeEntry = function(lines, key, val)
	{
		lines.push(_buildEntry("remove", key, val));
		return lines;
	};

	//queries for matches, returns match lines.  matches against entire line including length metadata
	rv.query = function(lines, contains)
	{
		let matches=[];
		
		//get the contains args
		let args = [].slice.call(arguments);
		args.shift(); //remove first element

		for(let i=0; i<lines.length; i++)
		{
			let line=lines[i];
			if(line.startsWith("add_") == false && line.startsWith("remove_") == false)
				continue;
						
			//we query the entire line.  this includes length metadata and the key,val
			for(let j=0; j<args.length; j++)
			{
				//let keyLen = parseInt(line.getAfter("_").getBefore("_"));
				//let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
				//let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
				//let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 

				if (line.includes(args[j]))
				{
					matches.push(line);
					continue;				
				}
			}
		}	
		return matches;	
	};
	//calculates emerged lines, returns them
	rv.emerge = function(lines, keyPortion)
	{
		let addedData=[]; //stores the data.  parallel to the lines
		let addedKeys=[]; //stores the keys.  parallel to the lines
		let addedLines=[]; //stores the lines

		for(let i=0; i<lines.length; i++)
		{
			let line=lines[i];
			
			if(line.startsWith("add_"))
			{
				//get matching add lines
				let keyLen = parseInt(line.getAfter("_").getBefore("_"));
				let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
				let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
				let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 
				
				if (JSMeta.isNullOrUndefined(keyPortion) || key.startsWith(keyPortion))
				{
					addedLines.push(line);
					addedKeys.push(key);
					addedData.push(data);
				}
			}
			else if(line.startsWith("remove_"))
			{
				//get matching remove lines 
				let keyLen = parseInt(line.getAfter("_").getBefore("_"));
				let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
				let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
				
				if ( !JSMeta.isNullOrUndefined(keyPortion) && !key.startsWith(keyPortion))
					continue;
				
				//apply the removal to the currently accumulated adds	
				//there are 2 cases
				//  case 1: path item removal - only keyPortion is provided.  any items with this are removed.
				//	case 2: exact item removal - both key and data match an add line.  only one item is removed.
				if(dataLen == 0)
				{
					//case 1
					for(let j=0; j< addedKeys.length; j++)
					{
						if(addedKeys[j] == key)
							addedLines[j]=null;
					}	
				}
				else
				{
					//case 2
					let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 
					for(let j=0; j< addedKeys.length; j++)
					{
						if(addedKeys[j] == key && addedData[j] == data)
						{
							addedLines[j]=null;
							break; //only match once
						}
					}
				}
			}
		}

		let emerged=[];
		for(let i=0; i<addedLines.length; i++)
		{
			if(addedLines[i] != null)
				emerged.push(addedLines[i]);
		}
		return emerged;
	};
	//formats the lines with a provided formatstring
	//a format string looks like 'sometext {0} somemoretext {1}'
	rv.format = function(lines, formatString)
	{
		let text=""
		for(let i=0; i<lines.length; i++)
		{
			let line=lines[i];
			let keyLen = parseInt(line.getAfter("_").getBefore("_"));
			let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
			let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
			let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 
			data=data.split("<NL>").join("\n");
			
			text+=formatString.f(key, data) + "\n";
		}
		return text;
	};
	rv.getExactValues = function(lines, keyPath)
	{
		//this is essentially an emerge, but matching exactly on keyPath
		
		if(JSMeta.isNullOrUndefined(keyPath))
			return null;
			
		let addedData=[]; //stores the data.  parallel to the lines
		let addedKeys=[]; //stores the keys.  parallel to the lines
		let addedLines=[]; //stores the lines

		for(let i=0; i<lines.length; i++)
		{
			let line=lines[i];
			
			if(line.startsWith("add_"))
			{
				//get matching add lines
				let keyLen = parseInt(line.getAfter("_").getBefore("_"));
				let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
				let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
				let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 
				
				if (key == keyPath)
				{
					addedLines.push(line);
					addedKeys.push(key);
					addedData.push(data);
				}
			}
			else if(line.startsWith("remove_"))
			{
				//get matching remove lines 
				let keyLen = parseInt(line.getAfter("_").getBefore("_"));
				let dataLen = parseInt(line.getAfter("_").getAfter("_").getBefore("_"));
				let key=line.getAfter("_").getAfter("_").getAfter("_").substr(0, keyLen);
				
				if (key != keyPath)
					continue;
				
				//apply the removal to the currently accumulated adds	
				//there are 2 cases
				//  case 1: path item removal - only keyPortion is provided.  any items with this are removed.
				//	case 2: exact item removal - both key and data match an add line.  only one item is removed.
				if(dataLen == 0)
				{
					//case 1
					for(let j=0; j< addedKeys.length; j++)
					{
						if(addedKeys[j] == key)
							addedLines[j]=null;
					}	
				}
				else
				{
					//case 2
					let data=line.getAfter("_").getAfter("_").getAfter("_").substr(keyLen + 1); 
					for(let j=0; j< addedKeys.length; j++)
					{
						if(addedKeys[j] == key && addedData[j] == data)
						{
							addedLines[j]=null;
							break; //only match once
						}
					}
				}
			}
		}

		let emergedValues=[];
		for(let i=0; i<addedLines.length; i++)
		{
			if(addedLines[i] != null)
				emergedValues.push(addedData[i]);
		}
		return emergedValues;
		
	};
	
	Object.freeze(rv);
	
	return rv;
})();
	




