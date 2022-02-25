# FluentBash
bash scripting done fluently

Features:

	Key-Value store written entirely in Bash that allows data to be persisted across shell instances.

	Variable store that allows variables to be easily shared between shells.

	Fluent string and list mutation

	Fluent tests/conditionals, facilitating inline tests as part of the construction of data

	Much cleaner and more readable Bash scripting


See the various Test scripts for example usage.

-------------

To reference FluentBash add the following lines to the top of your script.  This assumes your script is running in the same root directory as FluentBase.

Load loader first

	[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

	source $BASH_DIR/../core/core.sh #first thing we load is the script loader

To load up a specific library/functionality add a "loadScript" call.  eg. 
	
	loadScript $BASH_DIR/../piping/piping.sh
	
	loadScript $BASH_DIR/../piping/strings.sh
	
	loadScript $BASH_DIR/../piping/lists.sh
	
	loadScript $BASH_DIR/../piping/conditionals.sh
	
	loadScript $BASH_DIR/../caching/sharedVars.sh
	
	loadScript $BASH_DIR/../caching/keyValueStoreCreate.sh
	
	loadScript $BASH_DIR/../caching/keyValueStore.sh

-------------
Examples of the functionality expressed as bash tests.


STRINGS  

[ "$(echo "abc" | getStdIn)" == "abc" ]

[ "$(echo "abc" | getLength)" == "3" ]

[ "$(echo "abc" | getSubstring 0)" == "abc" ]

[ "$(echo "abc" | getSubstring 1)" == "bc" ]

[ "$(echo "abc" | getSubstring 3)" == "" ]

[ "$(echo "a" | append b)" == "ab" ]

[ "$(echo "a" | prepend b)" == "ba" ]

[ "$(echo "a" | appendLine b | getLine 1 )" == "a" ]
	
[ "$(echo "a" | appendLine b | getLine 2 )" == "b" ]

[ "$(echo "a" | prependLine b | getLine 1 )" == "b" ]
	
[ "$(echo "a" | prependLine b | getLine 2 )" == "a" ]
	
[ "$(echo "a" | prependLine b | replaceLine 2 c | getLine 2 )" == "c" ]
	
[ "$(echo "a" | prependLine b | replaceLine 2 c | getLine 1 )" == "b" ]

[ "$(echo "a" | appendLine b | appendLine c | appendOnLine 2 d | getLine 2 )" == "bd" ]

[ "$(echo "a" | appendLine b | appendLine c | prependOnLine 2 d | getLine 2 )" == "db" ]

[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 1 )" == "a" ]

[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 2 )" == "d" ]

[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 3 )" == "b" ]

[ "$(echo "a" | appendLine b | appendLine c | insertLine 2 d | getLine 4 )" == "c" ]

LIST=$(echo a | appendLine b | appendLine c | appendLine d | appendLine e | appendLine f);

[ "$(echo "$LIST" | insertLine 1 x | getLine 1 )" == "x" ]

[ "$(echo "$LIST" | getLinesAbove 1 | getLine 1 )" == "" ]

[ "$(echo "$LIST" | getLinesAbove 0 | getLine 1 )" == "" ]

[ "$(echo "$LIST" | getLinesAbove 10 | getLine 1 )" == "a" ]

[ "$(echo "$LIST" | getLinesBelow 1 | getLine 1 )" == "b" ]

[ "$(echo "$LIST" | getLinesBelow 0 | getLine 1 )" == "a" ]

[ "$(echo "$LIST" | replaceLine 1 x | getLine 1 )" == "x" ]

[ "$(echo "$LIST" | removeLine 1  | getLine 1 )" == "b" ]

[ "$(echo "$LIST" | replaceLine 3 x | getLine 3 )" == "x" ]
			


LISTS

[ "$(echo "a b c" | getArrayItem 0)" == "a" ]
	
[ "$(echo "a b c" | getArrayItem 1)" == "b" ]

[ "$(echo "a b c" | getArrayItem 4)" == "" ]

[ "$(echo "a b c" | getFirstArrayItem )" == "a" ]

[ "$(echo "a b c" | getFirstArrayItemRemainder )" == "b c" ]

[ "$(echo "a,b,c" | getArrayItem 0 ,)" == "a" ]

[ "$(echo "a,b,c" | getArrayItem 1 ,)" == "b" ]

[ "$(echo "a,b,c" | getArrayItem 4 ,)" == "" ]

[ "$(echo "a,b,c" | getFirstArrayItem , )" == "a" ]

[ "$(echo "a,b,c" | getFirstArrayItemRemainder , )" == "b,c" ]

[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 1 =a)" == "a" ]

[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 2 =b)" == "b" ]
	
[ "$(echo "a,b,c" | getArrayItemsAsLines , | getLine 3 =c)" == "c" ]

[ "$(echo "A dog,A cat,B cat,C cat" | doEach , appendToFile derp | touch derp; cat derp  | getLine 1 ; rm derp )" == "A dog" ]

[ "$(echo "A dog,A cat,B cat,C cat" | doEach , ifContains A | appendToFile derp | touch derp; cat derp  | getLine 2 ; rm derp )" == "A cat" ]



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

[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesEquals 3 | getLine 1 =a)" == "a" ]

[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesGreaterThan 2 | getLine 1 =a)" == "a" ]

[ "$(echo "a,b,c" | getArrayItemsAsLines , | ifNumberOfLinesLessThan 4 | getLine 1 =a)" == "a" ]



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



