<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <partialquery name="transaction_last_24hours">      
    <querytext>
	txn_attempted_time + 1 > sysdate
    </querytext>
  </partialquery>

  <partialquery name="transaction_last_week">      
    <querytext>
	txn_attempted_time + 7 > sysdate
    </querytext>
  </partialquery>

  <partialquery name="transaction_last_month">      
    <querytext>
	add_months(txn_attempted_time,1) > sysdate
    </querytext>
  </partialquery>

  <fullquery name="result_select">      
    <querytext>
      select transaction_id, to_char(txn_attempted_time, 'MM-DD-YYYY HH24:MI:SS') as txn_time, txn_attempted_type, response, response_code, response_reason_code, response_reason_text, auth_code, avs_code, amount 
      from authorize_gateway_result_log 
      where '1'='1' [ad_dimensional_sql $dimensional] [ad_order_by_from_sort_spec $orderby $table_def]
    </querytext>
  </fullquery>

</queryset>