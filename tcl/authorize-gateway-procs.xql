<?xml version="1.0"?>

<queryset>

  <fullquery name="authorize_gateway.chargecard.select_auth_only">      
    <querytext>
      select transaction_id, auth_code
      from authorize_gateway_result_log 
      where txn_attempted_type='AUTH_ONLY' 
      and response_code='1' 
      and transaction_id=:transaction_id
    </querytext>
  </fullquery>

  <fullquery name="authorize_gateway.info.get_package_version">
    <querytext>
      select version_name
      from apm_package_versions 
      where enabled_p = 't' 
      and package_key = 'authorize-gateway'
    </querytext>
  </fullquery>

  <fullquery name="authorize_gateway.info.get_package_name">
    <querytext>
      select instance_name 
      from apm_packages p, apm_package_versions v 
      where p.package_key = v.package_key 
      and v.enabled_p = 't' 
      and p.package_key = 'authorize-gateway'
    </querytext>
  </fullquery>

</queryset>
