ad_page_contract {

    Index to documentation of the Authorize.net Gateway, an
    implementation of the Payment Service Contract.

    @author Bart Teeuwisse <bart.teeuwisse@thecodemill.biz>
    @creation-date May 2002

} {
} -properties {
    title:onevalue
    context_bar:onevalue
}

# Authenticate the user

set user_id [ad_maybe_redirect_for_registration]

set package_name "Authorize.net Gateway"
set title "$package_name Documentation"
set package_url [apm_package_url_from_key "authorize-gateway"]
set package_id [apm_package_id_from_key "authorize-gateway"]

# Check if the package has been mounted.

set authorize_gateway_mounted [expr ![empty_string_p $package_url]]

# Check for admin privileges

set admin_p [ad_permission_p $package_id admin]

# Check if the ecommerce and the shipping service contract packages
# are installed on the system.

set ecommerce_installed [apm_package_installed_p ecommerce]
set payment_gateway_installed [apm_package_installed_p "payment-gateway"]

# Set the context bar.

set context_bar [ad_context_bar $package_name]

# Set signatory for at the bottom of the page

set signatory "bart.teeuwisse@thecodemill.biz"
