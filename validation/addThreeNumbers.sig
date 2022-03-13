_KEY_1_pos_arg1
1
_KEY_1_pos_arg2
2
_KEY_1_pos_arg3
3
_KEY_1_paramvalidator_arg2_isGreaterThan
isGreaterThan 10
_KEY_1_paramvalidator_arg3_isLessThan
isLessThan 20
_KEY_1_paramvalidator_arg1_isLessThan
isLessThan 10
_KEY_1_param_arg3
arg3
_KEY_1_param_arg2
arg2
_KEY_1_param_arg1
arg1
_KEY_1_paramvalidator_arg2_isNumeric
isNumeric
_KEY_11__fn_isNumeric
isNumeric () 
{ 
    case $1 in 
        '' | *[!0-9]*)
            return 1
        ;;
        *)
            return 0
        ;;
    esac
}
_KEY_1_paramvalidator_arg3_isGreaterThanOrEqual
isGreaterThanOrEqual 15
_KEY_1____id___
z7LsB
_KEY_4__fn_isGreaterThan
isGreaterThan () 
{ 
    [[ "$2" -gt "$1" ]]
}
_KEY_4__fn_isLessThan
isLessThan () 
{ 
    [[ "$2" -lt "$1" ]]
}
_KEY_1_default_arg3
0
_KEY_1_default_arg2
0
_KEY_1_default_arg1
0
_KEY_1_paramvalidator_arg3_isNumeric
isNumeric
_KEY_1_isOptional_arg1
false
_KEY_1_isOptional_arg2
false
_KEY_1_isOptional_arg3
false
_KEY_1_sig
addThreeNumbers
_KEY_1_paramvalidator_arg1_isNumeric
isNumeric
_KEY_4__fn_isGreaterThanOrEqual
isGreaterThanOrEqual () 
{ 
    [[ "$2" -ge "$1" ]]
}
