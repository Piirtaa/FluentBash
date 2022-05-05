//helpers/////////////////////////////////////////////////////////////////
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

/*
	utility functions:
		jsMeta
			.arrayUtil
				.arrArraysEqual : function(a,b)
				.removeSet : function(source, toRemove)
			.isNull : function(val)
			.isUndefined : function(val)
			.isNullOrUndefined : function(val)
			.isEmpty : function(val)
			.isPrimitive : function(val)
			.isFunction : function(val)
			.getMemberNamesAsArray : function(obj)
			.hasMembers : 	function(object to test membership on obj , list of members )
			.getRawFunctionSignature : function(func)
			.getFunctionArgNamesAsArray : function(func) 
			.hasSameFunctionSignature : function(fnA, fnB, isStrict)
			.convertFunctionArgsToMap : function(func, args)
			.hasFunctionArgNames : function( expects a function func, expects an array of names expectedArgNames)
			.isValidFunctionSignature : function(obj, name,  function(argNames)  argValidationFn)
			.hasSameObjectSignaturesAsTemplate : function(templateObj, testObj,  expects array of members to ignore excludeList)
			.validators
				.validateNotUndefined : function (obj)
 				.validateNotNull : function (obj)
 				.validateNotNullOrUndefined : function(obj)
 				.validateIsFunction : function (expectedFn)
 				.validateIsArray : function(expectedArray)
 				.assert : function(  assertion function returns bool assertionFn)
 			.JSONSerializer
 				.deserialize : function(text)
				.serialize : function (obj)
 			.StringArraySerializer
 				.deserialize : function(text)
 				.serialize : function(stringArray)
 				
*/
const arrayUtil = 
{
	areArraysEqual : function(a,b) 
	{
		if (a === b) return true;
		if (a == null || b == null) return false;
		
		if(!Array.isArray(a))
			throw new Error("not array");
		
		if(!Array.isArray(b))
			throw new Error("not array");
		
		if (a.length != b.length) return false;

		// If you don't care about the order of the elements inside
		// the array, you should sort both arrays here.

		for (var i = 0; i < a.length; ++i) {
			if (a[i] !== b[i]) return false;
		}
		
		return true;
	},
	removeSet : function(source, toRemove)
	{
		if (source === null) return [];
		if (toRemove === null) return source.slice();
	
		var rv = source.filter(function(item)
		{
			return toRemove.indexOf(item) < 0;
		});
		
		return rv;
	}
};

(function(){
	//lock it down
	Object.freeze(arrayUtil);
})();

const jsMeta = 
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
		return jsMeta.isUndefined(val)  || jsMeta.isNull(val);
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
			
		if(jsMeta.isNullOrUndefined(val))
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
		if(jsMeta.isNullOrUndefined(obj))
			return false;
		
		if(typeof obj !== "function")
			return false;
		
		return true;
	},
	/* reflection utilities ---------------------------------------------------------*/
	getMemberNamesAsArray : function(obj)
	{    
		"use strict";
		if(jsMeta.isNullOrUndefined(obj))
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
		if(jsMeta.isNullOrUndefined(obj))
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
		if(!jsMeta.isFunction(func))
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
		if(!jsMeta.isFunction(func))
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
		if(!jsMeta.isFunction(func))
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
		if(jsMeta.isNullOrUndefined(fnA))
			throw new Error("nullOrUndefined");
		if(jsMeta.isNullOrUndefined(fnB))
			throw new Error("nullOrUndefined");

		if(!jsMeta.isFunction(fnA))
			throw new Error("not a function");
		if(!jsMeta.isFunction(fnB))
			throw new Error("not a function");


		//run a strict mode compare
		if(isStrict)
		{
			var sigA = jsMeta.getFunctionRawSignature(fnA);
			var sigB = jsMeta.getFunctionRawSignature(fnB);
			
			return sigA === sigB;
		}

		//otherwise just compare argument names
		var namesA = jsMeta.getFunctionArgNamesAsArray(fnA);
		var namesB = jsMeta.getFunctionArgNamesAsArray(fnB);
		
		if(!arrayUtil.areArraysEqual(namesA, namesB))
			return false;
		
		return true;
	},
	/* converts an arguments array into a map using the parsed argument names as keys*/
	convertFunctionArgsToMap : function(func, args)
	{    
		"use strict";
		if(!jsMeta.isFunction(func))
			throw new Error("not a function");
		
		var rv = {};
		
		//if there are no args, there is no return data
		if(jsMeta.isNullOrUndefined(args))
			return rv;
		
		//parse the arg names
		var argNames = jsMeta.getFunctionArgNamesAsArray(func);
		
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
		if(!jsMeta.isFunction(func))
			throw new Error("not a function");
		
		if(!Array.isArray(expectedArgNames))
			throw new Error("not an array");
		
		var argNames = jsMeta.getFunctionArgNamesAsArray(func);
		
		return arrayUtil.areArraysEqual(argNames, expectedArgNames);
	},
		/* 
		examines obj to see if a function of name exists, and if its args pass the validation function
	*/
	isValidFunctionSignature : function(obj, name, /* function(argNames) */ argValidationFn)
	{    
		"use strict";
		if(jsMeta.isNullOrUndefined(obj))
			throw new Error("nullOrUndefined");
		if(jsMeta.isNullOrUndefined(name))
			throw new Error("nullOrUndefined");
		if(jsMeta.isNullOrUndefined(argValidationFn))
			throw new Error("nullOrUndefined");
	   
		//does the member exist?
		if(!jsMeta.hasMembers(obj, name))
			return false;
		
		//is it a function?
		var fn = obj[name];
		if(!jsMeta.isFunction(fn))
			return false;
		
		//get the args
		var argNames = jsMeta.getFunctionArgNamesAsArray(obj[name]);
		
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
		if(jsMeta.isNullOrUndefined(templateObj))
			throw new Error("nullOrUndefined");
		if(jsMeta.isNullOrUndefined(testObj))
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
			if(jsMeta.isFunction(templateMember))
			{
				var testMember = testObj[p];
				if(jsMeta.isFunction(testMember))
				{
					var templateArgs = jsMeta.getFunctionArgNamesAsArray(templateMember);
					var testMemberArgs = jsMeta.getFunctionArgNamesAsArray(testMember);
				
					if(!jsMeta.arrayUtil.areArraysEqual(templateArgs, testMemberArgs))
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
(function(){
	
	jsMeta.arrayUtil = arrayUtil;
	//lock it down
	Object.freeze(jsMeta);
})();

//executes whatever code is passed to it
const __evaluator = (function(){

	var rv = 
	{
		evaluate : function(fnText)
		{
			let result;
			result = eval.call(null, fnText);
			return result;
		},
		evaluateInFunction : function(fnText)
		{
			let fn=Function('"use strict";return (' + fnText + ')')();
			let result;
			result = fn();
			return result;
		}
			
	};
	
	Object.freeze(rv);
	
	return rv;
})();

//length encodes and decodes text
//the data format is:  le_lengthOfText_actualText
const lengthEncoder = (function(){
	
	var rv = {};
	rv.encode = function(text){
		if(lengthEncoder.isValid(text))
			return text;
			
		if(jsMeta.isNullOrUndefined(text))
			return "le_0_";
		
		let le = "le_" + text.length + "_" + text;
		return le;
	};
	rv.decode = function(text){
		if(!lengthEncoder.isValid(text))
			throw new Error("not length encoded");
		
		let val = lengthEncoder.getValue(text);
		return val;
	};
	//has length encoding smells
	rv.isIndicated = function(text){
		if(jsMeta.isNullOrUndefined(text))
			return false;
			
		if(!text.startsWith("le_"))
			return false;

		try
		{
			var len = parseInt(text.getAfter("le_").getBefore("_"));
		}
		catch(e){
			return false;
		}
		if(len < 0)
			return false;
		return true;
	};
	rv.getExpectedLength = function(text)
	{
		if(!lengthEncoder.isIndicated(text))
			throw new Error("not length encoded");
			
		let len = parseInt(text.getAfter("le_").getBefore("_"));
		return len;
	};
	rv.getValue = function(text)
	{
		if(!lengthEncoder.isIndicated(text))
			throw new Error("not length encoded");
			
		let val = text.getAfter("le_").getAfter("_");
		return val;
	};
	//is validly encoded
	rv.isValid = function(text){
		if(!lengthEncoder.isIndicated(text))
			return false;
			
		let len = lengthEncoder.getExpectedLength(text);
		let val = lengthEncoder.getValue(text);
		
		if(len == 0)
		{
			if (jsMeta.isNullOrUndefined(val))
				return true;
				
			return false;
		}
			
		if(len != val.length)
			return false;
		
		return true;
	};

	Object.freeze(rv);
	
	return rv;
})();

//the sandbox api.  does 2 things.  repl.  standalone function execution.
const __sandbox = (function(){

	//private 
	let _replEchoPrefix = "_echo_ ";
	let _replExitLine = "_exit_";
	let _replSilentPrefix = "_silent_";
	
	//public returned object
	var rv = 
	{ 
		//listens on std in, in an endless loop.  
		startRepl : function(/*fn()=>string*/ readLineStrategy, /*fn(obj)*/ printLineStrategy)
		{
			if(readLineStrategy == null)
				throw "null read strategy";
				
			if(printLineStrategy == null)
				throw "null print strategy";
			
			while (true) {
				var line = readLineStrategy();
				var actualLine;
				
				//special consideration for length encoded text.  
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
						var totalLine = lengthEncoder.getValue(line);
						var len = lengthEncoder.getExpectedLength(line);
						var timeoutFn = (size)=>{
							let msPer10000 = 1000;
							return size * msPer10000;
						};
						var expireDate = Date.now() + timeoutFn(len);
						while(expireDate > Date.now())
						{
							line = readLineStrategy();
							totalLine+=line;
							if(totalLine.length == len)
							{	
								//we have the full text now
								actualLine = totalLine;
								break;
							}
						}
					}
				}
				else
				{
					actualLine = line;
				}

				//don't process if we don't have a line
				if(jsMeta.isNullOrUndefined(actualLine))
					continue;
										
				//now we parse out any prefixes that are "special instructions"
				//exit
				if(actualLine == _replExitLine)
				{
					printLineStrategy("exiting");
					break;
				}
					
				//echo
				if(actualLine.startsWith(_replEchoPrefix))
				{
					actualLine=actualLine.getAfter(_replEchoPrefix);
					printLineStrategy(actualLine);
					continue;
				}
			
				//silent (ie. no printing of the result)
				var isSilent=false;
				if(actualLine.startsWith(_replSilentPrefix))
				{
					actualLine=actualLine.getAfter(_replSilentPrefix);
					isSilent=true;
				}
				
				//execute the instruction
				try{
					//execute	
					var result=__evaluator.evaluate(actualLine);
					
					if(isSilent)
						continue;
						
					//print
					printLineStrategy(result);
				}catch(e)
				{
					printLineStrategy("error on line:" + actualLine);
					printLineStrategy(e);
					continue;
				}
			}
		},
		evaluateFunction : function(/* a function definition*/ fnDef, /*fn(obj)*/ printLineStrategy)
		{
			if(printLineStrategy == null)
				throw "null print strategy";

			if(fnDef == null)
				throw "no code!"
				
			try{
				//execute	
				var result=__evaluator.evaluateInFunction(fnDef);
					
				//print
				printLineStrategy(result)
			}catch(e)
			{
				printLineStrategy(e);
			}	
		}
	};
	
	Object.freeze(rv);
	
	return rv;
})();
