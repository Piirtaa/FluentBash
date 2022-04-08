#!/bin/bash
#summary: library supporting function signature functionality
#tags: function signature parameters arguments args param validation

#load loader first.  
[ -z ${BASH_DIR+x} ] && BASH_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $BASH_DIR/../core/core.sh #first thing we load is the script loader

#load dependencies.  
loadScript keyValue/keyValueGram.sh

#description: creates a parameters datagram, and saves it as a functionName".params" file where it is defined
#usage: createSig functionName
createSig()
{
	local GRAM FNNAME 
	FNNAME="$1"
	
	if [[ -z "$FNNAME" ]] ; then
		debecho createSig no function name provided
		return 1	
	fi

	#test if the fnName is a function
	isUserDefinedFunction "$FNNAME" || debecho createSig not a function "$FNNAME"; 	return 1;
		
	GRAM=$(kvgSet sig "$FNNAME")
	
	FNNAME=$(echo "$GRAM" | kvgGet sig)
	echo "$GRAM" > "$FNNAME"".sig"
	echo "$GRAM"
	return 0
}
readonly -f createSig
#debugFlagOn createSig

#description: defines a parameter
#usage: echo "$SIG" | addParameter name position isOptional defaultValue 
addParameter()
{
	local GRAM FNNAME NAME POSITION ISOPT DEFAULT
	
	GRAM=$(getStdIn)
	if [[ -z "$GRAM" ]] ; then
		debecho addParameter no signature provided
		return 1	
	fi
	
	NAME="$1"
	POSITION="$2"
	ISOPT="$3"
	DEFAULT="$4"
	
	if [[ -z "$NAME" ]] ; then
		debecho addParameter no name provided
		return 1	
	fi

	debecho addParameter name: "$NAME" pos: "$POSITION" isopt: "$ISOPT" default: "$DEFAULT"
		
	GRAM=$(echo "$GRAM" | kvgSet param_"$NAME" "$NAME")
	GRAM=$(echo "$GRAM" | kvgSet pos_"$NAME" "$POSITION")
	GRAM=$(echo "$GRAM" | kvgSet isOptional_"$NAME" "$ISOPT")
	GRAM=$(echo "$GRAM" | kvgSet default_"$NAME" "$DEFAULT")

	FNNAME=$(echo "$GRAM" | kvgGet sig)
	echo "$GRAM" > "$FNNAME"".sig"
	echo "$GRAM"
	return 0
}
readonly -f addParameter
#debugFlagOn addParameter

#description: creates a signature validator
#usage: addSigValidator function args
addSigValidator()
{
	local GRAM FNNAME VALFN VALFNBODY
	
	GRAM=$(getStdIn)
	if [[ -z "$GRAM" ]] ; then
		debecho addSigValidator no signature provided
		return 1	
	fi

	FNNAME=$(echo "$GRAM" | kvgGet sig)
	VALFN="$1"

	if [[ -z "$VALFN" ]] ; then
		debecho addSigValidator no validator function provided
		return 1	
	fi

	#test if is a function
	isUserDefinedFunction "$VALFN" || debecho addSigValidator not a function "$VALFN"; 	return 1 ;
	
	GRAM=$(echo "$GRAM" | kvgSet sig_validator "$@" )
	VALFNBODY=$(declare -f "$VALFN" )	
	GRAM=$(echo "$GRAM" | kvgSet _fn_"$VALFN" "$VALFNBODY" )

	echo "$GRAM" > "$FNNAME"".sig"
	echo "$GRAM"
	return 0
}
readonly -f addSigValidator
#debugFlagOn addSigValidator

#description: creates a signature validator
#usage: addParamValidator paramName function args.  NOTE!!:  the LAST arg into the function call MUST be the param value
addParamValidator()
{
	local GRAM FNNAME PARAM PARAM2 VALFN VALFNBODY
	
	GRAM=$(getStdIn)
	if [[ -z "$GRAM" ]] ; then
		debecho addParamValidator no signature provided
		return 1	
	fi

	FNNAME=$(echo "$GRAM" | kvgGet sig)
	PARAM="$1"
	shift
	
	if [[ -z "$PARAM" ]] ; then
		debecho addParamValidator no parameter name provided
		return 1	
	fi

	PARAM2=$(echo "$GRAM" | kvgGet param_"$PARAM")
	if [[ "$PARAM" != "$PARAM2" ]]; then
		debecho addParamValidator parameter not found "$PARAM"	
		return 1	
	fi
		
	VALFN="$1"
	if [[ -z "$VALFN" ]] ; then
		debecho addParamValidator no validator function provided
		return 1	
	fi
	#test if is a function
	isUserDefinedFunction "$VALFN" || debecho addParamValidator not a function "$VALFN"; return 1 ;
	
	GRAM=$(echo "$GRAM" | kvgSet paramvalidator_"$PARAM"_"$VALFN" "$@" )
	VALFNBODY=$(declare -f "$VALFN" )	
	GRAM=$(echo "$GRAM" | kvgSet _fn_"$VALFN" "$VALFNBODY" )

	echo "$GRAM" > "$FNNAME"".sig"
	echo "$GRAM"
	return 0
}
readonly -f addParamValidator
#debugFlagOn addParamValidator

#description: creates a signature validator
#usage: validateSig functionName args
validateSig()
{
	local GRAM FNNAME
	FNNAME="$1"
	shift
	
	GRAM=$(cat "$FNNAME"".sig" )
	if [[ -z "$GRAM" ]] ; then
		debecho validateSig no signature provided
		return 1	
	fi
	
	local KEYS PARAMKEYS PARAMFNS LIST EACH RV VAL POS ISOPT DEFAULT LIST2 EACH2 VALIDATOR
	KEYS=$(echo "$GRAM" | kvgGetAllKeys)
	#debecho validateSig keys "$KEYS"
	
	#validate all parameters
	PARAMKEYS=$(echo "$KEYS" | doEachLine ifStartsWith "param_" | doEachLine getAfter "param_" )
	
	#debecho validateSig paramkeys "$PARAMKEYS"
	IFS=$'\n' read -d '' -r -a LIST <<< "$PARAMKEYS"
	for EACH in "${LIST[@]}"
	do
		POS=$(echo "$GRAM" | kvgGet pos_"$EACH")
		ISOPT=$(echo "$GRAM" | kvgGet isOptional_"$EACH" )
		DEFAULT=$(echo "$GRAM" | kvgGet default_"$EACH" )
		#debecho validateSig name: "$EACH" pos: "$POS" isopt: "$ISOPT" default: "$DEFAULT"

		#get the value of the passed arg
		VAL="${!POS}"
		#debecho validateSig val: "$VAL"
		if [[ -z "$VAL" ]]; then
			#if the param is not optional we throw an error
			if [[ "$ISOPT"==true ]]; then
				debecho validateSig not optional error "$EACH"
				return 1
			fi		
			
			VAL="$DEFAULT"
		fi
		
		#get all of the functions applied to this parameter
		PARAMFNS=$(echo "$KEYS" | doEachLine ifStartsWith "paramvalidator_""$EACH""_" | doEachLine getAfter "paramvalidator_""$EACH""_" )
		#debecho validateSig paramfunctions "$PARAMFNS"
		IFS=$'\n' read -d '' -r -a LIST2 <<< "$PARAMFNS"
		for EACH2 in "${LIST2[@]}"		
		do
			#get the validator call
			VALIDATOR=$(echo "$GRAM" | kvgGet paramvalidator_"$EACH"_"$EACH2" )
			
			#get the function
			VALFNBODY=$(echo "$GRAM" | kvgGet _fn_"$EACH2" )
				
			#if the function already exists and has the same def, don't emerge it		
			local CURRENTFNDEF=$(declare -f "$EACH2")	
			if [[ "$CURRENTFNDEF" != "$VALFNBODY" ]] ; then
				eval "$VALFNBODY"
			fi
	
			#run the validator.  NOTE:
			eval "$VALIDATOR"" ""$VAL"
			RV=$?
			if [[ "$RV" != 0 ]]; then
				#kack
				debecho validateSig validator call "$VALIDATOR" "$VAL" fails
				return 1
			#else
				#debecho validateSig validator call "$VALIDATOR" "$VAL" success
			fi
		done				
	done
	
	debecho validateSig "$FNNAME" "$@" success

	return 0
}
readonly -f validateSig
debugFlagOn validateSig
