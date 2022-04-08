#!/usr/bin/env js78


//private functions
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

var getStdInLines = function()
{
	let lines=[];
	let line="";
	while (line = readline()) {
		lines.push(line);
	}
	return lines;
};

//use case functions

//executes whatever code is passed to it
const __runner = (function(){

	var rv = 
	{
		run : function(fnText)
		{
			let result;
			result = eval.call(null, fnText);
			return result;
		},
		run2 : function(fnText)
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

//takes an array of lines, replaces newline with the provided delim (or "_NL" by default) and returns a length encoded datagram with the prefix "le_"
var lengthEncodeLines=function(lines, newLineDelim)
{
	let delim="_NL_";
	if (! JSMeta.isNullOrUndefined(newLineDelim))
		delim=newLineDelim;
	let result=lines.join(delim);
	result="le_" + result.length + "_" + result;
	return result;
};
//decodes a length encoded string (has prefix "le_") and returns a string with \n newlines
var lengthDecodeLines=function(lines, newLineDelim)
{
	let delim="_NL_";
	if (! JSMeta.isNullOrUndefined(newLineDelim))
		delim=newLineDelim;
	
	let rawData=lines.join("");
	if(!rawData.startsWith("le_"))
	{ 
		throw "not a length-encoded string"; 
	}
	let len=rawData.getAfter("_").getBefore("_");
	let data=rawData.getAfter("_").getAfter("_");
	if(data.length != parseInt(len))
	{
		throw "length mismatch";
	}
	data=data.replaceAll(delim, "\n");
	return data;
};

//string mutators
//A | append B = AB
//B | prepend A = BA
//A | appendLine B = 	A
//						B
//A | prependLine B =	B
//						A
//if the input string is length-encoded, the operations assume the data is also to be length-encoded						
//other ops
//getLineOf


//actual script function
switch(scriptArgs[0]){

	
	case "lengthEncode":
		//usage: echo $data | ./stringsUtil.js lengthEncode newLineDelim 
		var lines=getStdInLines();
		
		try{
			var result=lengthEncodeLines(lines, scriptArgs[1]);
			print(result);
			quit(0);
		}
		catch(e)
		{
			print(e);
			quit(1);
		}
		break;
	case "lengthDecode":
		//usage: echo $data | ./stringsUtil.js lengthDecode newLineDelim 
		var lines=getStdInLines();
		
		try{
			var result=lengthDecodeLines(lines, scriptArgs[1]);
			print(result);
			quit(0);
		}
		catch(e)
		{
			print(e);
			quit(1);
		}
		break;
	case "handle":
		var expression=scriptArgs[1];
		try{
			var result=__runner.run2(expression);
			
			if (Array.isArray(result))
			{
				result.forEach((element, index, array) => { print(element);});
			}
			else if(typeof result === "function")
			{
				print(result.toString());
			}
			else
			{
				print(result)
			}
			quit(0);
		}
		catch(e)
		{
			print(e);
			quit(1);
		}
		break;
	default:
		print("usage1:  echo $data | ./stringsUtil.js lengthEncode myDelim");
		print("usage2:	echo $data | ./stringsUtil.js lengthDecode myDelim");
		print("usage3:	echo $data | ./stringsUtil.js handle functionDef");
		
}

