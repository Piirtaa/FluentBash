# FluentBash
bash scripting done fluently, with a js REPL and runner for those things that bash is a bad fit for.  

Features:

	Common bash functions done in a fluent idiom allowing logic to be easily chained together.  
	
	Dependency loading.  
	
		Eg. loadScript piping/strings.sh
		
	Fluent string and list mutation.  
		
		Eg.  echo line1 | appendLine line2 | appendLine line3 | prependLine line0 | replaceLine 1 line0a
		| removeLine 2 | insertLine 2 line2redux | ifNumberOfLinesGreaterThan 4 | doEachLine ifStartsWith line 
		| appendToFile myFile | getLine 2 

	Fluent tests/conditionals, availing a pattern of "echo $data | filter1 | filter2 | filter3" which allows 
	things like validating data as you construct it, filtering lists, stashing and recalling data during iteration.  
		
		Eg.  echo goodLine1 | appendLine goodLine2 | appendLine badLine | appendLine goodLine3 
		| appendToFile tempFile | doEachLine ifStartsWith bad | appendToFile badFile > /dev/null; cat tempFile 
		| doEachLine ifStartsWith good | appendToFile goodFile ; rm tempFile 
	
	In-memory key-value store (written entirely in Bash) that that allows data to be persisted across shell
	(and sub-shell) instances.  
		
		Eg. setKV myKey myValue ; getKV myKey  

	Variable store that allows variables to be easily shared between shells.   
		
		Eg.  BOB='bob'; shareVar myExportedVarsFile BOB ; doUpdate myExportedVarsFile ; 
		unshareVar myExportedVarsFile BOB
		
	Reactive programming allowing event-driven logic to be constructed which is persistent, and which can be 
	chained together to create complex workflows.  
		
		Eg.  initStepA(){...} stepATriggerEvent(){...} doStepA(){...} ; createTrigger stepA stepATriggerEvent
		| doBeforeTrigger initStepA | doAfterTrigger doStepA ; activateTrigger stepA myPollingInterval ;
	
	Fluent validation of function signatures, decoupled from function.  For example, this is useful if we need
	to inject additional validation strategies into externally provided logic. 
		
		Eg. addThreeNumbers(){...} ; createSig addThreeNumbers | addParameter arg1 1 false 0 | 
		addParameter arg2 2 false 0 | addParameter arg3 3 false 0 | addParamValidator arg1 isNumeric | 
		addParamValidator arg2 isNumeric | addParamValidator arg3 isNumeric | addParamValidator arg1 isLessThan 10 
		| addParamValidator arg2 isGreaterThan 10 | addParamValidator arg3 isLessThan 20 
		| addParamValidator arg3 isGreaterThanOrEqual 15 ; validateSig addThreeNumbers 1 11 15 ;
	
	A bunch of systems stuff for programmatically spinning up sockets, http servers, hotspots, 
	port knocking logic, etc.  Too many to summarize quickly.  Look in the sockets, http, hotspot
	and recipes folders for examples.
	
	X-automation including automation of firefox, webscraping, etc.
	
	A process-shim framework for intercepting stdin/stdout of a process so that it can be more easily managed.
	For example, this allows javascript engines to be REPL-ized such that they can be talked to via shell commands.
	
	A javascript sandbox for executing standalone js.  
		
		Eg. jsRun.sh '()=>{return 1;}'
		Eg. echo '()=>{return 1;}' | jsRun.sh piped
	
	A javascript REPL.
		
		Eg. jsREPL.sh start myREPL
		    echo "var a=1;" | jsREPL.sh run myREPL 	
		    echo "a++;" | jsREPL.sh run myREPL
		    jsREPL.sh getHistory myREPL
		    jsREPL.sh stop myREPL
		    
See the various Test scripts for example usage.

-------------

To reference FluentBash add the following lines to the top of your script.  This assumes your script is running in the same root 
directory as FluentBash.

Load loader first

	[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

	source $BASH_DIR/../core/core.sh #first thing we load is the script loader

To load up a specific library/functionality add a "loadScript" call.  eg. 
	
	loadScript piping/piping.sh
	
	loadScript piping/strings.sh
	
	loadScript piping/lists.sh
	
	loadScript piping/conditionals.sh
	
	loadScript caching/sharedVars.sh
	
	loadScript caching/keyValueStoreCreate.sh
	
	loadScript caching/keyValueStore.sh

-------------
Brief xxamples of some of the functionality expressed as bash tests.


STRINGS  

	[ "$(echo "abc" | getStdIn)" == "abc" ]

	[ "$(echo "abc" | getLength)" == "3" ]

	[ "$(echo "abc" | getSubstring 0)" == "abc" ]

	[ "$(echo "abc" | getSubstring 1)" == "bc" ]

LISTS

	[ "$(echo "a b c" | getArrayItem 0)" == "a" ]
	
	[ "$(echo "a b c" | getArrayItem 1)" == "b" ]

	[ "$(echo "a b c" | getArrayItem 4)" == "" ]

	[ "$(echo "a b c" | getFirstArrayItem )" == "a" ]

	[ "$(echo "a b c" | getFirstArrayItemRemainder )" == "b c" ]

	[ "$(echo "a,b,c" | getArrayItem 0 ,)" == "a" ]

	[ "$(echo "A dog,A cat,B cat,C cat" | doEach , appendToFile derp | touch derp; cat derp  | getLine 1 ;
	rm derp )" == "A dog" ]

	[ "$(echo "A dog,A cat,B cat,C cat" | doEach , ifContains A | appendToFile derp | touch derp; cat derp  
	| getLine 2 ; rm derp )" == "A cat" ]

CONDITIONALS

	[ "$(echo "abc" | ifContains b)" == "abc" ]

	[ "$(echo "abc" | ifContains d)" == "" ]

	[ "$(echo "abc" | ifEquals abc)" == "abc" ]

	[ "$(echo "abc" | ifEquals bc)" == "" ]

	[ "$(echo "abc" | ifArgsEqual 1 1)" == "abc" ]

	[ "$(echo "abc" | ifArgsEqual 1 2)" == "" ]

	[ "$(echo "abc" | ifLengthOf 3)" == "abc" ]

	[ "$(echo "abc" | ifLengthOf 2)" == "" ]

	[ "$(echo "abc" | ifStartsWith a)" == "abc" ]

	[ "$(echo "abc" | ifStartsWith d)" == "" ]
	
	[ "$(echo "abc" | ifEndsWith c)" == "abc" ]

	[ "$(echo "abc" | ifEndsWith a)" == "" ]

	[ "$(echo "abc" | ifArgsEqual a a)" == "abc" ]

PERSISTING VARIABLES
	
	$(BOB="i'm bob";  shareVar dumpfile BOB;)

	doUpdate dumpfile		

	[ "$BOB" == "i'm bob" ]

	unset BOB	

	$(unshareVar dumpfile BOB;)

	doUpdate dumpfile		

	[ "$BOB" == "" ]



IN-MEMORY (using tmpfs) KEY VALUE STORE

	setKV bob joe

	[ "$(getKV bob)" == "joe" ]


TRIGGERS

	#load trigger library 

	loadScript unitOfWork/trigger.sh
	
	#define a series of steps.  
	#	each step has 3 parts:  before trigger fires logic; the trigger; after trigger fires logic.  
	#	the trigger itself is polled.  each step is persisted as a file in a "unitOfWork" datagram
	which encapsulates its logic
	#		so that it can be exported across machine boundary.
	#	triggers can be chained together.  thus a chain of reactive logic can be created somewhat fluently.
	touch testFile

	#step 1
	beforeStep1() { echo "before step1" >> testFile }
	step1Trigger() { echo "step 1 triggered" >> testFile ; return 0 ; }
	afterStep1() { echo "after step1" >> testFile }
	createTrigger step1 step1Trigger beforeStep1 afterStep1

	#step 2
	beforeStep2() { echo "before step2" >> testFile }
	step2Trigger() { echo "step 2 triggered" >> testFile ; return 0 ; }
	afterStep2() { echo "after step2" >> testFile }
	createTrigger step2 step2Trigger beforeStep2 afterStep2

	#link step1 to step2
	chainTriggers step1 step2

	#fire it off, with polling at 5 second intervals
	activateTrigger step1 5

SIGNATURE VALIDATION

	#load dependencies.  
	loadScript validation/functionSig.sh
	loadScript validation/validators.sh

	#description: a function that adds numbers 
	#usage:  addThreeNumbers 1 2 3 
	addThreeNumbers()
	{
		local arg1 arg2 arg3
		arg1="$1"
		arg2="$2"
		arg3="$3"
	
		echo $(( arg1 + arg2 + arg3 ))	
	}

	#signature validation injects the following:
	#arg 1 must be less than 10
	#arg 2 must be greater than 10
	#arg 3 must be less than 20 and greater than or equal to 15
	SIG=$(createSig addThreeNumbers | addParameter arg1 1 false 0 | addParameter arg2 2 false 0 | addParameter arg3 3 false 0)
	SIG=$(echo "$SIG" | addParamValidator arg1 isNumeric | addParamValidator arg2 isNumeric | addParamValidator arg3 isNumeric)
	SIG=$(echo "$SIG" | addParamValidator arg1 isLessThan 10 | addParamValidator arg2 isGreaterThan 10 | addParamValidator arg3 isLessThan 20 | addParamValidator arg3 isGreaterThanOrEqual 15)

	#passes validation
	validateSig addThreeNumbers 1 11 15

	#does not pass validation
	validateSig addThreeNumbers 1 11 25
