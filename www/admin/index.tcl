ad_page_contract {
    
    Lists the log of the results 

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date April 2002
} {
    {orderby "txn_time*"}
} -properties {
    title:onevalue
    context_bar:onevalue
    dimensional_bar:onevalue    
}

# Authenticate the user

set user_id [auth::require_login]

# Check for admin privileges

set package_id [ad_conn package_id]
set admin_p [ad_permission_p $package_id admin]

# Get the package name and set the title.

if {[db_0or1row get_package_name {}]} {
    set title "$instance_name Administration"
} else {
    set title "Administration"
}

# Set the context bar.

set context_bar [ad_context_bar]

# Dimensional slider definition for narrowing the selection.

set dimensional {
    {response_code "Result" approved {
        {approved "approved" {where "[db_map result_approved]"} }
        {declined "declined" {where "[db_map result_declined]"} }
        {error "error" {where "[db_map result_error]"} }
        {any "all" {} }
    } }
    {transaction "Time of transaction" 1d {
        {1d "last 24 hours" {where "[db_map transaction_last_24hours]"}}
        {1w "last week" {where "[db_map transaction_last_week]"}}
        {1m "last month" {where "[db_map transaction_last_month]"}}
        {any "all" {} }
    } }
}
set dimensional_bar [ad_dimensional $dimensional]

# Definition for ad_table.

set table_def {
    {transaction_id "ID" {} {}}
    {txn_time "Date" {txn_attempted_time desc} {}}
    {txn_attempted_type "Type" {} {}}
    {response_code "Result" {} {}}
    {response_reason_code "Reason" {} {}}
    {response_reason_text "Explanation" no_sort {}}
    {auth_code "Authorization" {} {}}
    {avs_code "AVS" {} {}}
    {response "Verbatim response" no_sort {}}
}

# Create the table to display the results from Authorize.net

set result_table [ad_table result_select {} $table_def]
