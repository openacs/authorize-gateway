ad_library {

    Procedures to implement Authorize.net credit card transactions.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
}

ad_proc -private authorize_gateway.authorize {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to Authorize.net to authorize a transaction for the amount 
    given on the card given.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {
    # 1. Send transaction off to gateway

    set test_request [authorize_gateway.decode_test_request]
    set field_seperator [ad_parameter field_seperator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] referer_url]]

    # Add the Referer to the headers passed on to Authorize.net

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with Authorize.net

    # Basic secure URL and account info.

    set full_url "[ad_parameter authorize_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_url]]?x_Login=[ns_urlencode [ad_parameter authorize_login -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_login]]]&x_Password=[ns_urlencode [ad_parameter authorize_password -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_password]]]"

    # Add necessary ADC (Authorize.net Direct Connect) info such as the delimiting character.

    append full_url "&x_ADC_URL=False&x_ADC_Delim_Data=True&x_ADC_Delim_Character=[ns_urlencode $field_seperator]"

    # Set the test request flag to indicate trial communication or a real live transaction.

    append full_url "&x_Test_Request=[ns_urlencode $test_request]"

    # Set the transaction type to AUTHORIZE ONLY and set the invoice
    # number to the transaction id paramater. This is a bit confusing
    # as the transaction id passed to this procedure should not be
    # mistaken for the transaction id that Authorize.net will generate
    # and return. The Authorize.net transaction id will be store in
    # the response_transaction_id. Use the response_transaction_id to
    # complete the transaction with a POST_AUTH operation.
 
    append full_url "&x_Type=AUTH_ONLY&x_Amount=[ns_urlencode [format "%0.2f" $amount]]&x_Invoice_Num=$transaction_id&x_Description=[ns_urlencode [ad_parameter description -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] description]]]"

    # Set the credit card information.

    append full_url "&x_Card_Num=[ns_urlencode $card_number]&x_Exp_Date=[ns_urlencode ${card_exp_month}/${card_exp_year}]&x_Last_Name=[ns_urlencode $card_name]"

    # Set the billing information. The information will be used by
    # Authorize.net to run an AVS check.

    append full_url "&x_Address=[ns_urlencode $billing_street]&x_City=[ns_urlencode $billing_city]&x_Zip=[ns_urlencode $billing_zip]&x_State=[ns_urlencode $billing_state]&x_Country=[ns_urlencode $billing_country]"

    # Contact Authorize.net and receive the character delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to Authorize.net.

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
	authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" $error_message 3 "" $error_message "" "" $amount
	set return(response_code) [nsv_get payment_gateway_return_codes retry]
	set return(reason) "Transaction $transaction_id failed, could not contact Authorize.net: $error_message"
	set return(transaction_id) $transaction_id
	return [array get return]
    } else {

	# 2. Insert into log table

	# Decode the response from Authorize.net. Not all fields are
	# of interest. See the Authorize.net documentation
	# (https://secure.authorize.net/docs/response.pml)
	# for a complete list of response codes.

	set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

	# Check that the response from Authorize.net is a legimate ADC
	# response. When Authorize.net has problems the response is
	# not a character delimited list but an HTML page. An ADC
	# response has certainly 38 or more elements. Future
	# versions might return more elements.

	if { [llength $response_list] < 38 } {
	    authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" $response 3 "" \
		"Authorize.net must be down, the response was not a character delimited list" "" "" $amount
	    set return(response_code) [nsv_get payment_gateway_return_codes retry]
	    set return(reason) "Authorize.net must be down, the response was not a character delimited list"
 	    set return(transaction_id) $transaction_id
	    return [array get return]
	} else {
	    set response_code [lindex $response_list 0]
	    set response_reason_code [lindex $response_list 2]
	    set response_reason_text [lindex $response_list 3]
	    set response_auth_code [lindex $response_list 4]
	    set response_avs_code [lindex $response_list 5]
	    set response_transaction_id [lindex $response_list 6]
	    set response_md5_hash [lindex $response_list 37]
	    authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_ONLY" \
		$response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

	    # 3. Return result

	    return [authorize_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text \
			$response_md5_hash $amount]
	}
    }
}

ad_proc -public authorize_gateway.chargecard {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    ChargeCard is a wrapper so we can present a consistent interface to
    the caller.  It will just pass on it's parameters to 
    authorize_gateway.postauth or authorize_gateway.authcapture, 
    whichever is appropriate for the implementation at hand. 

    PostAuth is used when there is a successful authorize transaction in 
    the authorize_gateway_result_log for transaction_id. AuthCapture will 
    be used if there is no prior authorize transaction in the log.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {

    # 1. Check for the existence of a prior auth_only for the transaction_id.

    if {[db_0or1row select_auth_only "
	select transaction_id, auth_code
	from authorize_gateway_result_log 
	where txn_attempted_type='AUTH_ONLY' 
	and response_code='1' 
	and transaction_id=:transaction_id"]} {

	# 2a. The transaction has been authorized, now mark the transaction for settlement.

	return [authorize_gateway.postauth $transaction_id $auth_code $card_number $card_exp_month $card_exp_year $amount]

    } else {

	# 2b. This is a new transaction which will be authorized and automatically marked for settlement.

	return [authorize_gateway.authcapture $transaction_id $amount $card_type $card_number $card_exp_month $card_exp_year \
		    $card_name $billing_street $billing_city $billing_state $billing_zip $billing_country]
    }
}

ad_proc -public authorize_gateway.return {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to Authorize.net to refund the amount given to the card given. 
    The transaction id needs to reference a settled transaction performed 
    with the same card.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {

    # 1. Send transaction off to gateway

    set test_request [authorize_gateway.decode_test_request]
    set field_seperator [ad_parameter field_seperator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] referer_url]]

    # Add the Referer to the headers passed on to Authorize.net

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with Authorize.net

    # Basic secure URL and account info.

    set full_url "[ad_parameter authorize_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_url]]?x_Login=[ns_urlencode [ad_parameter authorize_login -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_login]]]&x_Password=[ns_urlencode [ad_parameter authorize_password -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_password]]]"

    # Add necessary ADC (Authorize.net Direct Connect) info such as the delimiting character.

    append full_url "&x_ADC_URL=False&x_ADC_Delim_Data=True&x_ADC_Delim_Character=[ns_urlencode $field_seperator]"

    # Set the test request flag to indicate trial communication or a real live transaction.

    append full_url "&x_Test_Request=[ns_urlencode $test_request]"

    # Set the transaction type to CREDIT and the transaction id.
 
    append full_url "&x_Type=CREDIT&x_Amount=[ns_urlencode [format "%0.2f" $amount]]&x_Trans_ID=$transaction_id"

    # Set the credit card information.

    append full_url "&x_Card_Num=[ns_urlencode $card_number]&x_Exp_Date=[ns_urlencode ${card_exp_month}/${card_exp_year}]&x_Last_Name=[ns_urlencode $card_name]"

    # Contact Authorize.net and receive the character delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to Authorize.net.

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
	authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" $error_message 3 "" $error_message "" "" $amount
	set return(response_code) [nsv_get payment_gateway_return_codes retry]
	set return(reason) "Transaction $transaction_id failed, could not contact Authorize.net: $error_message"
	set return(transaction_id) $transaction_id
	return [array get return]
    } else {

	# 3. Insert into log table

	# Decode the response from Authorize.net. Not all fields are
	# of interest. See the Authorize.net documentation
	# (https://secure.authorize.net/docs/response.pml)
	# for a complete list of response codes.

	set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

	# Check that the response from Authorize.net is a legimate ADC
	# response. When Authorize.net has problems the response is
	# not a character delimited list but an HTML page. An ADC
	# response has certainly 38 or more elements. Future
	# versions might return more elements.

	if { [llength $response_list] < 38 } {
	    authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" $response 3 "" \
		"Authorize.net must be down, the response was not a character delimited list" "" "" $amount
	    set return(response_code) [nsv_get payment_gateway_return_codes retry]
	    set return(reason) "Authorize.net must be down, the response was not a character delimited list"
	    set return(transaction_id) $transaction_id
	    return [array get return]
	} else {
	    set response_code [lindex $response_list 0]
	    set response_reason_code [lindex $response_list 2]
	    set response_reason_text [lindex $response_list 3]
	    set response_auth_code [lindex $response_list 4]
	    set response_avs_code [lindex $response_list 5]
	    set response_transaction_id [lindex $response_list 6]
	    set response_md5_hash [lindex $response_list 37]
	    authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "CREDIT" \
		$response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

	    # 4. Return result

	    return [authorize_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text \
		    $response_md5_hash $amount]
	}
    }
}

ad_proc -public authorize_gateway.void {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to Authorize.net to void the transaction with transaction_id.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {
    # 1. Send transaction off to gateway

    set test_request [authorize_gateway.decode_test_request]
    set field_seperator [ad_parameter field_seperator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] referer_url]]

    # Add the Referer to the headers passed on to Authorize.net

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with Authorize.net

    # Basic secure URL and account info.

    set full_url "[ad_parameter "authorize_url"]?x_Login=[ns_urlencode [ad_parameter "authorize_login"]]&x_Password=[ns_urlencode [ad_parameter "authorize_password"]]"

    # Add necessary ADC (Authorize.net Direct Connect) info such as the delimiting character.

    append full_url "&x_ADC_URL=False&x_ADC_Delim_Data=True&x_ADC_Delim_Character=[ns_urlencode field_seperator]"

    # Set the test request flag to indicate trial communication or a real live transaction.

    append full_url "&x_Test_Request=[ns_urlencode $test_request]"

    # Set the transaction type to VOID
 
    append full_url "&x_Type=VOID&x_Amount=[ns_urlencode [format "%0.2f" $amount]]&x_Invoice_Num=$transaction_id"

    # Set the credit card information.

    append full_url "&x_Card_Num=[ns_urlencode $card_number]&x_Exp_Date=[ns_urlencode ${card_exp_month}/${card_exp_year}]&x_Last_Name=[ns_urlencode $card_name]"

    # Contact Authorize.net and receive the character delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to Authorize.net.

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
	authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" $error_message 3 "" $error_message "" "" $amount
	set return(response_code) [nsv_get payment_gateway_return_codes retry]
	set return(reason) "Transaction $transaction_id failed, could not contact Authorize.net: $error_message"
	set return(transaction_id) $transaction_id
	return [array get return]
    } else {

	# 2. Insert into log table

	# Decode the response from Authorize.net. Not all fields are
	# of interest. See the Authorize.net documentation
	# (https://secure.authorize.net/docs/response.pml)
	# for a complete list of response codes.

	set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

	# Check that the response from Authorize.net is a legimate ADC
	# response. When Authorize.net has problems the response is
	# not a character delimited list but an HTML page. An ADC
	# response has certainly 38 or more elements. Future
	# versions might return more elements.

	if { [llength $response_list] < 38 } {
	    authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" $response 3 "" \
		"Authorize.net must be down, the response was not a character delimited list" "" "" $amount
	    set return(response_code) [nsv_get payment_gateway_return_codes retry]
	    set return(reason) "Authorize.net must be down, the response was not a character delimited list"
	    set return(transaction_id) $transaction_id
	    return [array get return]
	} else {
	    set response_code [lindex $response_list 0]
	    set response_reason_code [lindex $response_list 2]
	    set response_reason_text [lindex $response_list 3]
	    set response_auth_code [lindex $response_list 4]
	    set response_avs_code [lindex $response_list 5]
	    set response_transaction_id [lindex $response_list 6]
	    set response_md5_hash [lindex $response_list 37]
	    authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "VOID" \
		$response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

	    # 3. Return result

	    return [authorize_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text \
			$response_md5_hash $amount]
	}
    }
}

ad_proc -public authorize_gateway.info {
} {
    Return information about Authorize.net implementation of the
    payment service contract. Returns the package_key, version, package name
    cards accepted and a list of return codes.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {

    array set info [list \
			package_key authorize-gateway \
			version [db_string get_package_version "
			    select version_name
			    from apm_package_versions 
			    where enabled_p = 't' 
			    and package_key = 'authorize-gateway'"] \
			package_name [db_string get_package_name "
			    select instance_name 
			    from apm_packages p, apm_package_versions v 
			    where p.package_key = v.package_key 
			    and v.enabled_p = 't' 
			    and p.package_key = 'authorize-gateway'"] \
			cards_accepted [ad_parameter CreditCardsAccepted -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] CreditCardsAccepted]] \
			success [nsv_get payment_gateway_return_codes success] \
			failure [nsv_get payment_gateway_return_codes failure] \
			retry [nsv_get payment_gateway_return_codes retry] \
			not_supported [nsv_get payment_gateway_return_codes not_supported] \
			not_implemented [nsv_get payment_gateway_return_codes not_implemented]]
    return [array get info]
}

# These stubs aren't exposed via the API - they are called only by ChargeCard.

ad_proc -private authorize_gateway.postauth {
    transaction_id
    auth_code
    card_number
    card_exp_month
    card_exp_year
    amount
} {
    Connect to Authorize.net to PRIOR_AUTH_CAPTURE the transaction with transaction id. 
    The transaction needs to have been AUTH_ONLY before calling this procedure.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {
    # 1. Send transaction off to gateway

    set test_request [authorize_gateway.decode_test_request]
    set field_seperator [ad_parameter field_seperator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] referer_url]]

    # Add the Referer to the headers passed on to Authorize.net

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with Authorize.net

    # Basic secure URL and account info.

    set full_url "[ad_parameter authorize_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_url]]?x_Login=[ns_urlencode [ad_parameter authorize_login -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_login]]]&x_Password=[ns_urlencode [ad_parameter authorize_password -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_password]]]"

    # Add necessary ADC (Authorize.net Direct Connect) info such as the delimiting character.

    append full_url "&x_ADC_URL=False&x_ADC_Delim_Data=True&x_ADC_Delim_Character=[ns_urlencode $field_seperator]"

    # Set the test request flag to indicate trial communication or a real live transaction.

    append full_url "&x_Test_Request=[ns_urlencode $test_request]"

    # Set the transaction type to PRIOR_AUTH_CAPTURE, the transaction_id
    # to the id of the transaction that has been authorized and the
    # auth_code to the authorization code of that transaction.
 
    append full_url "&x_Type=PRIOR_AUTH_CAPTURE&x_Amount=[ns_urlencode [format "%0.2f" $amount]]&x_Trans_ID=$transaction_id&x_Auth_Code=$auth_code"

    # Set the credit card information.

    append full_url "&x_Card_Num=[ns_urlencode $card_number]&x_Exp_Date=[ns_urlencode ${card_exp_month}/${card_exp_year}]"

    # Contact Authorize.net and receive the character delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to Authorize.net.

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
	authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" $error_message 3 "" \
	    $error_message "" "" $amount
	set return(response_code) [nsv_get payment_gateway_return_codes retry]
	set return(reason) "Transaction $transaction_id failed, could not contact Authorize.net: $error_message"
	set return(transaction_id) $transaction_id
	return [array get return]
    } else {

	# 2. Insert into log table

	# Decode the response from Authorize.net. Not all fields are
	# of interest. See the Authorize.net documentation
	# (https://secure.authorize.net/docs/response.pml)
	# for a complete list of response codes.

	set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

	# Check that the response from Authorize.net is a legimate ADC
	# response. When Authorize.net has problems the response is
	# not a character delimited list but an HTML page. An ADC
	# response has certainly 38 or more elements. Future
	# versions might return more elements.

	if { [llength $response_list] < 38 } {
	    authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" $response 3 "" \
		"Authorize.net must be down, the response was not a character delimited list" "" "" $amount
	    set return(response_code) [nsv_get payment_gateway_return_codes retry]
	    set return(reason) "Authorize.net must be down, the response was not a character delimited list"
	    set return(transaction_id) $transaction_id
	    return [array get return]
	} else {
	    set response_code [lindex $response_list 0]
	    set response_reason_code [lindex $response_list 2]
	    set response_reason_text [lindex $response_list 3]
	    set response_auth_code [lindex $response_list 4]
	    set response_avs_code [lindex $response_list 5]
	    set response_transaction_id [lindex $response_list 6]
	    set response_md5_hash [lindex $response_list 37]
	    authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "PRIOR_AUTH_CAPTURE" \
		$response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

	    # 3. Return result

	    return [authorize_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code \
		    $response_reason_text $response_md5_hash $amount]
	}
    }
}

ad_proc -private authorize_gateway.authcapture {
    transaction_id
    amount
    card_type
    card_number
    card_exp_month
    card_exp_year
    card_name
    billing_street
    billing_city
    billing_state
    billing_zip
    billing_country
} {
    Connect to Authorize.net to authorize and shedule the transaction for automatic 
    settling. No further action is needed to complete the transastion. 

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {
    # 1. Send transaction off to gateway

    set test_request [authorize_gateway.decode_test_request]
    set field_seperator [ad_parameter field_seperator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_seperator]]
    set field_encapsulator [ad_parameter field_encapsulator -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] field_encapsulator]]
    set referer_url [ad_parameter referer_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] referer_url]]

    # Add the Referer to the headers passed on to Authorize.net

    set header [ns_set new]
    ns_set put $header Referer $referer_url

    # Compile the URL for the GET communication with Authorize.net

    # Basic secure URL and account info.

    set full_url "[ad_parameter authorize_url -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_url]]?x_Login=[ns_urlencode [ad_parameter authorize_login -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_login]]]&x_Password=[ns_urlencode [ad_parameter authorize_password -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_password]]]"

    # Add necessary ADC (Authorize.net Direct Connect) info such as the delimiting character.

    append full_url "&x_ADC_URL=False&x_ADC_Delim_Data=True&x_ADC_Delim_Character=[ns_urlencode $field_seperator]"

    # Set the test request flag to indicate trial communication or a real live transaction.

    append full_url "&x_Test_Request=[ns_urlencode $test_request]"

    # Set the transaction type to AUTH_CAPTURE and set the invoice
    # number to the transaction id paramater. This is a bit confusing
    # as the transaction id passed to this procedure should not be
    # mistaken for the transaction id that Authorize.net will generate
    # and return. The Authorize.net transaction id will be store in
    # the response_transaction_id. 
 
    append full_url "&x_Type=AUTH_CAPTURE&x_Amount=[ns_urlencode [format "%0.2f" $amount]]&x_Invoice_Num=$transaction_id&x_Description=[ns_urlencode [ad_parameter "description"]]"

    # Set the credit card information.

    append full_url "&x_Card_Num=[ns_urlencode $card_number]&x_Exp_Date=[ns_urlencode ${card_exp_month}/${card_exp_year}]&x_Last_Name=[ns_urlencode $card_name]"

    # Set the billing information. The information will be used by
    # Authorize.net to run an AVS check.

    append full_url "&x_Address=[ns_urlencode $billing_street]&x_City=[ns_urlencode $billing_city]&x_Zip=[ns_urlencode $billing_zip]&x_State=[ns_urlencode $billing_state]&x_Country=[ns_urlencode $billing_country]"

    # Contact Authorize.net and receive the character delimited
    # response. Timeout after 30 seconds, don't allow any redirects
    # and pass a set of custom headers to Authorize.net.

    if {[catch {set response [ns_httpsget $full_url 30 0 $header]} error_message]} {
	authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" $error_message 3 "" \
	    $error_message "" "" $amount
	set return(response_code) [nsv_get payment_gateway_return_codes retry]
	set return(reason) "Transaction $transaction_id failed, could not contact Authorize.net: $error_message"
	set return(transaction_id) $transaction_id
	return [array get return]
    } else {

	# 2. Insert into log table

	# Decode the response from Authorize.net. Not all fields are
	# of interest. See the Authorize.net documentation
	# (https://secure.authorize.net/docs/response.pml)
	# for a complete list of response codes.

	set response_list "\{[string map [list $field_encapsulator$field_seperator$field_encapsulator "\} \{" $field_encapsulator {}] $response]\}"

	# Check that the response from Authorize.net is a legimate ADC
	# response. When Authorize.net has problems the response is
	# not a character delimited list but an HTML page. An ADC
	# response has certainly 38 or more elements. Future versions
	# might return more elements.

	if { [llength $response_list] < 38 } {
	    authorize_gateway.log_results $transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" $response 3 "" \
		"Authorize.net must be down, the response was not a character delimited list" "" "" $amount
	    set return(response_code) [nsv_get payment_gateway_return_codes retry]
	    set return(reason) "Authorize.net must be down, the response was not a character delimited list"
	    set return(transaction_id) $transaction_id
	    return [array get return]
	} else {
	    set response_code [lindex $response_list 0]
	    set response_reason_code [lindex $response_list 2]
	    set response_reason_text [lindex $response_list 3]
	    set response_auth_code [lindex $response_list 4]
	    set response_avs_code [lindex $response_list 5]
	    set response_transaction_id [lindex $response_list 6]
	    set response_md5_hash [lindex $response_list 37]
	    authorize_gateway.log_results $response_transaction_id  "[clock format [clock seconds] -format "%D %H:%M:%S"]" "AUTH_CAPTURE" \
		$response $response_code $response_reason_code $response_reason_text $response_auth_code $response_avs_code $amount

	    # 3. Return result

	    return [authorize_gateway.decode_response $transaction_id $response_transaction_id $response_code $response_reason_code $response_reason_text \
			$response_md5_hash $amount]
	}
    }
}

ad_proc -private authorize_gateway.decode_response {
    transaction_id
    response_transaction_id
    response_code
    response_reason_code
    response_reason_text
    response_md5_hash
    amount
} {
    Decode the response from Authorize.net. Check authenticity, then map
    Authorize.net response codes to standardized payment service
    contract response codres.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {

    # Check if the response is authentic. The MD5 hash is a
    # security feature that enables your script to identify that
    # the results of a transaction are actually from
    # Authorize.Net. This is done by creating a "secret" in your
    # account. An MD5 hash is a specific way of encrypting
    # information to make it unreadable unless the secret is
    # known. Every time we return the results of a transaction, we
    # also return the MD5 hash. It is created as with your secret,
    # your Login ID, and two fields from the transaction. It is a
    # concatenated string of those four items in the following
    # order:

    # "MD5-Secret (assigned by merchant in the settings area)",
    # "Login ID", "Trans ID", "Amount"

    # For an example, if your secret was "secret", your Login ID
    # was "mylogin", the transaction ID was "987654321", and the
    # amount was "1.00", the MD5 would be run on the following
    # string: "secretmylogin9876543211.00"

    # When your script receives the results of the transaction you
    # can create an MD5 hash on your side and be sure it matches
    # ours. You will already know your secret and your login ID,
    # and will receive the Transaction ID and amount in the
    # results.

    # You can choose your MD5 Hash Secret by doing the following:
    # -Log into your merchant menu at (https://secure.authorize.net/).
    # -Click Settings.
    # -Select Automated Direct Connect (ADC) Settings.
    # -Click Go.
    # -Enter the MD5 Hash Secret that you would like to use.
    # -Click Submit to save the changes.

    # Don't forget to store the same MD5 Hash Secret in the
    # md5_secret parameter of the Authorize.net Gateway in
    # OpenACS.

    # The dqd_md5 functions is provided by Rob Mayoff's dqd_utils
    # module for AOLServer. (http://dqd.com/~mayoff/aolserver/)

    set md5_hash [string tolower [dqd_md5 "[ad_parameter md5_secret -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] md5_secret]][ad_parameter authorize_login -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] authorize_login]]$response_transaction_id[format "%0.2f" $amount]"]]
    if {$md5_hash == [string tolower $response_md5_hash]} {

	# The response is authentic. Now decode the response code
	# and the reason code.

	switch -exact $response_code {
	    "1" {
		set return(response_code) [nsv_get payment_gateway_return_codes success]
		set return(reason) "Transaction $response_transaction_id has been approved."
		set return(transaction_id) $response_transaction_id
		return [array get return]
	    }
	    "2" {
		set return(response_code) [nsv_get payment_gateway_return_codes failure]
		set return(reason) "Transaction $response_transaction_id has been declined: $response_reason_text"
		set return(transaction_id) $transaction_id
		return [array get return]
	    }
	    "3" {

		# Some of the transactions that encountered an 
		# error while being processed can be retried in a
		# little while. See the Authorize.net
		# documentation 
		# (https://secure.authorize.net/docs/response.pml)
		# for a complete list of response codes.

		switch -exact $response_reason_code {
		    "11" -
		    "19" -
		    "20" -
		    "21" -
		    "22" -
		    "23" -
		    "25" -
		    "26" {
			set return(response_code) [nsv_get payment_gateway_return_codes retry]
			set return(reason) "There has been an error processing transaction $response_transaction_id: $response_reason_text"
			set return(transaction_id) $transaction_id
			return [array get return]
		    }
		    default {

			# All other transactions failed indefinitely.

			set return(response_code) [nsv_get payment_gateway_return_codes failure]
			set return(reason) "There has been an error processing transaction $response_transaction_id: $response_reason_text"
			set return(transaction_id) $transaction_id
			return [array get return]
		    }
		}
	    }
	    default {
		set return(response_code) [nsv_get payment_gateway_return_codes not_implemented]
		set return(reason) "Authorize.net returned an unknown response_code: $response_code"
		set return(transaction_id) $transaction_id
		return [array get return]
	    }
	}
    } else {
	set return(response_code) [nsv_get payment_gateway_return_codes failure]
	set return(reason) "There has been an error processing transaction $response_transaction_id: the MD5 hash does not match"
	set return(transaction_id) $transaction_id
	return [array get return]
    }
}

ad_proc -private authorize_gateway.decode_test_request {
} {
    Set test_request to True/False based on the test_request parameter of the
    package. This prevents errors due to incorrect values of the test_request
    parameter

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
    @creation-date March 2002
} {

    switch -exact [string tolower [ad_parameter test_request -default [ad_parameter -package_id [apm_package_id_from_key authorize-gateway] test_request]]] {
	"0" -
	"n" -
	"no" -
	"false" {
	    set test_request "False"
	}
	"1" -
	"y" -
	"yes" - 
	"true" {
	    set test_request "True"
	}
	default {
	    set test_request "False"
	}
    }
    return $test_request
}

ad_proc -private authorize_gateway.log_results {
    transaction_id
    txn_attempted_time
    txn_attempted_type
    response
    response_code
    response_reason_code
    response_reason_text
    auth_code
    avs_code
    amount
} {
    Write the results of the current operation to the database.  If it fails,
    log it but don't let the user know about it.

    @author Bart Teeuwisse <bart.teeuwisse@7-sisters.com>
} {
    if [catch {db_dml do-insert "
	insert into authorize_gateway_result_log
	(transaction_id, txn_attempted_time, txn_attempted_type, response, response_code, response_reason_code, response_reason_text, response_transaction_id, 
	 auth_code, avs_code, amount) 
	values 
	(:transaction_id, :txn_attempted_time, :txn_attempted_type, :response, :response_code, :response_reason_code, :response_reason_text, :response_transaction_id, 
	 :auth_code, :avs_code, :amount)"} errmsg] {
	ns_log Error "Wasn't able to do insert into authorize_gateway_result_log for transaction_id $transaction_id; error was $errmsg"
    }
}
