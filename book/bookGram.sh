#!/bin/bash
#summary:  fluent modelling
#tags: model narrative fluent domain object 

#WARNING!!!!!!!!!!!!!!!!!!!!
#this is obsolete!!!  and very slow.  a more performant javascript solution doing the same basic thing is bookGram.js.


#load loader first.  
[ -z ${BASH_DIR} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
. $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript piping/piping.sh
loadScript piping/strings.sh
loadScript piping/lists.sh
loadScript piping/conditionals.sh

#what is a bookGram?
#	it is a datagram that models a book-like ledger-like data structure, aka the "Book" 
#		-mutation of the book is append-only.  entries are appended to the structure.
#		-entries are either add or remove
#		-entries have a (mandatory, string, no newline chars) path and (optional, string) data 
#		-paths are not validated for uniqueness
#		-the "emerged" state of the structure applies all of the remove operations to matching entries that occurred prior to the remove.  
#			-eg. case 1. a remove operation with path "abcd" and no data, will remove ALL add entries PRIOR 
#				to the remove entry whose paths START WITH "abcd" 
#			-eg. case 2. a remove operation with path "abcd" and data "mydata", will remove the FIRST add entry, 
#				iterating from the start of the book, that has the exact path "abcd" and the exact data "mydata"
#			-ie. emergeBooks summarize the datagram's contained state, producing another bookGram containing only add entries.
#				the evaluation happens in the book's sequence of entries starting from the first entry.
#		-a query of the structure will look for partial text matches of ANY search terms in both path and data.  it will produce another
#			bookGram.
#		-emerged bookGrams (ie. ones with no remove entries) can be converted into 2 bash arrays of the same length containing paths and data.
#		-similarly emerged bookGrams can be hydrated from 2 bash arrays of equal length containing paths and data.

#what are the advantages of this approach?
#	 -the emerged state of a gram can be explicitly calculated at every mutation/step
#	 -the emerged state of a specific path can be explicitly calculated by filtering out for entries starting with the provided path, and emerging that 
#	 -the processing of large grams can be parallelized via splitting the gram into smaller grams of different (ie. non matching) paths and processing them individually
#	 -concurrent mutation has only one critical section - the "end of the gram".  and this is only critical when the paths are matching.  for non-matching patterns
#		sequence is irrelevant.
#	 -additional validation checks can easily be added to mutation.  
#		-checksums can be appended to the entry line, providing data integrity checks to the "data" part.
#		-a decorator of checksums similar to blockchain can similarly be applied, providing data integrity to the entire book.

#TODO:  need ways to speed this up
#			splitting by unrelated paths 
#				faster line by line processing
#			replacing pipe redirection with similar mechanism without the crazy overhead

#MUTATOR PRIMITIVES --------------------------------------------------------------------------
# usage: gsub_literal STR REP
# replaces all instances of STR with REP. reads from stdin and writes to stdout.
gsub_literal() {
  # STR cannot be empty
  [[ $1 ]] || return

  # string manip needed to escape '\'s, so awk doesn't expand '\n' and such
  awk -v str="${1//\\/\\\\}" -v rep="${2//\\/\\\\}" '
    # get the length of the search string
    BEGIN {
      len = length(str);
    }

    {
      # empty the output string
      out = "";

      # continue looping while the search string is in the line
      while (i = index($0, str)) {
        # append everything up to the search string, and the replacement string
        out = out substr($0, 1, i-1) rep;

        # remove everything up to and including the first instance of the
        # search string from the line
        $0 = substr($0, i + len);
      }

      # append whatever is left
      out = out $0;

      print out;
    }
  '
}
readonly -f gsub_literal

#description:  tests a key for unrelatedness and updates the keyline
#usage:  echo "$GRAM" | _updateKeyPath keyPath
#_updateKeyPath()
#{
#	local STDIN KEYLINE LIST
#	STDIN=$(getStdIn)
#	KEYLINE=$(echo "$STDIN" | getLine 1)
#	LIST=$(echo "$KEYLINE" | gsub_literal "_|_" $'\n') 
#		
#}
#readonly -f _isUnrelatedKeyPath

#description:  constructs an add entry
#usage:  _buildEntry op keyPath data
_buildEntry()
{
	local OP KEYPATH DATA LEN1 LEN2 
	OP="$1"
	if [[ -z "$OP" ]]; then
		#debecho _buildEntry op not provided
		return 1
	fi
	shift
	
	KEYPATH="$1"
	if [[ -z "$KEYPATH" ]]; then
		#debecho _buildEntry keypath not provided
		return 1
	fi
	shift
	
	#validate the key has no newlines
	local LINECOUNT
	LINECOUNT=$(getLineCount < <(echo "$KEYPATH"))
	if [[ "$LINECOUNT" != 1 ]]; then
		#debecho _buildEntry invalid keypath
		return 1
	fi
	LEN1=$(getLength < <(echo "$KEYPATH"))

	DATA="$@"
	if [[ -z "$DATA" ]]; then
		#debecho _buildEntry data not provided
		echo "$OP""_""$LEN1""_0_""$KEYPATH"
	else
		local LIST EACH TEMP
		IFS=$'\n' read -d '' -r -a LIST <<< "$DATA"
		for EACH in "${LIST[@]}"
		do
			TEMP=$(append "$EACH""<NL>" < <(echo "$TEMP")) 
		done
		TEMP=${TEMP::-4}
		LEN2=$(getLength < <(echo "$TEMP"))
		echo "$OP""_""$LEN1""_""$LEN2""_""$KEYPATH""_""$TEMP"			
	fi
	
	return 0
}
readonly -f _buildEntry
#debugFlagOn _buildEntry

#MUTATORS --------------------------------------------------------------------------

#description:  add dataline
#usage:  echo $gram | addData keyPath data
addData()
{
	local STDIN ENTRY
	STDIN=$(getStdIn)
	if [[ ! -z "$STDIN" ]]; then
		echo "$STDIN"
	fi
	ENTRY=$(_buildEntry add "$@")
	echo "$ENTRY"
	return 0
}
readonly -f addData

#description:  remove dataline
#usage:  echo $gram | removeData keyPath 
#usage:  echo $gram | removeData keyPath data
removeData()
{
	local STDIN ENTRY
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		debecho removeData stdin not provided
		return 1
	fi
	echo "$STDIN"
	ENTRY=$(_buildEntry remove "$@")
	echo "$ENTRY"
	return 0	
}
readonly -f removeData

#ARRAY CONVERSION------------------------------------------------------------------
#description:  converts datagram to 3 equal length arrays of key, data, and op
#usage:  bookToArrays  keyArrayName dataArrayName opArrayName pathStartsWith <<< $gram
bookToArrays()
{
	local STDIN KEYPATH
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		debecho bookToArrays stdin not provided
		return 1
	fi
	#debecho bookToArrays stdin "$STDIN"
	
	local -n RETURNKEYS=$1 #uses nameref bash 4.3+
	local -n RETURNVALUES=$2 #uses nameref bash 4.3+
	local -n RETURNOPS=$3 #uses nameref bash 4.3+
	local PATHSTARTSWITH=$4
	#debecho bookToArrays pathKey "$PATHSTARTSWITH"
	
	local GRAMLEN
	GRAMLEN=$(getLineCount < <(echo "$STDIN"))
	#debecho bookToArrays gramlen "$GRAMLEN"
	
	local ARR I LINE OP  
	OP=""
	IFS=$'\n' read -d '' -r -a ARR <<< "$STDIN"
	
	#debecho bookToArrays arrsize "${#ARR[@]}"
	
	#iterate over each line
	for ((I = 0 ; I < "$GRAMLEN" ; I++)); do
		LINE="${ARR[$I]}"
		#debecho bookToArrays line "$LINE"
		
		#determine if it's an entry line
		if [[ -z "$OP" ]]; then
			#echo "$LINE" | ifStartsWith "add_" >/dev/null  && OP=add #&& debecho bookToArrays add op
			ifStartsWith "add_" >/dev/null < <(echo "$LINE")  && OP=add #&& debecho bookToArrays add op
		fi
		
		if [[ -z "$OP" ]]; then
			#echo "$LINE" | ifStartsWith "remove_" >/dev/null && OP=remove #&& debecho bookToArrays remove op
			ifStartsWith "remove_" >/dev/null < <(echo "$LINE") && OP=remove #&& debecho bookToArrays remove op
		fi
		
		if [[ ! -z "$OP" ]]; then
			local SEG1 SEG2 SEG3
			local ENTRYPATH ENTRYPATHLEN DATA DATALEN VERIFY_ENTRYPATHLEN 
			#line structure is op_keylen_datalen_key_data 
			SEG1=$(getAfter "_" < <(echo "$LINE"))
			#debecho bookToArrays seg1 "$SEG1"
			ENTRYPATHLEN=$(getBefore "_" < <(echo "$SEG1"))
			#debecho bookToArrays entrypathlen "$ENTRYPATHLEN"
			SEG2=$(getAfter "_" < <(echo "$SEG1"))
			#debecho bookToArrays seg2 "$SEG2"
			DATALEN=$(getBefore "_" < <(echo "$SEG2"))
			#debecho bookToArrays datalen "$DATALEN"
			SEG3=$(getAfter "_" < <(echo "$SEG2"))
			#debecho bookToArrays seg3 "$SEG3"
			ENTRYPATH=$(getSubstring 0 "$ENTRYPATHLEN" < <(echo "$SEG3"))
			#debecho bookToArrays entrypath "$ENTRYPATH"
			
			#verify and exit if there is bad data
			VERIFY_ENTRYPATHLEN=$(getLength < <(echo "$ENTRYPATH"))
			#debecho bookToArrays verify entrypathlen "$VERIFY_ENTRYPATHLEN"
			if [[ "$VERIFY_ENTRYPATHLEN" != "$ENTRYPATHLEN" ]]; then
				debecho bookToArrays bad entry header.  path length mismatch. line "$I"
				return 1
			fi
			
			if [[ $DATALEN != 0 ]]; then
				ENTRYPATHLEN=$(( ENTRYPATHLEN +1 ))
				DATA=$(getSubstring $ENTRYPATHLEN < <(echo "$SEG3"))
			else
				DATA=""
			fi
			#debecho bookToArrays data "$DATA"
			
			if [[ -z "$PATHSTARTSWITH" ]]; then
				#debecho bookToArrays no path filter adding path "$ENTRYPATH"
				RETURNKEYS+=("$ENTRYPATH")
				RETURNVALUES+=("$DATA")
				RETURNOPS+=("$OP")
			else
				local ISMATCH=false
				#echo "$ENTRYPATH" | ifStartsWith "$PATHSTARTSWITH" >/dev/null && ISMATCH=true
				ifStartsWith "$PATHSTARTSWITH" >/dev/null < <(echo "$ENTRYPATH") && ISMATCH=true
				
				if [[ "$ISMATCH" == true ]]; then
					debecho bookToArrays path filter "$PATHSTARTSWITH" adding path "$ENTRYPATH"
					RETURNKEYS+=("$ENTRYPATH")
					RETURNVALUES+=("$DATA")
					RETURNOPS+=("$OP")
				fi
			fi
			#reset
			OP=""
		fi
	done
	
	return 0	
}
readonly -f bookToArrays
debugFlagOn bookToArrays

#description:  creates book datagram from 3 equal length arrays of key, data, and op
#usage:  arraysToBook  keyArrayName dataArrayName opArrayName 
arraysToBook()
{
	local -n KEYS=$1 #uses nameref bash 4.3+
	local -n VALUES=$2 #uses nameref bash 4.3+
	local -n OPS=$3 #uses nameref bash 4.3+
	
	local LEN KEY VALUE i OP BOOK
	LEN=${#VALUES[@]} #note we use the values array because we don't unset any of its values and thus don't mess with the length
	#debecho arraysToBook len "$LEN"
	
	for ((i = 0 ; i < "$LEN" ; i++)); do
		KEY="${KEYS[$i]}"
		VALUE="${VALUES[$i]}"
		OP="${OPS[$i]}"
	
		#debecho arraysToBook key "$KEY" op "$OP" value "$VALUE"
		if [[ -z "$KEY" ]]; then
			continue;
		fi
		
		if [[ "$OP" == add ]]; then
			BOOK=$(addData "$KEY" "$VALUE" < <(echo "$BOOK"))
		fi
		
		if [[ "$OP" == remove ]]; then
			BOOK=$(removeData "$KEY" "$VALUE" < <(echo "$BOOK"))
		fi
	done
	
	echo "$BOOK"
	return 0	
}
readonly -f arraysToBook
#debugFlagOn arraysToBook

#GETTERS --------------------------------------------------------------------------
#description:  queries datagram.  returns subset of datagram where query is contained in either path or data
#usage:  echo $gram | queryBook searchterm searchterm 
queryBook()
{
	local STDIN 
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		debecho queryBook stdin not provided
		return 1
	fi
	#debecho queryBook stdin "$STDIN"
	
	local -a TEMPKEYS
	local -a TEMPVALUES
	local -a TEMPOPS
	
	bookToArrays TEMPKEYS TEMPVALUES TEMPOPS < <(echo "$STDIN")
		
	local LEN KEY VALUE i OP SEARCH ISMATCH
	LEN=${#TEMPVALUES[@]}
	#debecho queryBook len "$LEN"
	
	for ((i = 0 ; i < "$LEN" ; i++)); do
		KEY="${TEMPKEYS[$i]}"
		VALUE="${TEMPVALUES[$i]}"
		OP="${TEMPOPS[$i]}"
		ISMATCH=false
		
		for SEARCH in "$@" ; do
			#echo "$KEY" | ifContains "$SEARCH"  >/dev/null && ISMATCH=true && break
			#echo "$DATA" | ifContains "$SEARCH" >/dev/null && ISMATCH=true && break
			ifContains "$SEARCH" < <(echo "$KEY") >/dev/null && ISMATCH=true && break
			ifContains "$SEARCH" < <(echo "$DATA") >/dev/null && ISMATCH=true && break
		done
		
		if [[ "$ISMATCH" == false ]]; then
			#debecho queryBook unsetting index "$i"
			unset TEMPKEYS["$i"]
			#unset TEMPVALUES["$i"]
			unset TEMPOPS["$i"]
		#else
			#debecho queryBook keeping index "$i"
		fi
	done
	
	arraysToBook TEMPKEYS TEMPVALUES TEMPOPS

	return 0	
}
readonly -f queryBook
#debugFlagOn queryBook

#EMERGERS --------------------------------------------------------------------------
#description:  emergeBooks entities.  walks gram and summarizes all add/removes into a set of keys under a given keypath
#usage:  echo $gram | emergeBook (optional) keyPath 
emergeBook()
{
	local STDIN KEYPATH
	STDIN=$(getStdIn)
	if [[ -z "$STDIN" ]]; then
		debecho emergeBook stdin not provided
		return 1
	fi
	#debecho emergeBook stdin "$STDIN"
	#debecho emergeBook stdin "$(echo "$STDIN" | getLineCount)"
	
	KEYPATH="$1"
	#debecho emergeBook keypath "$KEYPATH"
	
	local -a TEMPKEYS
	local -a TEMPVALUES
	local -a TEMPOPS
	
	bookToArrays TEMPKEYS TEMPVALUES TEMPOPS "$KEYPATH" < <(echo "$STDIN")
		
	local LEN KEY VALUE i OP  
	LEN=${#TEMPKEYS[@]}
	
	for ((i = 0 ; i < "$LEN" ; i++)); do
		KEY="${TEMPKEYS[$i]}"
		VALUE="${TEMPVALUES[$i]}"
		OP="${TEMPOPS[$i]}"
		#debecho emergeBook key "$KEY" op "$OP" value "$VALUE"
		
		#it's a remove.  we now have to go thru all the prior registered adds and remove matches
		if [[ "$OP" == remove ]]; then
			local KEY2 VALUE2 j OP2 
			for ((j = 0 ; j < "$i" ; j++)); do
				KEY2="${TEMPKEYS[$j]}"
				
				#skip already removed entries
				if [[ -z "$KEY2" ]]; then
					continue
				fi
				
				VALUE2="${TEMPVALUES[$j]}"
				
				#if the remove keyPath entry has no associated data then we are removing any emerged keypath that starts with it
				#otherwise we are looking for an exact entry match of keyPath and data and removing just that entry
				if [[ -z "$VALUE" ]]; then
					#echo "$KEY2" | ifStartsWith "$KEY" >/dev/null && unset TEMPKEYS["$j"] && unset TEMPOPS["$j"] #&& debecho emergeBook remove key "$KEY2"
					#ifStartsWith "$KEY" <<< "$KEY2" >/dev/null && unset TEMPKEYS["$j"] && unset TEMPOPS["$j"] #&& debecho emergeBook remove key "$KEY2"
					ifStartsWith "$KEY" < <(echo "$KEY2") >/dev/null && unset TEMPKEYS["$j"] && unset TEMPOPS["$j"] #&& debecho emergeBook remove key "$KEY2"
				else
					if [[ "$KEY" == "$KEY2" ]]; then
						if [[ "$VALUE" == "$VALUE2" ]]; then
							unset TEMPKEYS["$j"]
							unset TEMPOPS["$j"]
							#debecho emergeBook remove key "$KEY2"
							
							#we stop at one exact match of keypath/data
							break;
						fi
					fi	
				fi
			done
			
			#remove self
			unset TEMPKEYS["$i"]
			unset TEMPOPS["$i"]
		fi
	done
	
	arraysToBook TEMPKEYS TEMPVALUES TEMPOPS
 	
 	return 0
}
readonly -f emergeBook
debugFlagOn emergeBook


#description:  dumps the contents of an array
#usage:  dumpArray varName
dumpArray()
{
	local K
	local -n ARR=$1 #uses nameref bash 4.3+
	for K in "${ARR[@]}"; do echo "$K" ; done
}
readonly -f dumpArray
